module Emily
  class MessagesController < ApplicationController
    def create
      conversation = Conversation.find(params[:conversation_id])

      # Save user message
      conversation.messages.create!(role: :user, content: params[:content])

      # Generate AI response async
      Emily::ChatJob.perform_later(conversation.id)

      head :ok
    end
  end
end
