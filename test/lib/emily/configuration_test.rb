require "test_helper"

module Emily
  class ConfigurationTest < ActiveSupport::TestCase
    test "has default values" do
      config = Configuration.new

      assert_equal :anthropic, config.llm_provider
      assert_equal "Emily", config.bot_name
      assert_equal :bottom_right, config.widget_position
      assert_equal "User", config.user_class
      assert_equal :current_user, config.current_user_method
      assert config.escalation_enabled
      assert config.sound_enabled
      assert_equal({ max_messages: 30, period: 60 }, config.rate_limit)
    end

    test "configure block sets values" do
      Emily.configure do |config|
        config.bot_name = "CustomBot"
        config.widget_position = :bottom_left
      end

      assert_equal "CustomBot", Emily.configuration.bot_name
      assert_equal :bottom_left, Emily.configuration.widget_position

      # Reset
      Emily.configure do |config|
        config.bot_name = "TestBot"
        config.widget_position = :bottom_right
      end
    end

    test "knowledge_providers defaults to empty array" do
      config = Configuration.new
      assert_equal [], config.knowledge_providers
    end

    test "theme defaults to empty hash" do
      config = Configuration.new
      assert_equal({}, config.theme)
    end
  end
end
