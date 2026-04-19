module Emily
  module Tools
    # Lets the LLM escalate a conversation to a support ticket. Bound to a
    # specific Emily::Conversation — the tool creates the ticket on it and
    # transitions the conversation to :escalated.
    class CreateTicket < ::RubyLLM::Tool
      description <<~DESC
        Crea un ticket de soporte para que el equipo humano de CloudHealth contacte al usuario.
        Úsalo cuando: el usuario explícitamente pide hablar con una persona/humano/soporte,
        reporta un bug o bloqueo operativo que no puedes resolver con la knowledge base,
        o has intentado ayudar y sigue sin resolverse. No lo uses para dudas simples que
        puedes contestar con artículos del knowledge base.
      DESC

      param :subject,
            desc: "Asunto corto (máx 80 chars) describiendo el problema. Ej: 'Error al guardar receta médica'."
      param :summary,
            desc: "Resumen del problema y lo que el usuario ha intentado, en 2-4 frases. Incluye datos relevantes que el usuario haya compartido."
      param :priority,
            desc: "Prioridad: 'low' (consulta general), 'normal' (default), 'high' (bloquea trabajo), 'urgent' (afecta pacientes o pagos).",
            required: false

      def initialize(conversation)
        super()
        @conversation = conversation
      end

      def name
        "create_ticket"
      end

      def execute(subject:, summary:, priority: "normal")
        priority = "normal" unless %w[low normal high urgent].include?(priority.to_s)

        ticket = @conversation.create_ticket!(
          subject: subject.to_s.strip.first(255),
          summary: summary.to_s.strip,
          priority: priority
        )
        @conversation.escalated!

        {
          ok: true,
          ticket_id: ticket.id,
          message: "Ticket ##{ticket.id} creado. El equipo de soporte contactará al usuario pronto."
        }
      rescue ActiveRecord::RecordInvalid => e
        { ok: false, error: "No se pudo crear el ticket: #{e.record.errors.full_messages.join(', ')}" }
      rescue => e
        Rails.logger.error("[Emily] CreateTicket tool error: #{e.class}: #{e.message}")
        { ok: false, error: "Error inesperado al crear el ticket." }
      end
    end
  end
end
