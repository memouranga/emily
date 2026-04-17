require "active_hashcash"

module Emily
  class Engine < ::Rails::Engine
    isolate_namespace Emily

    initializer "emily.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/assets/stylesheets")
        app.config.assets.paths << root.join("app/assets/images")
      end
    end

    config.to_prepare do
      if defined?(ActionController::Base)
        ActionController::Base.helper Emily::Engine.helpers
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

    # Propagate Emily's configured hashcash base complexity to ActiveHashcash.
    # The gem's default #hashcash_bits reads ActiveHashcash.bits and applies
    # IP-adaptive log2 amplification automatically.
    initializer "emily.hashcash", after: :load_config_initializers do
      if Emily.configuration&.hashcash_enabled?
        ActiveHashcash.bits = Emily.configuration.hashcash_bits
      end
    end
  end
end
