module Emily
  class Ticket < ApplicationRecord
    belongs_to :conversation
    belongs_to :assignee, polymorphic: true, optional: true
    belongs_to :resolved_by, polymorphic: true, optional: true
    has_many :internal_notes, dependent: :destroy

    enum :status, { open: "open", in_progress: "in_progress", resolved: "resolved", closed: "closed" }
    enum :priority, { low: "low", normal: "normal", high: "high", urgent: "urgent" }

    validates :subject, presence: true

    before_save :track_resolution
    after_create_commit :publish_created
    after_update_commit :publish_updated

    private

    def track_resolution
      return unless will_save_change_to_status?

      if status == "resolved"
        self.resolved_at ||= Time.current
      else
        self.resolved_at = nil
        self.resolved_by_type = nil
        self.resolved_by_id = nil
      end
    end

    def publish_created
      Emily::Events.publish(:ticket_created, ticket: self, conversation: conversation)
      Emily::Events.publish(:escalation, ticket: self, conversation: conversation)
    end

    def publish_updated
      Emily::Events.publish(:ticket_updated, ticket: self)
    end
  end
end
