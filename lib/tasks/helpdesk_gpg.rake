namespace :redmine do
  namespace :plugins do
    namespace :helpdesk_gpg do
      require_dependency File.dirname(__FILE__) + '/../gpgkeys.rb'

      desc <<-DESCRIPTION
      Update all keys in keystore from public keyserver

      Examples:
        rake redmine:plugins:helpdesk_gpg:refresh_keys RAILS_ENV="production"
      DESCRIPTION

      task refresh_keys: :environment do
        GpgKeys.init_gpg
        keys = GpgKeys.find_all_keys
        puts "found #{keys.count} keys"
        GpgKeys.refresh_keys
        puts 'done...'
      end

      desc <<-DESCRIPTION
      Remove all expired keys from keystore

      Examples:
        rake redmine:plugins:helpdesk_gpg:remove_expired_keys RAILS_ENV="production"
      DESCRIPTION

      task remove_expired_keys: :environment do
        GpgKeys.init_gpg
        GpgKeys.remove_expired_keys
      end
    end
  end
end
