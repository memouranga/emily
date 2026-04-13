require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)
require "emily"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.active_support.deprecation = :stderr
    config.root = File.expand_path("..", __dir__)
  end
end
