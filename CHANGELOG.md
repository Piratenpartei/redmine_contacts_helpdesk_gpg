Changelog
=========

19.12.0
-------

* Fix handling incoming signed mails, ignore verification errors.
  Signature verification errors are handled like an invalid signature.


19.11.1
-------

* Catch and log GPGME errors.
* Improve mail (in/out) logging to catch errors in the GPG and helpdesk plugins.
* Add some missing German translations.

* Fix error for new helpdesk issues when contact has been created in the issue.

19.11.0
-------

* Fix key status info for Helpdesk 4.1.5.

19.10.0
-------

* Remove support for GPG passphrases.


0.5.1
-----

* Fix saving of issues that were encrypted initially.

0.5.0 (Jun 2019)
----------------

* Fix for mail area customizations for Helpdesk 4.1.0.
* GPG options checkboxes are now on the same line as the mail checkbox above the mail area.
* Always show full recipient fields, CC / BCC addresses are always visible now.
* Fix display of GPG key indicators for the recipient fields.
* Hide GPG options if mail checkbox is not checked.
* Give earlier feedback about missing keys and don't save journal then.

0.4.0 (Jun 2019)
----------------

* Preselect encryption when replying to an encrypted issue.
* Fix gpg send options checkbox labels.
* code cleanups, modernization
* Fix key lookup from Javascript code.
* target Ruby 2.5

0.3.0 (Apr 2019)
----------------

* Redmine 4.x support
* Merge code from https://github.com/alexandermeindl/redmine_contacts_helpdesk_gpg
  * fixed key management

0.2.0 (Jan 2019)
----------------

* Helpdesk 4.0 support

0.1.0 (Nov 2018)
----------------

* Redmine 3.x support

0.0.7 (Oct 2018)
----------------

* fixed typo
* fixed routing for redmine v3.x
* added missing changelog entries
* checking keys in bcc

0.0.6 (Sep 2015)
----------------

* small fix

0.0.5 (Sep 2015)
----------------

* code refactoring

0.0.4 (May 2015)
----------------

* per project setting: sign/encrypt by default
* enable signing/encryption for new tickets

0.0.3 (March 2015)
----------------

*   Code cleanup
*   Initial checkin

0.0.2 unreleased
----------------

*   added rake tasks for key management

0.0.1 unreleased
----------------

*   initial development version

