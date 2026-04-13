Emily.configure do |config|
  config.bot_name = "TestBot"
  config.bot_greeting = "Hello from tests!"
  config.llm_provider = :anthropic
  config.llm_model = "claude-sonnet-4-5-20250514"
end
