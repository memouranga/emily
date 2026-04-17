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
      prime_session!
      post conversations_path, params: { page: "/pricing" }, as: :json
      assert_response :success
      body = JSON.parse(response.body)
      assert body["conversation_id"].present?
    end

    private

    # Integration tests start without a session cookie, so `session.id`
    # returns nil inside ConversationsController#create, and the
    # Conversation model's `validates :session_id, presence: true`
    # blocks the request with a 422 that has nothing to do with hashcash.
    #
    # Write an encrypted session cookie that matches what Rails'
    # EncryptedCookieJar expects, so `session.id` resolves to a valid
    # SessionId on the next request.
    def prime_session!
      request = ActionDispatch::Request.new(
        Rails.application.env_config.merge(
          "HTTP_HOST" => "www.example.com",
          "rack.input" => StringIO.new,
          "REQUEST_METHOD" => "GET",
          "PATH_INFO" => "/"
        )
      )
      jar = ActionDispatch::Cookies::CookieJar.build(request, {})
      jar.encrypted["_dummy_session"] = { value: { "session_id" => SecureRandom.hex(16) } }
      jar.update_cookies_from_jar
      cookies_header = jar.instance_variable_get(:@cookies)
      cookies_header.each do |name, value|
        cookies[name] = value
      end
    end
  end
end
