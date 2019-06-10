module HelpDeskGPG
  module Hooks
    class IssuesControllerHook < Redmine::Hook::ViewListener
      def controller_issues_edit_before_save(context = {})
        # context => { :params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal})
        GpgJournalHelper.prepareJournal(context[:issue], context[:journal], context[:params][:helpdesk])
      end

      def controller_issues_edit_after_save(context = {})
        # context => { :params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal})
        GpgJournalHelper.saveJournal((context[:issue]).id)
      end
    end
  end
end
