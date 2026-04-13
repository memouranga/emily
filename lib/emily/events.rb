module Emily
  module Events
    # Publishes events via ActiveSupport::Notifications.
    # Host apps subscribe with:
    #
    #   ActiveSupport::Notifications.subscribe("emily.ticket_created") do |event|
    #     AdminMailer.new_ticket(event.payload[:ticket]).deliver_later
    #   end
    #
    # Available events:
    #   emily.conversation_started  — payload: { conversation: }
    #   emily.message_received      — payload: { message:, conversation: }
    #   emily.message_sent          — payload: { message:, conversation: }  (AI response)
    #   emily.ticket_created        — payload: { ticket:, conversation: }
    #   emily.ticket_updated        — payload: { ticket: }
    #   emily.escalation            — payload: { ticket:, conversation: }

    def self.publish(event_name, **payload)
      ActiveSupport::Notifications.instrument("emily.#{event_name}", **payload)
    end
  end
end
