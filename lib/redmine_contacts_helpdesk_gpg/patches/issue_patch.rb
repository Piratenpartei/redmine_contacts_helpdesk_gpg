module RedmineContactsHelpdeskGpg
  module Patches
    module IssuePatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          has_one :gpg_journal, dependent: :destroy
          accepts_nested_attributes_for :gpg_journal
          validate :validate_recipient_gpg_keys_present
        end
      end

      module InstanceMethods
        def gpg_signed?
          gpg_journal&.signed?
        end

        def gpg_encrypted?
          gpg_journal&.encrypted?
        end

        private

        def validate_recipient_gpg_keys_present

          receivers =
            if current_journal
              return unless current_journal.gpg_journal&.encrypted?
              return unless current_journal.journal_message

              # encrypted response
              message = current_journal.journal_message
              [
                message[:to_address]&.split(','),
                message[:cc_address]&.split(','),
                message[:bcc_address]&.split(',')
              ].flatten.compact
            elsif gpg_journal&.encrypted? && helpdesk_ticket.from_address.present?
              # initial encrypted message
              [helpdesk_ticket.from_address]
            end

          return if receivers.nil?

          missing_keys = GpgKeys.missing_keys_for_encryption(receivers)
          missing_keys.each do |key|
            errors.add(:base, l(:msg_gpg_key_missing, missing: key))
          end
        end
      end
    end
  end
end
