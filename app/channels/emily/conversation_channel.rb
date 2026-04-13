module Emily
  class ConversationChannel < ActionCable::Channel::Base
    def subscribed
      stream_from "emily_conversation_#{params[:conversation_id]}"
    end
  end
end
