module Emily
  class Ticket < ApplicationRecord
    belongs_to :conversation

    enum :status, { open: "open", in_progress: "in_progress", resolved: "resolved", closed: "closed" }
    enum :priority, { low: "low", normal: "normal", high: "high", urgent: "urgent" }

    validates :subject, presence: true

    after_create_commit :publish_created
    after_update_commit :publish_updated

    private

    def publish_created
      Emily::Events.publish(:ticket_created, ticket: self, conversation: conversation)
      Emily::Events.publish(:escalation, ticket: self, conversation: conversation)
    end

    def publish_updated
      Emily::Events.publish(:ticket_updated, ticket: self)
    end
  end
end
