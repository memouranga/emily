module Emily
  class InternalNote < ApplicationRecord
    belongs_to :ticket
    belongs_to :author, polymorphic: true, optional: true

    validates :body, presence: true
  end
end
