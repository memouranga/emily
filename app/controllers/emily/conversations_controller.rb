module Emily
  class ConversationsController < ApplicationController
    include ActiveHashcash

    before_action :verify_hashcash_if_enabled, only: :create

    def create
      conversation = Conversation.create!(
        session_id: session.id.to_s,
        user: current_emily_user,
        phase: current_emily_user ? :support : :sales,
        metadata: {
          page: params[:page],
          referrer: request.referrer,
          user_agent: request.user_agent
        }
      )

      # Send greeting
      conversation.messages.create!(
        role: :assistant,
        content: Emily.configuration&.bot_greeting || "Hi! How can I help you?"
      )

      render json: { conversation_id: conversation.id }
    end

    def show
      conversation = Conversation.find(params[:id])
      render json: {
        id: conversation.id,
        status: conversation.status,
        phase: conversation.phase,
        messages: conversation.messages.order(:created_at).map { |m|
          { role: m.role, content: m.content, created_at: m.created_at }
        }
      }
    end

    # Override ActiveHashcash#hashcash_after_failure to render a JSON 422
    # instead of raising InvalidAuthenticityToken, which is more appropriate
    # for this controller's XHR/JSON clients.
    def hashcash_after_failure
      render json: { error: "anti_bot_verification_failed" }, status: :unprocessable_entity
    end

    private

    def verify_hashcash_if_enabled
      return unless Emily.configuration&.hashcash_enabled?
      return if current_emily_user.present?
      check_hashcash
    end
  end
end
