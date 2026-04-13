module Emily
  class MessagesController < ApplicationController
    before_action :check_rate_limit, only: :create

    def create
      conversation = Conversation.find(params[:conversation_id])

      # Save user message
      conversation.messages.create!(role: :user, content: params[:content])

      # Generate AI response async
      Emily::ChatJob.perform_later(conversation.id)

      head :ok
    end

    private

    def check_rate_limit
      return if Emily.rate_limiter.allowed?(session.id.to_s)

      render json: { error: "Rate limit exceeded. Please wait a moment." }, status: :too_many_requests
    end
  end
end
