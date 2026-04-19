module Emily
  class Message < ApplicationRecord
    belongs_to :conversation
    belongs_to :author, polymorphic: true, optional: true
    has_one :rating, dependent: :destroy

    enum :role, { user: "user", assistant: "assistant" }

    validates :content, presence: true
    validates :role, presence: true

    after_create_commit :broadcast_message
    after_create_commit :publish_event

    def human_reply?
      assistant? && author_id.present?
    end

    private

    def broadcast_message
      ActionCable.server.broadcast(
        "emily_conversation_#{conversation.id}",
        { role: role, content: content, message_id: id, created_at: created_at }
      )
    end

    def publish_event
      if user?
        Emily::Events.publish(:message_received, message: self, conversation: conversation)
      elsif human_reply?
        stamp_first_response_on_ticket
        Emily::Events.publish(:agent_replied, message: self, conversation: conversation, ticket: conversation.ticket)
      elsif assistant?
        Emily::Events.publish(:message_sent, message: self, conversation: conversation)
      end
    end

    def stamp_first_response_on_ticket
      ticket = conversation.ticket
      return unless ticket
      return if ticket.first_response_at.present?
      ticket.update_column(:first_response_at, created_at || Time.current)
    end
  end
end
