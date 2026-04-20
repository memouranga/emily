require "test_helper"

module Emily
  class ConversationsResumeTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "returns existing active conversation for the same session instead of creating a new one" do
      post conversations_path

      first_id = JSON.parse(response.body).fetch("conversation_id")
      assert_equal 1, Emily::Conversation.count
      assert_equal 1, Emily::Conversation.find(first_id).messages.count

      post conversations_path
      body = JSON.parse(response.body)

      assert_equal first_id, body.fetch("conversation_id"), "should reuse the active conversation"
      assert_equal true, body.fetch("resumed"), "should signal the conversation was resumed"
      assert_equal 1, Emily::Conversation.count
      assert_equal 1, Emily::Conversation.find(first_id).messages.count,
        "resume must not duplicate the greeting message"
    end

    test "greets in the configured locale when bot_greeting is nil" do
      original = Emily.configuration.bot_greeting
      Emily.configuration.bot_greeting = nil

      I18n.with_locale(:es) { post conversations_path }

      conversation_id = JSON.parse(response.body).fetch("conversation_id")
      greeting = Emily::Conversation.find(conversation_id).messages.first
      assert_equal "¡Hola! ¿En qué te puedo ayudar?", greeting.content
    ensure
      Emily.configuration.bot_greeting = original
    end

    test "uses bot_greeting callable when configured" do
      original = Emily.configuration.bot_greeting
      Emily.configuration.bot_greeting = ->(conv) { "Custom greeting for conv ##{conv.id}" }

      post conversations_path
      conversation_id = JSON.parse(response.body).fetch("conversation_id")
      greeting = Emily::Conversation.find(conversation_id).messages.first
      assert_equal "Custom greeting for conv ##{conversation_id}", greeting.content
    ensure
      Emily.configuration.bot_greeting = original
    end

    test "creates a new conversation when the previous one is resolved" do
      post conversations_path
      first_id = JSON.parse(response.body).fetch("conversation_id")
      Emily::Conversation.find(first_id).update!(status: :resolved)

      post conversations_path
      body = JSON.parse(response.body)

      refute_equal first_id, body.fetch("conversation_id")
      assert_equal false, body.fetch("resumed")
      assert_equal 2, Emily::Conversation.count
    end
  end
end
