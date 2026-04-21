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
    # Also guard the `attribute_types` call itself: it hits the schema cache,
    # which raises StatementInvalid in environments where the table does not
    # exist yet (fresh deploys, `db:migrate` inside a booting production
    # container, test DBs before load_schema). In that case we fall through
    # to `serialize` — the right choice for a yet-to-be-created table.
    begin
      needs_serialize = !attribute_types["metadata"].is_a?(ActiveRecord::Type::Json)
    rescue ActiveRecord::StatementInvalid
      needs_serialize = true
    end
    serialize :metadata, coder: JSON if needs_serialize

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
