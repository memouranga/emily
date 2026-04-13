module Emily
  class Configuration
    attr_accessor :llm_provider,        # :anthropic, :openai, etc.
                  :llm_model,           # "claude-sonnet-4-5-20250514", "gpt-4o", etc.
                  :api_key,             # LLM API key
                  :bot_name,            # Display name in chat widget ("Emily")
                  :bot_greeting,        # First message shown to users
                  :sales_prompt,        # System prompt for unauthenticated users (sales mode)
                  :support_prompt,      # System prompt for authenticated users (support mode)
                  :escalation_enabled,  # Create tickets when AI can't resolve
                  :knowledge_base_path, # Path to markdown knowledge base files
                  :knowledge_providers, # Array of external knowledge sources (lambdas/classes)
                  :layout               # Layout to use (nil = Emily's own, "application" = host app's)

    def initialize
      @llm_provider = :anthropic
      @llm_model = "claude-sonnet-4-5-20250514"
      @api_key = nil
      @bot_name = "Emily"
      @bot_greeting = "Hi! How can I help you today?"
      @sales_prompt = "You are a helpful sales assistant. Help visitors understand the product and qualify leads."
      @support_prompt = "You are a helpful support assistant. Help users resolve issues using the knowledge base."
      @escalation_enabled = true
      @knowledge_base_path = nil
      @knowledge_providers = []
      @layout = nil
    end
  end
end
