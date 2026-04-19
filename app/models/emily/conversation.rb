module Emily
  class Conversation < ApplicationRecord
    belongs_to :user, polymorphic: true, optional: true
    has_many :messages, dependent: :destroy
    has_one :ticket, dependent: :destroy

    enum :status, { open: "open", resolved: "resolved", escalated: "escalated" }
    enum :phase, { sales: "sales", support: "support" }

    validates :session_id, presence: true

    # Guard against MySQL native JSON columns — `serialize` raises
    # ColumnNotSerializableError when the column already casts to JSON natively.
    unless attribute_types["metadata"].is_a?(ActiveRecord::Type::Json)
      serialize :metadata, coder: JSON
    end

    # Escalated conversations must remain resumable: the user still needs to
    # see the agent's replies in the same widget session. Only `resolved` ends
    # the chat from the user's perspective.
    scope :active, -> { where(status: [:open, :escalated]) }

    after_create_commit -> { Emily::Events.publish(:conversation_started, conversation: self) }

    def visitor?
      user.nil?
    end

    def customer?
      user.present?
    end
  end
end
