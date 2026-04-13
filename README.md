# Emily

AI-powered sales & support chat engine for Rails. Drop-in chat widget with knowledge base, ticket escalation, and analytics — powered by LLMs.

Emily replaces tools like Intercom and Zendesk with a single Rails engine. One widget handles both **sales** (visitors) and **support** (authenticated users), switching automatically based on context.

## Features

- **Chat widget** — Floating chat with real-time messaging via Action Cable
- **Dual mode** — Sales for visitors, support for logged-in users (automatic)
- **Knowledge base** — Built-in articles + connect your app's own models (RAG)
- **Conversation flow** — Guided decision trees before AI takes over
- **Ticket escalation** — When AI can't resolve, creates a support ticket
- **Public FAQs page** — Publish knowledge articles as a FAQ page
- **Analytics dashboard** — Conversations, resolution rate, tickets, trends
- **Ratings** — Thumbs up/down on AI responses
- **i18n** — English and Spanish included, fully translatable
- **Theming** — CSS variables + automatic dark mode
- **Events** — ActiveSupport::Notifications for hooks (email, Slack, etc.)
- **Rate limiting** — Built-in spam protection
- **Admin panel** — Knowledge base CRUD with configurable auth

## Installation

Add to your Gemfile:

```ruby
gem "emily"
```

Then run:

```bash
bundle install
rails generate emily:install
rails db:migrate
```

Add the chat widget to your layout:

```erb
<%= emily_chat_widget %>
```

That's it. Three commands and a tag.

## Configuration

The installer creates `config/initializers/emily.rb`:

```ruby
Emily.configure do |config|
  # LLM (via RubyLLM — supports Anthropic, OpenAI, etc.)
  config.llm_provider = :anthropic
  config.llm_model = "claude-sonnet-4-5-20250514"
  config.api_key = ENV["ANTHROPIC_API_KEY"]

  # Bot
  config.bot_name = "Emily"
  config.bot_greeting = "Hi! How can I help you today?"

  # Prompts
  config.sales_prompt = "You are a helpful sales assistant..."
  config.support_prompt = "You are a helpful support assistant..."

  # User detection (works with Devise or any auth)
  config.user_class = "User"
  config.current_user_method = :current_user

  # Admin auth
  config.admin_authenticate = -> {
    redirect_to main_app.root_path unless current_user&.admin?
  }

  # UI
  config.layout = "application"          # Use your app's layout
  config.widget_position = :bottom_right # or :bottom_left
end
```

## Knowledge Base

### Built-in articles

Create articles through the admin panel at `/emily/admin/knowledge_articles` or programmatically:

```ruby
Emily::KnowledgeArticle.create!(
  title: "How to reset your password",
  content: "Go to Settings > Security > Reset Password...",
  content_format: "markdown",  # plain, markdown, html, json
  category: "Account",
  published: true,
  public_faq: true  # Show on /emily/faqs
)
```

### Connect your app's models

No need to duplicate data. Tell Emily where to search:

```ruby
Emily.configure do |config|
  config.knowledge_providers = [
    -> (query) {
      Video.search(query).limit(3).map { |v|
        { title: v.title, content: v.transcript, source: v.youtube_url }
      }
    },
    -> (query) {
      Course.search(query).limit(3).map { |c|
        { title: c.name, content: c.description, source: nil }
      }
    }
  ]
end
```

Emily searches both its own articles and your models, picks the best results, and passes them to the AI as context (RAG).

## Conversation Flow

Guide users through a decision tree before the AI takes over:

```ruby
Emily.configure do |config|
  config.conversation_flow = {
    greeting: "How can I help you?",
    options: [
      {
        label: "Learn about our services",
        next: {
          greeting: "What type of project?",
          options: [
            { label: "Web application", tag: "lead:web" },
            { label: "Mobile app", tag: "lead:mobile" }
          ]
        }
      },
      { label: "Technical support", tag: "support" },
      { label: "Talk to someone", tag: "escalate" }
    ]
  }
end
```

## Events

Emily publishes events via `ActiveSupport::Notifications`. Subscribe to what you need:

```ruby
# Send email when a ticket is created
ActiveSupport::Notifications.subscribe("emily.ticket_created") do |event|
  AdminMailer.new_ticket(event.payload[:ticket]).deliver_later
end

# Notify Slack on escalation
ActiveSupport::Notifications.subscribe("emily.escalation") do |event|
  SlackNotifier.ping("Escalated: #{event.payload[:ticket].subject}")
end
```

Available events:
- `emily.conversation_started`
- `emily.message_received`
- `emily.message_sent`
- `emily.ticket_created`
- `emily.ticket_updated`
- `emily.escalation`
- `emily.message_rated`

## Theming

Emily uses CSS variables. Override them to match your brand:

```css
:root {
  --emily-primary: #e11d48;
  --emily-primary-hover: #be123c;
  --emily-bg: #ffffff;
  --emily-text: #1a1a1a;
  --emily-border: #e8e8e8;
  --emily-surface: #f0f0f0;
  --emily-radius: 0.5rem;
  --emily-font: "Inter", sans-serif;
}
```

Dark mode is automatic via `prefers-color-scheme`.

## Customizing Views

Copy Emily's views to your app for full customization:

```bash
rails generate emily:views
```

This copies all templates to `app/views/emily/` where you can edit them freely.

## Routes

Mounted at `/emily` by default:

| Route | Description |
|---|---|
| `POST /emily/conversations` | Start a conversation |
| `GET /emily/conversations/:id` | Get conversation + messages |
| `POST /emily/conversations/:id/messages` | Send a message |
| `POST /emily/conversations/:id/messages/:id/rating` | Rate a message |
| `GET /emily/faqs` | Public FAQs page |
| `GET /emily/admin/knowledge_articles` | Admin: manage articles |
| `GET /emily/admin/analytics` | Admin: analytics dashboard |

## Tech Stack

- **Rails Engine** (mountable, isolated namespace)
- **RubyLLM** — LLM-agnostic (Anthropic, OpenAI, etc.)
- **Action Cable** — Real-time WebSocket chat
- **Active Job** — Async AI responses
- **Stimulus** — Chat widget interactivity
- **Minitest** — 59 tests, 123 assertions

## Requirements

- Ruby >= 3.1
- Rails >= 7.1
- An LLM API key (Anthropic, OpenAI, etc.)

## Development

```bash
git clone https://github.com/memouranga/emily.git
cd emily
bundle install
bundle exec rake test
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Create a Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

Built by [9T Solutions](https://9t.solutions)
