module RedmineHelpdeskGPG
  module Hooks
    class ViewIssuesHook < Redmine::Hook::ViewListener
      render_on :view_issues_form_details_bottom, partial: 'issues/gpg_ticket_data_form'
    end
  end
end
