redmine_contacts_helpdesk_gpg
=============================

Requirements
------------

* Redmine 3.4-4.0
* RedmineCRM's Contacts plugin (pro or light)
* RedmineCRM's Helpdesk plugin (pro)

This plugin does not provide a (licensed) copy of RedmineCRM's plugins. Please get your own. :)

Installation
------------

### Prepare OS

Install these packages

* gnupg_1.4.xx
* optional: gpgsm (on some OS bundled with gnupg)
* libgpgme11-dev (Name may vary depending on OS. It's the package providing executable 'gpgme-config')


### Install required GEMs

  gem install gpgme -- --use-system-libraries
  gem install mail-gpg

Please install gpgme with '--use-system-libraries' because otherwise gpgme would compile its own versions of gpg libraries.

Further development of this plugin expects gpgsm to be available and I hate mixing libraries from different sources.


### Install this plugin

Unarchive plugin to redmine/plugins

  rake redmine:plugins RAILS_ENV=production


Uninstallation
--------------

  rake redmine:plugins NAME=redmine_contacts_helpdesk_gpg VERSION=0 RAILS_ENV=production
  rm -rf plugins/redmine_contacts_helpdesk_gpg


Setup
-----

### Params

* Directory containing key rings - Default is determined by environment GNUPGHOME or fallback "~/.gnupg"
* URL of public key server - Only "http://pool.sks-keyservers.net:11371" has been tested yet. Other keyservers might work...


### Add cron jobs for keystore maintenance

Paths in the following examples should be set according to your environment.

Cron jobs should be run as the same user running redmine (e.g. www-data)

  # refresh keys from keyserver on the first day of the month
  00 00 01 * * cd /srv/redmine && bundle exec rake RAILS_ENV=production redmine:plugins:helpdesk_gpg:refresh_keys
  # delete expired keys from keystore on the 15th
  00 00 15 * * cd /srv/redmine && bundle exec rake RAILS_ENV=production redmine:plugins:helpdesk_gpg:remove_expired_keys


Credits
-------

### Icons

* Icons are taken from "FatCow-Farm Fresh Icons" (http://www.fatcow.com/free-icons) by FatCow Web Hosting (http://www.fatcow.com) and are licensed under CC BY US 3.0 (http://creativecommons.org/licenses/by/3.0/us/)
* Or were inspired by above icons

License
-------

This redmine plugin is released under the MIT license.
