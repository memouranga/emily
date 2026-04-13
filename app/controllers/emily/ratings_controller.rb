module Emily
  class RatingsController < ApplicationController
    def create
      message = Message.find(params[:message_id])
      rating = message.create_rating!(
        conversation: message.conversation,
        score: params[:score],
        feedback: params[:feedback]
      )

      render json: { id: rating.id, score: rating.score }
    end
  end
end
