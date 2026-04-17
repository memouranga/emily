module Emily
  class Configuration
    attr_accessor :llm_provider,
                  :llm_model,
                  :api_key,
                  :bot_name,
                  :bot_greeting,
                  :sales_prompt,
                  :support_prompt,
                  :escalation_enabled,
                  :knowledge_base_path,
                  :knowledge_providers,
                  :layout,
                  :user_class,
                  :current_user_method,
                  :admin_authenticate,
                  :widget_position,
                  :theme,
                  :conversation_flow,
                  :bot_avatar_url,
                  :rate_limit,
                  :sound_enabled,
                  :anti_bot,
                  :hashcash_bits

    def initialize
      @llm_provider = :anthropic
      @llm_model = "claude-haiku-4-5"
      @api_key = nil
      @bot_name = "Emily"
      @bot_greeting = nil
      @sales_prompt = "You are a helpful sales assistant. Help visitors understand the product and qualify leads."
      @support_prompt = "You are a helpful support assistant. Help users resolve issues using the knowledge base."
      @escalation_enabled = true
      @knowledge_base_path = nil
      @knowledge_providers = []
      @layout = nil
      @user_class = "User"
      @current_user_method = :current_user
      @admin_authenticate = nil
      @widget_position = :bottom_right
      @theme = {}
      @conversation_flow = nil
      @bot_avatar_url = nil
      @rate_limit = { max_messages: 30, period: 60 }
      @sound_enabled = true
      @anti_bot = :none
      @hashcash_bits = 20
    end

    def hashcash_enabled?
      @anti_bot == :hashcash
    end
  end
end
