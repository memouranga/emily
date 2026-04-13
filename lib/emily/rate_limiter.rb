module Emily
  # Simple in-memory rate limiter. For production, override with Redis-based limiter.
  # Limits messages per session to prevent spam.
  #
  # Usage in configuration:
  #   config.rate_limit = { max_messages: 30, period: 60 }  # 30 messages per 60 seconds
  #
  class RateLimiter
    def initialize
      @store = {}
      @mutex = Mutex.new
    end

    def allowed?(session_id, max_messages: 30, period: 60)
      @mutex.synchronize do
        cleanup_expired(period)

        key = session_id.to_s
        @store[key] ||= []
        @store[key].reject! { |t| t < Time.current - period }

        if @store[key].size < max_messages
          @store[key] << Time.current
          true
        else
          false
        end
      end
    end

    private

    def cleanup_expired(period)
      cutoff = Time.current - period
      @store.each do |key, timestamps|
        timestamps.reject! { |t| t < cutoff }
      end
      @store.reject! { |_, v| v.empty? }
    end
  end
end
