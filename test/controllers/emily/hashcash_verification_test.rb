require "test_helper"

module Emily
  class HashcashVerificationTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @original_anti_bot = Emily.configuration.anti_bot
    end

    teardown do
      Emily.configuration.anti_bot = @original_anti_bot
    end

    test "visitor without hashcash proof is rejected when anti_bot is enabled" do
      Emily.configuration.anti_bot = :hashcash
      post conversations_path, params: { page: "/pricing" }, as: :json
      assert_response :unprocessable_entity
      body = JSON.parse(response.body)
      assert_equal "anti_bot_verification_failed", body["error"]
    end

    test "anti_bot disabled skips verification entirely" do
      Emily.configuration.anti_bot = :none
      post conversations_path, params: { page: "/pricing" }, as: :json
      assert_response :success
      body = JSON.parse(response.body)
      assert body["conversation_id"].present?
    end
  end
end
