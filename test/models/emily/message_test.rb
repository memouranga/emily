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

    test "human_reply? is true when author set and role is assistant" do
      conv = Emily::Conversation.create!(session_id: "m", phase: :support)
      msg = conv.messages.create!(role: "assistant", content: "hi", author_type: "User", author_id: 7)
      assert msg.human_reply?
    end

    test "human_reply? is false when role is user" do
      conv = Emily::Conversation.create!(session_id: "m2", phase: :support)
      msg = conv.messages.create!(role: "user", content: "hi", author_type: "User", author_id: 7)
      assert_not msg.human_reply?
    end

    test "publishes agent_replied event on create when human_reply?" do
      conv = Emily::Conversation.create!(session_id: "m3", phase: :support)
      conv.create_ticket!(subject: "s")
      events = []
      sub = ActiveSupport::Notifications.subscribe("emily.agent_replied") do |event|
        events << event.payload
      end
      conv.messages.create!(role: "assistant", content: "reply", author_type: "User", author_id: 9)
      assert_equal 1, events.size
      assert_equal conv.id, events.first[:conversation].id
    ensure
      ActiveSupport::Notifications.unsubscribe(sub) if sub
    end

    test "stamps first_response_at on the ticket when first human reply lands" do
      conv = Emily::Conversation.create!(session_id: "fr", phase: :support)
      ticket = conv.create_ticket!(subject: "s")
      assert_nil ticket.first_response_at
      conv.messages.create!(role: "assistant", content: "reply 1", author_type: "User", author_id: 1)
      assert_not_nil ticket.reload.first_response_at
      original = ticket.first_response_at
      sleep 0.01
      conv.messages.create!(role: "assistant", content: "reply 2", author_type: "User", author_id: 1)
      assert_equal original.to_i, ticket.reload.first_response_at.to_i
    end
  end
end
