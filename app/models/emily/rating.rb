module Emily
  class Rating < ApplicationRecord
    belongs_to :message
    belongs_to :conversation

    validates :score, presence: true, inclusion: { in: [ 1, 2 ] }

    scope :positive, -> { where(score: 2) }
    scope :negative, -> { where(score: 1) }

    after_create_commit -> { Emily::Events.publish(:message_rated, rating: self, message: message) }
  end
end
