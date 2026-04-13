module Emily
  class KnowledgeArticle < ApplicationRecord
    validates :title, presence: true
    validates :content, presence: true

    scope :published, -> { where(published: true) }
    scope :faqs, -> { published.where(public_faq: true).order(:position, :title) }
    scope :by_category, ->(cat) { where(category: cat) }

    # Simple keyword search — can be replaced with vector search for production RAG
    scope :search, ->(query) {
      where("title LIKE :q OR content LIKE :q", q: "%#{query}%")
    }
  end
end
