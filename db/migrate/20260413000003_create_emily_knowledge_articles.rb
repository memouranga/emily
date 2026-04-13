class CreateEmilyKnowledgeArticles < ActiveRecord::Migration[7.1]
  def change
    create_table :emily_knowledge_articles do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :content_format, default: "markdown" # plain, markdown, html, json
      t.string :category
      t.string :tags, array: true, default: []
      t.string :source_url          # YouTube link, doc URL, etc.
      t.string :source_type         # markdown, youtube_transcript, manual
      t.boolean :published, default: true
      t.boolean :public_faq, default: false  # visible on public FAQs page
      t.integer :position, default: 0        # ordering for FAQs
      t.timestamps
    end

    add_index :emily_knowledge_articles, :category
    add_index :emily_knowledge_articles, :published
    add_index :emily_knowledge_articles, :public_faq
  end
end
