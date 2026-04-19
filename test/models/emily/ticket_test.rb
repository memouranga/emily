require "test_helper"

module Emily
  class TicketTest < ActiveSupport::TestCase
    test "creates ticket" do
      conv = create_conversation
      ticket = conv.create_ticket!(subject: "Need help")

      assert ticket.persisted?
      assert ticket.open?
      assert ticket.normal?
    end

    test "requires subject" do
      conv = create_conversation
      assert_raises(ActiveRecord::RecordInvalid) do
        conv.create_ticket!(subject: "")
      end
    end

    test "supports priority levels" do
      conv = create_conversation
      ticket = conv.create_ticket!(subject: "Urgent!", priority: :urgent)
      assert ticket.urgent?
    end

    test "supports status transitions" do
      conv = create_conversation
      ticket = conv.create_ticket!(subject: "Help")

      ticket.in_progress!
      assert ticket.in_progress?

      ticket.resolved!
      assert ticket.resolved?

      ticket.closed!
      assert ticket.closed?
    end

    test "belongs to conversation" do
      conv = create_conversation
      ticket = conv.create_ticket!(subject: "Help")
      assert_equal conv, ticket.conversation
    end

    test "sets resolved_at and resolved_by when status flips to resolved" do
      conv = Emily::Conversation.create!(session_id: "t", phase: :support)
      ticket = conv.create_ticket!(subject: "s", summary: "x")
      ticket.update!(assignee_type: "User", assignee_id: 42)
      ticket.update!(status: "resolved", resolved_by_type: "User", resolved_by_id: 42)
      assert_not_nil ticket.reload.resolved_at
      assert_equal 42, ticket.resolved_by_id
    end

    test "clears resolution fields when un-resolving a ticket" do
      conv = Emily::Conversation.create!(session_id: "u", phase: :support)
      ticket = conv.create_ticket!(subject: "reopen me", summary: "x")
      ticket.update!(status: "resolved", resolved_by_type: "User", resolved_by_id: 1)
      assert_not_nil ticket.reload.resolved_at
      ticket.update!(status: "in_progress")
      ticket.reload
      assert_nil ticket.resolved_at
      assert_nil ticket.resolved_by_type
      assert_nil ticket.resolved_by_id
    end
  end
end
