require "test_helper"

module Emily
  class ConversationTest < ActiveSupport::TestCase
    test "creates conversation with session_id" do
      conv = create_conversation
      assert conv.persisted?
      assert conv.session_id.present?
    end

    test "requires session_id" do
      assert_raises(ActiveRecord::RecordInvalid) do
        Conversation.create!(phase: :sales)
      end
    end

    test "defaults to open status and sales phase" do
      conv = create_conversation
      assert conv.open?
      assert conv.sales?
    end

    test "visitor? returns true when no user" do
      conv = create_conversation
      assert conv.visitor?
      assert_not conv.customer?
    end

    test "has many messages" do
      conv = create_conversation
      create_message(conv, content: "Hello")
      create_message(conv, role: :assistant, content: "Hi there!")
      assert_equal 2, conv.messages.count
    end

    test "can be escalated" do
      conv = create_conversation
      conv.escalated!
      assert conv.escalated?
    end

    test "can be resolved" do
      conv = create_conversation
      conv.resolved!
      assert conv.resolved?
    end

    test "active scope returns open conversations" do
      open_conv = create_conversation
      resolved_conv = create_conversation
      resolved_conv.resolved!

      assert_includes Conversation.active, open_conv
      assert_not_includes Conversation.active, resolved_conv
    end
  end
end
