require "test_helper"

module Emily
  class RateLimiterTest < ActiveSupport::TestCase
    setup do
      @limiter = RateLimiter.new
    end

    test "allows messages under limit" do
      5.times do
        assert @limiter.allowed?("session_1", max_messages: 10, period: 60)
      end
    end

    test "blocks messages over limit" do
      3.times do
        @limiter.allowed?("session_2", max_messages: 3, period: 60)
      end

      assert_not @limiter.allowed?("session_2", max_messages: 3, period: 60)
    end

    test "different sessions have separate limits" do
      3.times { @limiter.allowed?("session_a", max_messages: 3, period: 60) }

      # session_a is blocked
      assert_not @limiter.allowed?("session_a", max_messages: 3, period: 60)

      # session_b is fine
      assert @limiter.allowed?("session_b", max_messages: 3, period: 60)
    end

    test "is thread-safe" do
      threads = 10.times.map do
        Thread.new do
          20.times { @limiter.allowed?("concurrent", max_messages: 1000, period: 60) }
        end
      end
      threads.each(&:join)

      # Should not raise any errors
      assert true
    end
  end
end
