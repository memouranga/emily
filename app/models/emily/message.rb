module Emily
  class Message < ApplicationRecord
    belongs_to :conversation

    enum :role, { user: "user", assistant: "assistant" }

    validates :content, presence: true
    validates :role, presence: true

    after_create_commit :broadcast_message
    after_create_commit :publish_event

    private

    def broadcast_message
      ActionCable.server.broadcast(
        "emily_conversation_#{conversation.id}",
        { role: role, content: content, created_at: created_at }
      )
    end

    def publish_event
      event = user? ? :message_received : :message_sent
      Emily::Events.publish(event, message: self, conversation: conversation)
    end
  end
end
