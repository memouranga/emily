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
  end
end
