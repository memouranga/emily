module Emily
  module Admin
    class AnalyticsController < ApplicationController
      def index
        @period = params[:period] || "30"
        @since = @period.to_i.days.ago

        conversations = Conversation.where("created_at >= ?", @since)
        messages = Message.where("created_at >= ?", @since)
        tickets = Ticket.where("created_at >= ?", @since)

        @stats = {
          # Conversations
          total_conversations: conversations.count,
          sales_conversations: conversations.where(phase: :sales).count,
          support_conversations: conversations.where(phase: :support).count,
          active_conversations: conversations.where(status: :open).count,

          # Resolution
          resolved_by_ai: conversations.where(status: :resolved).count,
          escalated: conversations.where(status: :escalated).count,
          resolution_rate: resolution_rate(conversations),

          # Messages
          total_messages: messages.count,
          user_messages: messages.where(role: :user).count,
          ai_messages: messages.where(role: :assistant).count,
          avg_messages_per_conversation: avg_messages(conversations, messages),

          # Tickets
          total_tickets: tickets.count,
          open_tickets: tickets.where(status: :open).count,
          in_progress_tickets: tickets.where(status: :in_progress).count,
          resolved_tickets: tickets.where(status: [ :resolved, :closed ]).count,
          urgent_tickets: tickets.where(priority: :urgent).count,

          # Daily breakdown
          conversations_by_day: group_by_day(conversations),
          messages_by_day: group_by_day(messages)
        }

        respond_to do |format|
          format.html
          format.json { render json: @stats }
        end
      end

      private

      def resolution_rate(conversations)
        total = conversations.where(status: [ :resolved, :escalated ]).count
        return 0 if total.zero?

        resolved = conversations.where(status: :resolved).count
        (resolved.to_f / total * 100).round(1)
      end

      def avg_messages(conversations, messages)
        return 0 if conversations.count.zero?
        (messages.count.to_f / conversations.count).round(1)
      end

      def group_by_day(relation)
        relation.group("DATE(created_at)").count.transform_keys(&:to_s)
      end
    end
  end
end
