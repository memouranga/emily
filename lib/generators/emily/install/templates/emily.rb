Emily.configure do |config|
  # LLM provider (:anthropic, :openai, etc.)
  config.llm_provider = :anthropic

  # Model to use
  config.llm_model = "claude-sonnet-4-5-20250514"

  # API key (use Rails credentials or ENV)
  config.api_key = Rails.application.credentials.dig(:anthropic, :api_key) || ENV["ANTHROPIC_API_KEY"]

  # Bot display name
  config.bot_name = "Emily"

  # Greeting message for new conversations
  config.bot_greeting = "Hi! How can I help you today?"

  # System prompt for visitors (sales mode)
  config.sales_prompt = "You are a helpful sales assistant. Help visitors understand the product and qualify leads."

  # System prompt for authenticated users (support mode)
  config.support_prompt = "You are a helpful support assistant. Help users resolve issues using the knowledge base."

  # Create tickets when AI can't resolve
  config.escalation_enabled = true

  # External knowledge providers — connect your app's models to Emily's RAG.
  # Each provider is a lambda or object that responds to .search(query)
  # and returns an array of { title:, content:, source: } hashes.
  #
  # config.knowledge_providers = [
  #   -> (query) {
  #     Video.search(query).limit(3).map { |v|
  #       { title: v.title, content: v.transcript, source: v.youtube_url }
  #     }
  #   },
  #   -> (query) {
  #     Course.search(query).limit(3).map { |c|
  #       { title: c.name, content: c.description, source: nil }
  #     }
  #   }
  # ]
  config.knowledge_providers = []

  # User model class name — Emily uses this to identify authenticated users
  # Works with any auth system (Devise, custom, etc.) as long as current_user exists
  config.user_class = "User"

  # Method to get the current user from the controller (default: :current_user)
  # config.current_user_method = :current_user

  # Layout — nil uses Emily's default, set to "application" to use your app's layout
  # config.layout = "application"
end
