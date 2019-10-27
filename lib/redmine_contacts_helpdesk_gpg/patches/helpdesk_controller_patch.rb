require_dependency 'helpdesk_controller'

module RedmineContactsHelpdeskGpg
  module Patches
    module HelpdeskControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method :set_settings_without_gpg, :set_settings
          alias_method :set_settings, :set_settings_with_gpg
        end
      end

      module InstanceMethods
        def set_settings_with_gpg
          set_settings_param(:gpg_decrypt_key)

          set_settings_param(:gpg_sign_key)

          set_settings_param(:gpg_send_default_action)

          set_settings_without_gpg # call original method
        end
      end
    end
  end
end
