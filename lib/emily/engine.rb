module Emily
  class Engine < ::Rails::Engine
    isolate_namespace Emily

    initializer "emily.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Emily::ApplicationHelper
      end
    end

    initializer "emily.i18n" do
      config.i18n.load_path += Dir[Emily::Engine.root.join("config/locales/**/*.yml")]
    end
  end
end
