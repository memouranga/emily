require "emily/version"
require "emily/engine"
require "emily/configuration"

module Emily
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end
  end
end
