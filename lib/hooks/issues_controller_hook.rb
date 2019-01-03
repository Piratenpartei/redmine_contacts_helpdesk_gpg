module RedmineHelpdeskGPG
  class IssuesControllerHookHelper

    @journals = {}

    def self.prepareJournal(issue, journal, params)
      if params[:gpg_do_encrypt] || params[:gpg_do_sign]
        item = GpgJournal.new
        item.was_signed = params[:gpg_do_sign]
        item.was_encrypted = params[:gpg_do_encrypt]
        item.journal = journal
        @journals[issue.id] = item
      end

    end

    def self.queryJournal(issue_id)
      return @journals[issue_id]
    end

    def self.saveJournal(issue_id)
      item = @journals[issue_id]
      if !item.nil?
        item.save
        @journals.delete(issue_id)
      end
    end
  end

  module Hooks
    class IssuesControllerHook < Redmine::Hook::ViewListener

      def controller_issues_edit_before_save(context = {})
        # context => { :params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal})
        IssuesControllerHookHelper.prepareJournal(context[:issue], context[:journal], context[:params][:helpdesk])
      end

      def controller_issues_edit_after_save (context = {})
        # context => { :params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal})
        IssuesControllerHookHelper.saveJournal((context[:issue]).id)
      end

    end
  end
end
