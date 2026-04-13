Emily.configure do |config|
  # === LLM ===
  # Provider and model (via RubyLLM — supports Anthropic, OpenAI, etc.)
  config.llm_provider = :anthropic
  config.llm_model = "claude-sonnet-4-5-20250514"
  config.api_key = Rails.application.credentials.dig(:anthropic, :api_key) || ENV["ANTHROPIC_API_KEY"]

  # === Bot ===
  config.bot_name = "Emily"
  # config.bot_avatar_url = "/path/to/avatar.png"
  # config.bot_greeting = "Hi! How can I help you?"  # nil = use i18n default

  # === Prompts ===
  config.sales_prompt = "You are a helpful sales assistant. Help visitors understand the product and qualify leads."
  config.support_prompt = "You are a helpful support assistant. Help users resolve issues using the knowledge base."

  # === User detection ===
  # Works with any auth system (Devise, custom, Auth0, etc.)
  config.user_class = "User"
  # config.current_user_method = :current_user

  # === Admin auth ===
  # Protect /emily/admin routes. Runs in controller context.
  # config.admin_authenticate = -> { redirect_to main_app.root_path unless current_user&.admin? }

  # === Tickets ===
  config.escalation_enabled = true

  # === Knowledge providers ===
  # Connect your app's models to Emily's RAG (in addition to Emily's own KnowledgeArticles).
  # Each provider is a lambda that receives a query and returns [{ title:, content:, source: }]
  #
  # config.knowledge_providers = [
  #   -> (query) {
  #     Video.search(query).limit(3).map { |v|
  #       { title: v.title, content: v.transcript, source: v.youtube_url }
  #     }
  #   }
  # ]
  config.knowledge_providers = []

  # === Conversation flow ===
  # Decision tree for guided conversations. User picks options before AI takes over.
  #
  # config.conversation_flow = {
  #   greeting: "How can I help you?",
  #   options: [
  #     {
  #       label: "Learn about services",
  #       next: {
  #         greeting: "What type of project?",
  #         options: [
  #           { label: "Web app", tag: "lead:web" },
  #           { label: "Mobile", tag: "lead:mobile" }
  #         ]
  #       }
  #     },
  #     { label: "Technical support", tag: "support" },
  #     { label: "Talk to someone", tag: "escalate" }
  #   ]
  # }

  # === UI ===
  # config.layout = "application"        # Use your app's layout instead of Emily's
  # config.widget_position = :bottom_right  # :bottom_right or :bottom_left
  # config.sound_enabled = true

  # === Theme ===
  # Override CSS variables to match your brand. Example:
  # config.theme = { primary: "#e11d48", primary_hover: "#be123c" }

  # === Rate limiting ===
  config.rate_limit = { max_messages: 30, period: 60 }
end
