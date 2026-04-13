require "test_helper"

module Emily
  class RatingTest < ActiveSupport::TestCase
    test "creates positive rating" do
      conv = create_conversation
      msg = create_message(conv, role: :assistant, content: "Here's help")
      rating = Rating.create!(message: msg, conversation: conv, score: 2)

      assert rating.persisted?
      assert_equal 2, rating.score
    end

    test "creates negative rating" do
      conv = create_conversation
      msg = create_message(conv, role: :assistant, content: "Bad help")
      rating = Rating.create!(message: msg, conversation: conv, score: 1)

      assert_equal 1, rating.score
    end

    test "validates score inclusion" do
      conv = create_conversation
      msg = create_message(conv, role: :assistant, content: "Help")

      assert_raises(ActiveRecord::RecordInvalid) do
        Rating.create!(message: msg, conversation: conv, score: 5)
      end
    end

    test "positive and negative scopes" do
      conv = create_conversation
      msg1 = create_message(conv, role: :assistant, content: "Good")
      msg2 = create_message(conv, role: :assistant, content: "Bad")

      pos = Rating.create!(message: msg1, conversation: conv, score: 2)
      neg = Rating.create!(message: msg2, conversation: conv, score: 1)

      assert_includes Rating.positive, pos
      assert_includes Rating.negative, neg
      assert_not_includes Rating.positive, neg
    end
  end
end
