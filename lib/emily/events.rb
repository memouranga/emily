module Emily
  module Events
    # Publishes events via ActiveSupport::Notifications.
    #
    # Host apps can subscribe via either:
    #
    #   Emily::Events.subscribe(:ticket_created) { |payload| ... }
    #
    # or directly with ActiveSupport::Notifications.
    #
    # Available events:
    #   emily.conversation_started  — payload: { conversation: }
    #   emily.message_received      — payload: { message:, conversation: }
    #   emily.message_sent          — payload: { message:, conversation: }  (AI response)
    #   emily.ticket_created        — payload: { ticket:, conversation: }
    #   emily.ticket_updated        — payload: { ticket: }
    #   emily.escalation            — payload: { ticket:, conversation: }
    #   emily.agent_replied         — payload: { message:, conversation:, ticket: }
    #   emily.message_rated         — payload: { rating:, message: }

    def self.publish(event_name, **payload)
      ActiveSupport::Notifications.instrument("emily.#{event_name}", **payload)
    end

    def self.subscribe(event_name, &block)
      ActiveSupport::Notifications.subscribe("emily.#{event_name}") do |event|
        block.call(event.payload)
      end
    end
  end
end
