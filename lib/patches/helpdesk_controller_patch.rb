require_dependency 'helpdesk_controller'

module RedmineHelpdeskGPG
  module Patches
    module HelpdeskControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development

          alias_method :set_settings_without_gpg, :set_settings
          alias_method :set_settings, :set_settings_with_gpg

          alias_method :set_settings_param_without_gpg, :set_settings_param
          alias_method :set_settings_param, :set_settings_param_with_gpg
        end
      end

      module InstanceMethods
        def set_settings_with_gpg
          set_settings_param(:gpg_decrypt_key)
          set_settings_param(:gpg_decrypt_key_password)

          set_settings_param(:gpg_sign_key)
          set_settings_param(:gpg_sign_key_password)

          set_settings_param(:gpg_send_default_action)

          set_settings_without_gpg # call original method
        end

        def set_settings_param_with_gpg(param)
          if %i[gpg_decrypt_key_password gpg_sign_key_password].include?(param)
            ContactsSetting[param, @project.id] = params[param] if params[param] && params[param].present?
          else
            set_settings_param_without_gpg(param)
          end
        end
      end
    end
  end
end

unless HelpdeskController.included_modules.include?(RedmineHelpdeskGPG::Patches::HelpdeskControllerPatch)
  HelpdeskController.send(:include, RedmineHelpdeskGPG::Patches::HelpdeskControllerPatch)
end
