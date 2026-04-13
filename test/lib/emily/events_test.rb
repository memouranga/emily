require "test_helper"

module Emily
  class EventsTest < ActiveSupport::TestCase
    test "publishes event and receives payload" do
      received = nil

      ActiveSupport::Notifications.subscribe("emily.test_event") do |event|
        received = event.payload
      end

      Events.publish(:test_event, message: "hello", count: 42)

      assert_not_nil received
      assert_equal "hello", received[:message]
      assert_equal 42, received[:count]

      ActiveSupport::Notifications.unsubscribe("emily.test_event")
    end

    test "no error when no subscribers" do
      # Should not raise
      Events.publish(:no_subscribers, data: "test")
      assert true
    end
  end
end
