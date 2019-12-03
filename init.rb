require 'redmine_contacts_helpdesk_gpg'

Rails.logger.info 'Starting GPG Helper Plugin for RedmineUP\'s Helpdesk Plugin'

# Plugin definition
Redmine::Plugin.register :redmine_contacts_helpdesk_gpg do
  name 'Redmine Contacts Helpdesk GPG'
  author 'darkstarSH / Alphanodes GmbH / Tobias Stenzel'
  description 'This is a plugin for Redmine to use GPG signing/encryption in RedmineUP\'s helpdesk'
  version '19.12.0'
  url 'https://github.com/piratenpartei/redmine_contacts_helpdesk_gpg'

  requires_redmine version_or_higher: '3.4'
  requires_redmine_plugin :redmine_contacts, version_or_higher: '4.2.1'
  requires_redmine_plugin :redmine_contacts_helpdesk, version_or_higher: '4.0.0'

  settings default: {
    gpg_keyrings_dir: ENV['GNUPGHOME'] || '~/.gnupg',
    gpg_keyserver: 'http://pool.sks-keyservers.net:11371'
  }, partial: 'settings/gpg_settings'

  menu :admin_menu, :gpg_keystore, { controller: 'gpgkeys', action: 'index' }, caption: :label_gpg_keystore, param: nil, html: { class: 'icon' }
end

if ActiveRecord::Base.connection.table_exists?(:settings)
  Rails.configuration.to_prepare do
    HelpDeskGPG.setup
  end
end
