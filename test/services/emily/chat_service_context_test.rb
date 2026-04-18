require "test_helper"

module Emily
  class ChatServiceContextTest < ActiveSupport::TestCase
    setup do
      @conversation = Emily::Conversation.create!(
        session_id: "s-ctx",
        phase: "support",
        metadata: { "current_page" => "/patients/42" }
      )
      @conversation.messages.create!(role: :user, content: "¿cómo cambio la edad?")
    end

    test "injects user_context_builder output into the system prompt" do
      cfg = Emily.configuration
      previous = cfg.user_context_builder
      cfg.user_context_builder = ->(conv) {
        ["User: Dr. Memo", "Page: #{conv.metadata['current_page']}"]
      }

      service = Emily::ChatService.new(@conversation)
      messages = service.send(:build_messages, "")

      system_content = messages.first[:content]
      assert_includes system_content, "Conversation context:"
      assert_includes system_content, "User: Dr. Memo"
      assert_includes system_content, "Page: /patients/42"
    ensure
      cfg.user_context_builder = previous
    end

    test "skips context section when builder is not configured" do
      cfg = Emily.configuration
      previous = cfg.user_context_builder
      cfg.user_context_builder = nil

      service = Emily::ChatService.new(@conversation)
      messages = service.send(:build_messages, "")

      refute_includes messages.first[:content], "Conversation context:"
    ensure
      cfg.user_context_builder = previous
    end

    test "builder errors are logged and do not raise" do
      cfg = Emily.configuration
      previous = cfg.user_context_builder
      cfg.user_context_builder = ->(_conv) { raise "boom" }

      service = Emily::ChatService.new(@conversation)
      assert_nothing_raised do
        service.send(:build_messages, "")
      end
    ensure
      cfg.user_context_builder = previous
    end
  end
end
