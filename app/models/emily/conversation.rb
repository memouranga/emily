module Emily
  class Conversation < ApplicationRecord
    belongs_to :user, polymorphic: true, optional: true
    has_many :messages, dependent: :destroy
    has_one :ticket, dependent: :destroy

    enum :status, { open: "open", resolved: "resolved", escalated: "escalated" }
    enum :phase, { sales: "sales", support: "support" }

    validates :session_id, presence: true

    scope :active, -> { where(status: :open) }

    def visitor?
      user.nil?
    end

    def customer?
      user.present?
    end
  end
end
