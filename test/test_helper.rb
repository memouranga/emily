# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"
require "minitest/autorun"

# Create tables in memory
ActiveRecord::Schema.define do
  create_table :emily_conversations, force: true do |t|
    t.string :session_id, null: false
    t.string :user_type
    t.bigint :user_id
    t.string :status, default: "open", null: false
    t.string :phase, default: "sales", null: false
    t.text :metadata
    t.timestamps
  end

  create_table :emily_messages, force: true do |t|
    t.bigint :conversation_id, null: false
    t.string :role, null: false
    t.text :content, null: false
    t.timestamps
  end

  create_table :emily_tickets, force: true do |t|
    t.bigint :conversation_id, null: false
    t.string :subject, null: false
    t.text :summary
    t.string :status, default: "open", null: false
    t.string :priority, default: "normal"
    t.timestamps
  end

  create_table :emily_ratings, force: true do |t|
    t.bigint :message_id, null: false
    t.bigint :conversation_id, null: false
    t.integer :score, null: false
    t.text :feedback
    t.timestamps
  end

  create_table :emily_knowledge_articles, force: true do |t|
    t.string :title, null: false
    t.text :content, null: false
    t.string :content_format, default: "markdown"
    t.string :category
    t.string :source_url
    t.string :source_type
    t.boolean :published, default: true
    t.boolean :public_faq, default: false
    t.integer :position, default: 0
    t.timestamps
  end

  create_table :active_hashcash_stamps, force: true do |t|
    t.string :version, null: false
    t.integer :bits, null: false
    t.date :date, null: false
    t.string :resource, null: false
    t.string :ext, null: false
    t.string :rand, null: false
    t.string :counter, null: false
    t.string :request_path
    t.string :ip_address
    t.json :context
    t.timestamps
  end
end

module ActiveSupport
  class TestCase
    def create_conversation(attrs = {})
      Emily::Conversation.create!({
        session_id: SecureRandom.hex(16),
        phase: :sales,
        status: :open
      }.merge(attrs))
    end

    def create_message(conversation, attrs = {})
      conversation.messages.create!({
        role: :user,
        content: "Hello"
      }.merge(attrs))
    end

    def create_article(attrs = {})
      Emily::KnowledgeArticle.create!({
        title: "Test Article",
        content: "Test content for the article.",
        content_format: "plain",
        published: true
      }.merge(attrs))
    end
  end
end
