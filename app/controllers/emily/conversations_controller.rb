module Emily
  class ConversationsController < ApplicationController
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
  end
end
