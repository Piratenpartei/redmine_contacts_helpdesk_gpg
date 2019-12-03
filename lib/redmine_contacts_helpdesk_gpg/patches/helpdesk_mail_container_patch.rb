require 'gpgme'
require 'mail-gpg'
require 'gpgkeys'
require_dependency 'helpdesk_mail_container'
require_dependency 'redmine_contacts_helpdesk_gpg'

module RedmineContactsHelpdeskGpg
  module Patches
    module HelpdeskMailContainerPatch
      CONTAINER_ACCESSORS = %i[issue is_new_issue].freeze
      attr_accessor *CONTAINER_ACCESSORS

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          # incoming mail; check for gpg encryption/signature prior to handling mail by helpdesk
          alias_method :initialize_without_gpg, :initialize
          alias_method :initialize, :initialize_with_gpg

          # incoming mail; create journal entries etc.
          alias_method :dispatch_without_gpg, :dispatch
          alias_method :dispatch, :dispatch_with_gpg
        end
      end

      module InstanceMethods
        def initialize_with_gpg(email_or_raw, options = {})
          # XXX: this is called for sending and receiving of mails, but the encryption / signature parts
          # are only called for incoming mails. This is a bit confusing...
          init_gpg_settings
          logger = options[:logger]
          target_project = (options[:issue])[:project_id]
          email_or_raw.force_encoding('ASCII-8BIT') if email_or_raw.respond_to?(:force_encoding)
          mail = email_or_raw.is_a?(Mail) ? email_or_raw : Mail.new(email_or_raw)
          @gpg_received_options = { encrypted: false, signed: false }
          sender_email = mail.from_addrs.first.to_s.strip
          header = mail.header
          if mail.encrypted?
            decrypt_key = HelpdeskSettings[:gpg_decrypt_key, target_project]
            logger&.info "gpg_receive_mail: encrypted incoming mail; from=#{sender_email}, key=#{decrypt_key}, header=#{header.to_json}"
            decrypted = mail.decrypt(verify: true)
            @gpg_received_options[:encrypted] = true
            sig_valid = decrypted.signature_valid?
            signatures = decrypted.signatures.map(&:from)
            logger&.info "gpg_receive_mail: checked signature; message_id=#{mail.message_id}, sig_valid=#{sig_valid}, signatures=#{signatures.join(',')}"
            @gpg_received_options[:signed] = sig_valid
            mail = Mail.new(decrypted)
          elsif mail.signed?
            logger&.info "gpg_receive_mail: signed incoming mail; from=#{sender_email}, header=#{header.to_json}"
            have_key = GpgKeys.check_and_optionally_import_key(sender_email, logger)

            if have_key
              begin
                verified = mail.verify
                sig_valid = verified.signature_valid?
              rescue StandardError => e
                logger&.error("gpg_receive_mail: signature verification failed (process #{Process.pid}): " +
                  e.message +
                  "\n\t" +
                  e.backtrace.join("\n\t"))
                sig_valid = false
              end
              signatures = verified.signatures.map(&:from)
              logger&.info "gpg_receive_mail: checked signature; sig_valid=#{sig_valid}, signatures=#{signatures.join(',')}"
              @gpg_received_options[:signed] = sig_valid
              mail = Mail.new(verified) if sig_valid
            else
              logger&.info "gpg_receive_mail: could not find key; message_id=#{mail.message_id}, from=#{sender_email}"
            end
          end
          initialize_without_gpg(mail, options)
        end

        def dispatch_with_gpg
          dispatch_without_gpg
          ref = is_new_issue ? issue : issue.current_journal
          save_gpg_journal(ref, @gpg_received_options)
        end

        private

        def init_gpg_settings
          ENV['GNUPGHOME'] = HelpDeskGPG.keyrings_dir
          GPGME::Engine.home_dir = HelpDeskGPG.keyrings_dir
        end

        def save_gpg_journal(ref, options)
          return unless options[:signed] || options[:encrypted]

          logger.info "save_gpg_journal: class=#{ref.class}, id=#{ref.id}, sign=#{options[:signed]}, encrypt=#{options[:encrypted]}"
          item = GpgJournal.new
          item.signed = options[:signed].present? && options[:signed]
          item.encrypted = options[:encrypted].present? && options[:encrypted]
          item.issue = ref if ref.instance_of?(Issue)
          item.journal = ref if ref.instance_of?(Journal)
          item.save
        end
      end
    end
  end
end
