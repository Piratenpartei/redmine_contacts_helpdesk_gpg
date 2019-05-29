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
      end # self.included

      module InstanceMethods
        # checks for encrypted/signed mail then proceeds with the receiving process
        def initialize_with_gpg(email_or_raw, options = {})
          init_gpg_settings
          logger = options[:logger]
          target_project = (options[:issue])[:project_id]
          email_or_raw.force_encoding('ASCII-8BIT') if email_or_raw.respond_to?(:force_encoding)
          the_email = email_or_raw.is_a?(Mail) ? email_or_raw : Mail.new(email_or_raw)
          @gpg_received_options = { encrypted: false, signed: false }
          logger.info "initialize_with_gpg: email.from_addrs is '#{the_email.from_addrs}'" unless logger.nil?
          sender_email = the_email.from_addrs.first.to_s.strip
          if the_email.encrypted?
            logger.info "initialize_with_gpg: do I have a key for decrypting? '#{HelpdeskSettings[:gpg_decrypt_key, target_project]}" unless logger.nil?
            decrypted = the_email.decrypt(verify: true, password: HelpdeskSettings[:gpg_decrypt_key_password, target_project], pinentry_mode: GPGME::PINENTRY_MODE_LOOPBACK)
            @gpg_received_options[:encrypted] = true
            @gpg_received_options[:signed] = decrypted.signature_valid?
            logger.info "initialize_with_gpg: Mail was encrypted" unless logger.nil?
            logger.info "initialize_with_gpg: signature(s) valid: #{decrypted.signature_valid?}" unless logger.nil?
            logger.info "initialize_with_gpg: message signed by: #{decrypted.signatures.map{|sig|sig.from}.join("\n")}" unless logger.nil?
            the_email = Mail.new(decrypted)
          elsif the_email.signed?
            have_key = GpgKeys.check_and_optionally_import_key(sender_email)
            if have_key
              verified = the_email.verify
              logger.info "initialize_with_gpg: signature(s) valid: #{verified.signature_valid?}" unless logger.nil?
              logger.info "initialize_with_gpg: message signed by: #{verified.signatures.map{|sig|sig.from}.join("\n")}" unless logger.nil?
              @gpg_received_options[:signed] = verified.signature_valid?
              the_email = Mail.new(verified) if verified.signature_valid?
            else
              logger.info "initialize_with_gpg: could not find key for: #{sender_email}" unless logger.nil?
            end
          end
          initialize_without_gpg(the_email, options)
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

          logger.info "save_gpg_journal: Creating GpgJournal for #{ref.class}(#{ref.id}): s:#{options[:signed]},e:#{options[:encrypted]}"
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
