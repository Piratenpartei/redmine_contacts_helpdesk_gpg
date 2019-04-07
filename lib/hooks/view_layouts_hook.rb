module RedmineHelpdeskGPG
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(_context = {})
        stylesheet_link_tag(:helpdesk_gpg, plugin: 'redmine_contacts_helpdesk_gpg')
      end
    end
  end
end
