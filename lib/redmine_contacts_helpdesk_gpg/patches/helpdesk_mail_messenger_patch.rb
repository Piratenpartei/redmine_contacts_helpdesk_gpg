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

          # Strip leading comma. This breaks mail delivery otherwise.
          # I don't know the origin, maybe there's an error in the Javascript code.
          options[:to_address] = options[:to_address][1..] if options[:to_address].start_with?(',')

          logger&.info "gpg_send_mail: begin; issue=#{issue.id}, options=#{options.except(:logger).to_json}"
          ENV['GNUPGHOME'] = HelpDeskGPG.keyrings_dir
          GPGME::Engine.home_dir = HelpDeskGPG.keyrings_dir

          logger&.info "gpg_send_mail: call prepare_email_without_gpg; issue=#{issue.id}"
          prepare_email_without_gpg(contact, object, options)

          gpg_journal = object.gpg_journal

          if gpg_journal.present?
            gpg_options = {}
            gpg_options[:encrypt] = gpg_journal.encrypted?
            if gpg_journal.signed?
              gpg_options[:sign_as] = HelpdeskSettings[:gpg_sign_key, project]
            end
            mail gpg: gpg_options
            logger&.info "gpg_send_mail: GPG is used; issue=#{issue.id}, gpg_options=#{gpg_options}"
          else
            logger&.info "gpg_send_mail: GPG is not used; issue=#{issue.id}"
          end

          email
        end
      end
    end
  end
end
