# require_dependency 'gpgkeys'

module HelpDeskGPG
  class << self
    def settings
      ActionController::Parameters.new(Setting[:plugin_redmine_contacts_helpdesk_gpg])
    end

    def setting?(value)
      Additionals.true?(settings[value])
    end

    def keyrings_dir
      settings[:gpg_keyrings_dir]
    end

    def keyserver
      settings[:gpg_keyserver]
    end

    def setup
      # Patches
      Additionals.patch(%w[HelpdeskMailContainer 
                           HelpdeskMailMessenger
                           HelpdeskController
                           Issue
                           Journal], 'redmine_contacts_helpdesk_gpg')

      IssuesController.send :helper, GpgIssuesHelper

      # Hooks
      require_dependency 'hooks/view_issues_hook'
      require_dependency 'hooks/view_layouts_hook'
      require_dependency 'hooks/issues_controller_hook'

    end
  end

  class Helper
    def self.new_context
      GPGME::Ctx.new(pinentry_mode: GPGME::PINENTRY_MODE_LOOPBACK)
    end

    def self.engine_infos
      res = []
      GPGME::Engine.info.each do |inf|
        res.push("protocol='#{inf.instance_variable_get(:@protocol)}',
                  @file_name='#{inf.instance_variable_get(:@file_name)}',
                  @version='#{inf.instance_variable_get(:@version)}'")
      end
      res
    end

    def self.keystoresize
      ENV['GNUPGHOME'] = HelpDeskGPG.keyrings_dir
      GPGME::Engine.home_dir = HelpDeskGPG.keyrings_dir
      ctx = new_context
      pub = ctx.keys(nil, false)
      priv = ctx.keys(nil, true)
      ctx.release

      [pub.length, priv.length]
    end

    def self.private_keys_select_options
      priv = GPGME::Key.find(:secret)
      options = []
      priv.each do |k|
        label = "0x#{k.primary_subkey.fingerprint[-8..-1]} &lt;#{k.primary_uid.email}&gt;".html_safe
        options.push([label, k.primary_subkey.fingerprint])
      end
      options
    end

    def self.shorten_fingerprint(fpr)
      fpr[-8..-1]
    end

    def self.project_fingerprint(project)
      "0x#{HelpDeskGPG::Helper.shorten_fingerprint(HelpdeskSettings[:gpg_sign_key, project.id])})"
    end

    def self.send_defaults_select_options
      [[(I18n.translate :label_no_key), ''],
       [(I18n.translate :label_gpg_action_sign), '1'],
       [(I18n.translate :label_gpg_action_encrypt), '2'],
       [(I18n.translate :label_gpg_action_both), '3']]
    end

    def self.send_mail_signed_by_default(project)
      HelpdeskSettings[:gpg_send_default_action, project.id].to_i & 1 > 0
    end

    def self.send_mail_encrypted_by_default(project)
      HelpdeskSettings[:gpg_send_default_action, project.id].to_i & 2 > 0
    end
  end
end
