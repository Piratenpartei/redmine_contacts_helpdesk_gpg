module RedmineContactsHelpdeskGpg
  module Patches
    module IssuesControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          before_action :add_gpg_journal_initial_message, only: [:create]
          after_action :save_gpg_journal_initial_message, only: [:create]
        end
      end

      module InstanceMethods
        def add_gpg_journal_initial_message
          helpdesk_params = params[:helpdesk]
          return unless helpdesk_params && params[:helpdesk_send_as] != "0"

          HelpDeskGPG::GpgJournalHelper.prepare_journal(@issue, nil, helpdesk_params)
        end

        def save_gpg_journal_initial_message
          @issue.gpg_journal&.save
        end
      end
    end
  end
end
