require "test_helper"

module Emily
  class InternalNoteTest < ActiveSupport::TestCase
    test "belongs to ticket and requires body" do
      conv = Emily::Conversation.create!(session_id: "n", phase: :support)
      ticket = conv.create_ticket!(subject: "s")
      note = Emily::InternalNote.new(ticket: ticket, body: "")
      assert_not note.valid?
      note.body = "revisar"
      assert note.valid?
      note.save!
      assert_includes ticket.internal_notes.reload, note
    end
  end
end
