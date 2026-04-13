module Emily
  class TicketsController < ApplicationController
    def create
      conversation = Conversation.find(params[:conversation_id])
      ticket = conversation.create_ticket!(
        subject: params[:subject],
        summary: params[:summary],
        priority: params[:priority] || :normal
      )
      conversation.escalated!

      render json: { ticket_id: ticket.id }
    end

    def index
      tickets = Ticket.order(created_at: :desc)
      render json: tickets
    end

    def show
      ticket = Ticket.find(params[:id])
      render json: ticket
    end

    def update
      ticket = Ticket.find(params[:id])
      ticket.update!(ticket_params)
      render json: ticket
    end

    private

    def ticket_params
      params.permit(:status, :priority)
    end
  end
end
