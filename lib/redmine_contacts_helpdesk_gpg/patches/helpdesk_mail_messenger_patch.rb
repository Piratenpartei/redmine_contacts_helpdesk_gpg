require 'gpgme'
require 'mail-gpg'
require 'gpgkeys'
require_dependency 'helpdesk_mail_messenger'
require_dependency 'redmine_contacts_helpdesk_gpg'

module RedmineContactsHelpdeskGpg
  module Patches
    module HelpdeskMailMessengerPatch
      attr_writer :email

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          # add settings for gpg encryption/signature to prepared email
          alias_method :prepare_email_without_gpg, :prepare_email
          alias_method :prepare_email, :prepare_email_with_gpg
        end
      end

      module InstanceMethods
        def prepare_email_with_gpg(contact, object, options = {})
          logger = options[:logger]
          project = object.instance_of?(Issue) ? object.project : object.issue.project
          issue = object.instance_of?(Issue) ? object : object.issue

          logger&.info "gpg_send_mail: begin; issue=#{issue.id}, options=#{options.except(:logger).to_json}"
          initGPGSettings

          logger&.info "gpg_send_mail: call prepare_email_without_gpg; issue=#{issue.id}"
          prepare_email_without_gpg(contact, object, options)

          created_journal = maySetGPGOptionsFromParams(issue, options)
          logger&.info "gpg_send_mail: after maySetGPGOptionsFromParams; issue=#{issue.id}, created_journal=#{created_journal}"

          gpg_journal = HelpDeskGPG::GpgJournalHelper.queryJournal(issue.id)
          gpg_options = validateGPGOptionsFromParams(project, options, gpg_journal, logger, issue.id)
          logger&.info "gpg_send_mail: validated gpg options; issue=#{issue.id}, gpg_options=#{gpg_options}"

          mail gpg: gpg_options unless gpg_options.empty?

          if created_journal
            HelpDeskGPG::GpgJournalHelper.saveJournal(issue.id)
          end

          email
        end

        private

        def initGPGSettings
          ENV['GNUPGHOME'] = HelpDeskGPG.keyrings_dir
          GPGME::Engine.home_dir = HelpDeskGPG.keyrings_dir
        end

        def maySetGPGOptionsFromParams(issue, params)
          # might create/prepare a journal entry. ()Esp. if issue is a newly created one and we working on its initial email.)
          created_journal = false
          if params[:helpdesk]
            if params[:helpdesk][:gpg_do_encrypt] || params[:helpdesk][:gpg_do_sign]
              HelpDeskGPG::GpgJournalHelper.prepareJournal(issue, nil, params[:helpdesk])
              created_journal = true
            end
          end
          created_journal
        end

        def validateGPGOptionsFromParams(project, options, gpg_journal, logger, issue_id)
          gpg_options = {}
          return gpg_options if gpg_journal.nil?

          if gpg_journal.encrypted?
            # do we have keys for all recipients?
            receivers = []
            receivers += options[:to_address].split(',') if options[:to_address]
            receivers += options[:cc_address].split(',') if options[:cc_address]
            receivers += options[:bcc_address].split(',') if options[:bcc_address]
            missing_keys = GpgKeys.missing_keys_for_encryption(receivers)
            if missing_keys.empty?
              gpg_options[:encrypt] = true
              logger&.info "gpg_send_mail: keys available for all recipients; issue=#{issue_id}"
            else
              gpg_journal.encrypted = false
              logger&.info "gpg_send_mail: cannot encrypt, no mail sent; issue=#{issue_id}, missing_keys=#{missing_keys}"
              raise MailHandler::MissingInformation, "Cannot encrypt, no mail sent. Public key missing for #{missing_keys}"
            end
          end
          logger&.info "gpg_send_mail: issue=#{issue_id}, sign_mail=#{gpg_journal.signed?}"
          if gpg_journal.signed?
            gpg_options[:sign_as] = HelpdeskSettings[:gpg_sign_key, project]
          end
          gpg_options
        end
      end
    end
  end
end
