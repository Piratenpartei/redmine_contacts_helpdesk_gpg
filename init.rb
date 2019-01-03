require 'redmine'

Rails.logger.info 'Starting GPG Helper Plugin for RedmineUP\'s Helpdesk Plugin'

# Plugin definition
Redmine::Plugin.register :redmine_contacts_helpdesk_gpg do
	name 'Redmine Contacts Helpdesk GPG plugin'
	author 'darkstarSH'
	description 'This is a plugin for Redmine to use GPG signing/encryption in RedmineUP\'s helpdesk'
	version '0.0.9'
	url 'https://github.com/darkstarSH'
	author_url 'mailto:gpg_helpdesk@piepgras.name'

	requires_redmine :version_or_higher => '2.6'
	requires_redmine_plugin :redmine_contacts, :version_or_higher => '4.1.0'
	requires_redmine_plugin :redmine_contacts_helpdesk, :version_or_higher => '4.0.0'

	settings :default => {
		:gpg_keyrings_dir	=> if ENV['GNUPGHOME'] then ENV['GNUPGHOME'] else '~/.gnupg' end,
		:gpg_keyserver		=> 'http://pool.sks-keyservers.net:11371'
	}, :partial => 'settings/gpg_settings'

	menu :admin_menu, :gpg_keystore, {:controller => 'gpgkeys', :action => 'index'}, :caption => :label_gpg_keystore, :param => nil, :html => {:class => 'icon'}
end

require 'redmine_contacts_helpdesk_gpg'