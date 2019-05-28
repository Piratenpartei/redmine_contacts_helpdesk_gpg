module RedmineContactsHelpdeskGpg
  module Patches
    module JournalPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          has_one :gpg_journal, dependent: :destroy
        end
      end

      module InstanceMethods
        def gpg_signed?
          gpg_journal && gpg_journal.signed?
        end

        def gpg_encrypted?
          gpg_journal && gpg_journal.encrypted?
        end
      end
    end
  end
end
