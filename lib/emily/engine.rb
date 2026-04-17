module Emily
  class Engine < ::Rails::Engine
    isolate_namespace Emily

    initializer "emily.assets" do |app|
      app.config.assets.paths << root.join("app/assets/stylesheets")
      app.config.assets.paths << root.join("app/assets/images")
    end

    initializer "emily.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Emily::Engine.helpers
      end
    end

    initializer "emily.i18n" do
      config.i18n.load_path += Dir[Emily::Engine.root.join("config/locales/**/*.yml")]
    end

    initializer "emily.llm", after: :load_config_initializers do
      require "ruby_llm"
      cfg = Emily.configuration
      if cfg&.api_key.present?
        ::RubyLLM.configure do |c|
          c.anthropic_api_key = cfg.api_key if cfg.llm_provider == :anthropic
          c.openai_api_key = cfg.api_key if cfg.llm_provider == :openai
        end
      end
    end
  end
end
