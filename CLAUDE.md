# Emily — AI Sales & Support Chat Engine for Rails

Open source Rails engine by **9T Solutions** that adds an AI-powered chat widget to any Rails app. Handles both sales (lead qualification) and support (knowledge base + ticket escalation) in a single interface.

## Tech Stack

- **Rails Engine** (mountable, isolated namespace)
- **LLM**: RubyLLM gem (supports Anthropic, OpenAI, etc.)
- **Real-time**: Action Cable (WebSocket)
- **Queue**: Active Job (Solid Queue compatible)
- **RAG**: Knowledge base search over articles/transcripts

## Architecture

```
User ← Action Cable → ConversationChannel
                          ↓
MessagesController → ChatJob (async)
                          ↓
                    ChatService
                    ├── retrieve_knowledge (RAG)
                    ├── build_messages (context + history)
                    └── call_llm (RubyLLM)
                          ↓
                    Message (broadcast via Cable)
```

## Models

- **Conversation** — session with visitor or customer (phase: sales/support)
- **Message** — individual chat message (role: user/assistant)
- **KnowledgeArticle** — indexed content for RAG (markdown, YouTube transcripts, etc.)
- **Ticket** — escalation when AI can't resolve

## Key Files

- `lib/emily/configuration.rb` — all config options
- `app/services/emily/chat_service.rb` — core LLM + RAG logic
- `app/channels/emily/conversation_channel.rb` — WebSocket streaming
- `app/jobs/emily/chat_job.rb` — async AI response
- `lib/generators/emily/install/` — install generator

## Commands

```bash
rails generate emily:install   # Install initializer + mount + migrations
rails db:migrate               # Run Emily migrations
```

## Install in host app

```ruby
# Gemfile
gem "emily"

# Then:
# bundle install
# rails generate emily:install
# rails db:migrate
```

## Routes (mounted at /emily by default)

```
POST   /emily/conversations          → create conversation
GET    /emily/conversations/:id      → show conversation + messages
POST   /emily/conversations/:id/messages → send message (triggers AI response)
POST   /emily/tickets                → create ticket
GET    /emily/tickets                → list tickets
```
