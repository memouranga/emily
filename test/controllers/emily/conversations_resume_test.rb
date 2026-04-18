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
