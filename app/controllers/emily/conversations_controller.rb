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

    # Override ActiveHashcash#hashcash_bits to honor Emily.configuration.hashcash_bits
    # while preserving the gem's adaptive IP-based complexity increase.
    def hashcash_bits
      configured = Emily.configuration&.hashcash_bits || ActiveHashcash.bits
      previous_stamp_count = ActiveHashcash::Stamp
        .where(ip_address: hashcash_ip_address)
        .where(created_at: 1.day.ago..)
        .count
      if previous_stamp_count > 0
        (configured + Math.log2(previous_stamp_count)).floor
      else
        configured
      end
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
      return if authenticated_caller?
      check_hashcash
    end

    def authenticated_caller?
      user_method = Emily.configuration&.current_user_method || :current_user
      respond_to?(user_method, true) && send(user_method).present?
    end
  end
end
