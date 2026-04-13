require "test_helper"

module Emily
  class MessageTest < ActiveSupport::TestCase
    test "creates user message" do
      conv = create_conversation
      msg = create_message(conv, role: :user, content: "Hello!")

      assert msg.persisted?
      assert msg.user?
      assert_equal "Hello!", msg.content
    end

    test "creates assistant message" do
      conv = create_conversation
      msg = create_message(conv, role: :assistant, content: "Hi there!")

      assert msg.assistant?
    end

    test "requires content" do
      conv = create_conversation
      assert_raises(ActiveRecord::RecordInvalid) do
        conv.messages.create!(role: :user, content: "")
      end
    end

    test "requires role" do
      conv = create_conversation
      assert_raises(ActiveRecord::RecordInvalid) do
        conv.messages.create!(content: "Hello")
      end
    end

    test "belongs to conversation" do
      conv = create_conversation
      msg = create_message(conv)
      assert_equal conv, msg.conversation
    end

    test "can have rating" do
      conv = create_conversation
      msg = create_message(conv, role: :assistant, content: "Help!")
      rating = msg.create_rating!(conversation: conv, score: 2)

      assert_equal rating, msg.rating
      assert_equal 2, rating.score
    end
  end
end
