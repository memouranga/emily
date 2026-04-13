require "emily/version"
require "emily/engine"
require "emily/configuration"
require "emily/markdown_renderer"
require "emily/events"
require "emily/conversation_flow"
require "emily/rate_limiter"

module Emily
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    def rate_limiter
      @rate_limiter ||= RateLimiter.new
    end
  end
end
