module Emily
  class Engine < ::Rails::Engine
    isolate_namespace Emily

    initializer "emily.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Emily::ApplicationHelper
      end
    end
  end
end
