module Emily
  class Ticket < ApplicationRecord
    belongs_to :conversation

    enum :status, { open: "open", in_progress: "in_progress", resolved: "resolved", closed: "closed" }
    enum :priority, { low: "low", normal: "normal", high: "high", urgent: "urgent" }

    validates :subject, presence: true
  end
end
