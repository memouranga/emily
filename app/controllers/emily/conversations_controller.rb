module Emily
  class ConversationsController < ApplicationController
    include ActiveHashcash

    before_action :verify_hashcash_if_enabled, only: :create

    def create
      resolved_session_id = emily_session_id
      target_phase = current_emily_user ? :support : :sales

      conversation = Conversation.active
        .where(session_id: resolved_session_id, phase: target_phase)
        .order(created_at: :desc)
        .first

      resumed = conversation.present?

      unless resumed
        conversation = Conversation.create!(
          session_id: resolved_session_id,
          user: current_emily_user,
          phase: target_phase,
          metadata: {
            page: params[:page],
            referrer: request.referrer,
            user_agent: request.user_agent
          }
        )

        conversation.messages.create!(
          role: :assistant,
          content: Emily.configuration&.bot_greeting || "Hi! How can I help you?"
        )
      end

      render json: { conversation_id: conversation.id, resumed: resumed }
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

    def emily_session_id
      session[:emily_session_id] ||= (session.id&.to_s.presence || SecureRandom.hex(16))
    end
  end
end
