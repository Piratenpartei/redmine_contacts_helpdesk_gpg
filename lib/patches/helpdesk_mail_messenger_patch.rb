require 'gpgme'
require 'mail-gpg'
require 'gpgkeys'
require_dependency 'helpdesk_mail_messenger'
require_dependency 'redmine_contacts_helpdesk_gpg'

module RedmineHelpdeskGPG
  module Patches
    module HelpdeskMailMessengerPatch
      attr_writer :email

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development

          # add settings for gpg encryption/signature to prepared email
          alias_method :prepare_email_without_gpg, :prepare_email
          alias_method :prepare_email, :prepare_email_with_gpg

        end
      end # self.included

      module InstanceMethods
        def prepare_email_with_gpg(contact, object, options = {})
          initGPGSettings

          prepare_email_without_gpg(contact, object, options)

          _project = object.instance_of?(Issue) ? object.project : object.issue.project
          _issue = object.instance_of?(Issue) ? object : object.issue

          _created_journal = maySetGPGOptionsFromParams(issue, options)

          _gpg_journal = RedmineHelpdeskGPG::IssuesControllerHookHelper.queryJournal(_issue.id)
          _gpg_options = validateGPGOptionsFromParams(project, options, _gpg_journal)
          # logger.info "prepare_email_with_gpg: set gpg options: #{_gpgOptions}"

          mail gpg: _gpg_options unless _gpg_options.empty?

          if _created_journal
            ## save the journal entry if we created it here
            RedmineHelpdeskGPG::IssuesControllerHookHelper.saveJournal(_issue.id)
          end

          email
        end # prepare_email_with_gpg

        ## private methods
        private

        def initGPGSettings
          ENV['GNUPGHOME'] = HelpDeskGPG.keyrings_dir
          GPGME::Engine.home_dir = HelpDeskGPG.keyrings_dir
        end # initGPGSettings

        def maySetGPGOptionsFromParams(issue, params)
          # might create/prepare a journal entry. ()Esp. if issue is a newly created one and we working on its initial email.)
          created_journal = false
          if params[:helpdesk]
            if params[:helpdesk][:gpg_do_encrypt] || params[:helpdesk][:gpg_do_sign]
              RedmineHelpdeskGPG::IssuesControllerHookHelper.prepareJournal(issue, nil, params[:helpdesk])
              created_journal = true
            end
          end
          created_journal
        end

        def validateGPGOptionsFromParams(project, options, gpg_journal)
          _gpg_options = {}
          return _gpg_options if gpg_journal.nil?

          if gpg_journal.was_encrypted
            # do we have keys for all recipients?
            _receivers = []
            _receivers += options[:to_address].split(',') if options[:to_address]
            _receivers += options[:cc_address].split(',') if options[:cc_address]
            _receivers += options[:bcc_address].split(',') if options[:bcc_address]
            _missing_keys = GpgKeys.missing_keys_for_encryption(_receivers)
            if _missing_keys.empty? # all keys are available :)
              _gpg_options[:encrypt] = true
            else
              gpg_journal.was_encrypted = false
              raise MailHandler::MissingInformation, "Cannot encrypt message. No public key for #{_missing_keys}"
            end
          end
          if gpg_journal.was_signed ## shall we sign the message?
            _gpg_options[:sign_as] = HelpdeskSettings[:gpg_sign_key, project]
            _gpg_options[:password] = HelpdeskSettings[:gpg_sign_key_password, project]
            _gpg_options[:pinentry_mode] = GPGME::PINENTRY_MODE_LOOPBACK
          end
          _gpg_options
        end
      end # module InstanceMethods
    end # module HelpdeskMailMessengerPatch
  end # module Patches
end # module RedmineHelpdeskGPG

unless HelpdeskMailMessenger.included_modules.include?(RedmineHelpdeskGPG::Patches::HelpdeskMailMessengerPatch)
  HelpdeskMailMessenger.send(:include, RedmineHelpdeskGPG::Patches::HelpdeskMailMessengerPatch)
end
