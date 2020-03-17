module HelpDeskGPG
  module Hooks
    class IssuesControllerHook < Redmine::Hook::ViewListener
      def controller_issues_edit_before_save(context = {})
        # context => { :params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal})
        helpdesk_params = context[:params][:helpdesk]
        return unless helpdesk_params && helpdesk_params[:is_send_mail]

        GpgJournalHelper.prepare_journal(context[:issue], context[:journal], context[:params][:helpdesk])
      end

      def controller_issues_edit_after_save(context = {})
        context[:journal].gpg_journal&.save
      end
    end
  end
end
