module Emily
  class ChatJob < ApplicationJob
    queue_as :default

    def perform(conversation_id)
      conversation = Emily::Conversation.find(conversation_id)
      Emily::ChatService.new(conversation).respond
    end
  end
end
