require 'gpgme'
require 'mail-gpg'
require 'gpgkeys'
require_dependency 'helpdesk_mail_container'
require_dependency 'redmine_contacts_helpdesk_gpg'

module RedmineHelpdeskGPG
  module Patches
    module HelpdeskMailContainerPatch
      CONTAINER_ACCESSORS = %i[issue is_new_issue].freeze
      attr_accessor *CONTAINER_ACCESSORS

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development

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
          initGPGSettings
          _myLogger = options[:logger]
          _target_project = (options[:issue])[:project_id]
          email_or_raw.force_encoding('ASCII-8BIT') if email_or_raw.respond_to?(:force_encoding)
          the_email = email_or_raw.is_a?(Mail) ? email_or_raw : Mail.new(email_or_raw)
          @gpg_received_options = { encrypted: false, signed: false }
          # _myLogger.info "receive_with_gpg: email.from_addrs is '#{the_email.from_addrs}'" unless _myLogger.nil?
          _sender_email = the_email.from_addrs.first.to_s.strip
          if the_email.encrypted?
            # _myLogger.info "receive_with_gpg: do I have a key for decrypting? '#{HelpdeskSettings[:gpg_decrypt_key, _target_project]}" unless _myLogger.nil?
            _decrypted = the_email.decrypt(verify: true, password: HelpdeskSettings[:gpg_decrypt_key_password, _target_project], pinentry_mode: GPGME::PINENTRY_MODE_LOOPBACK)
            @gpg_received_options[:encrypted] = true
            @gpg_received_options[:signed] = _decrypted.signature_valid?
            # _myLogger.info "receive_with_gpg: Mail was encrypted" unless _myLogger.nil?
            # _myLogger.info "receive_with_gpg: signature(s) valid: #{_decrypted.signature_valid?}" unless _myLogger.nil?
            # _myLogger.info "receive_with_gpg: message signed by: #{_decrypted.signatures.map{|sig|sig.from}.join("\n")}" unless _myLogger.nil?
            the_email = Mail.new(_decrypted)
          elsif the_email.signed?
            _have_key = GpgKeys.checkAndOptionallyImportKey(_sender_email)
            if _have_key
              _verified = the_email.verify
              # _myLogger.info "receive_with_gpg: signature(s) valid: #{_verified.signature_valid?}" unless _myLogger.nil?
              # _myLogger.info "receive_with_gpg: message signed by: #{_verified.signatures.map{|sig|sig.from}.join("\n")}" unless _myLogger.nil?
              @gpg_received_options[:signed] = _verified.signature_valid?
              the_email = Mail.new(_verified) if _verified.signature_valid?
            else
              # _myLogger.info "receive_with_gpg: could not find key for: #{_sender_email}" unless _myLogger.nil?
            end
          end
          initialize_without_gpg(the_email, options) # call original method
        end # def initialize_with_gpg

        def dispatch_with_gpg
          dispatch_without_gpg # call original method
          _ref = is_new_issue ? issue : issue.current_journal
          saveGpgJournal(_ref, options)
        end

        ## private methods
        private

        def initGPGSettings
          ENV['GNUPGHOME'] = HelpDeskGPG.keyrings_dir
          GPGME::Engine.home_dir = HelpDeskGPG.keyrings_dir
        end # initGPGSettings

        def saveGpgJournal(ref, _options)
          if @gpg_received_options[:signed] || @gpg_received_options[:encrypted]
            # logger.info "saveGpgJournal: Creating GpgJournal for #{ref.class}(#{ref.id}): s:#{options[:signed]},e:#{options[:encrypted]}"
            item = GpgJournal.new
            item.was_signed = @gpg_received_options[:signed]
            item.was_encrypted = @gpg_received_options[:encrypted]
            item.issue = ref if ref.instance_of?(Issue)
            item.journal = ref if ref.instance_of?(Journal)
            item.save
          end
        end
      end # module InstanceMethods
    end # module HelpdeskMailContainerPatch
  end # module Patches
end # module RedmineHelpdeskGPG

unless HelpdeskMailContainer.included_modules.include?(RedmineHelpdeskGPG::Patches::HelpdeskMailContainerPatch)
  HelpdeskMailContainer.send(:include, RedmineHelpdeskGPG::Patches::HelpdeskMailContainerPatch)
end
