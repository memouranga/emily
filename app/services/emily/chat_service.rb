module Emily
  class ChatService
    def initialize(conversation)
      @conversation = conversation
      @config = Emily.configuration || Configuration.new
    end

    def respond
      last_message = @conversation.messages.where(role: :user).last
      return unless last_message

      context = retrieve_knowledge(last_message.content)
      messages = build_messages(context)
      response = call_llm(messages)

      @conversation.messages.create!(role: :assistant, content: response)
    end

    private

    def retrieve_knowledge(query)
      results = []

      # 1. Emily's own knowledge articles
      articles = KnowledgeArticle.published.search(query).limit(3)
      articles.each do |a|
        results << { title: a.title, content: a.plain_content, source: a.source_url }
      end

      # 2. External knowledge providers (host app models)
      @config.knowledge_providers.each do |provider|
        entries = case provider
                  when Proc
                    provider.call(query)
                  when Class
                    provider.new.search(query)
                  else
                    provider.search(query)
                  end

        results.concat(Array(entries).first(3))
      rescue => e
        Rails.logger.error("[Emily] Knowledge provider error: #{e.message}")
      end

      return "" if results.empty?

      results.first(5).map { |r|
        text = "## #{r[:title]}\n#{r[:content]}"
        text += "\nSource: #{r[:source]}" if r[:source].present?
        text
      }.join("\n\n")
    end

    def build_messages(context)
      system_prompt = if @conversation.support?
        @config.support_prompt
      else
        @config.sales_prompt
      end

      user_context = resolve_user_context
      system_prompt += "\n\nConversation context:\n#{user_context}" if user_context.present?
      system_prompt += "\n\nRelevant knowledge base articles:\n#{context}" if context.present?

      messages = [ { role: "system", content: system_prompt } ]

      @conversation.messages.order(:created_at).each do |msg|
        messages << { role: msg.role, content: msg.content }
      end

      messages
    end

    def resolve_user_context
      builder = @config.user_context_builder
      return nil unless builder.respond_to?(:call)

      Array(builder.call(@conversation)).compact.reject(&:blank?).join("\n")
    rescue => e
      Rails.logger.error("[Emily] user_context_builder error: #{e.class}: #{e.message}")
      nil
    end

    def call_llm(messages)
      chat = ::RubyLLM.chat(model: @config.llm_model)

      system_msg = messages.shift
      chat.with_instructions(system_msg[:content])

      # Support conversations can escalate to a human via a ticket. The LLM
      # decides when to call the tool based on the support_prompt guidance.
      chat.with_tool(Emily::Tools::CreateTicket.new(@conversation)) if @conversation.support?

      # Preload all prior turns as history (no LLM call), then send only the
      # last user message with `ask` to trigger a single completion. RubyLLM
      # will loop internally to resolve tool calls.
      last_user = nil
      messages.each { |m| last_user = m if m[:role] == "user" }
      messages.each do |msg|
        next if msg.equal?(last_user)
        chat.add_message(role: msg[:role].to_sym, content: msg[:content])
      end

      response = last_user ? chat.ask(last_user[:content]) : nil
      response&.content.presence || "I'm sorry, I couldn't process that. Could you try again?"
    rescue => e
      Rails.logger.error("[Emily] LLM error: #{e.class}: #{e.message}")
      "I'm having trouble right now. Would you like me to create a support ticket?"
    end
  end
end
