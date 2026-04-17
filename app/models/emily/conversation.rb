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

    scope :active, -> { where(status: :open) }

    after_create_commit -> { Emily::Events.publish(:conversation_started, conversation: self) }

    def visitor?
      user.nil?
    end

    def customer?
      user.present?
    end
  end
end
