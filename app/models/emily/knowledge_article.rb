module Emily
  class KnowledgeArticle < ApplicationRecord
    validates :title, presence: true
    validates :content, presence: true
    validates :content_format, inclusion: { in: %w[plain markdown html json] }

    scope :published, -> { where(published: true) }
    scope :faqs, -> { published.where(public_faq: true).order(:position, :title) }
    scope :by_category, ->(cat) { where(category: cat) }

    # Simple keyword search — can be replaced with vector search for production RAG
    scope :search, ->(query) {
      where("title LIKE :q OR content LIKE :q", q: "%#{query}%")
    }

    # Returns clean text for RAG regardless of content format
    def plain_content
      case content_format
      when "html"
        ActionController::Base.helpers.strip_tags(content)
      when "json"
        extract_text_from_json(content)
      else # plain, markdown
        content
      end
    end

    # Renders content as HTML for display
    def rendered_content
      case content_format
      when "markdown"
        Emily::MarkdownRenderer.render(content)
      when "html"
        content.html_safe
      when "json"
        extract_text_from_json(content)
      else
        ActionController::Base.helpers.simple_format(content)
      end
    end

    private

    def extract_text_from_json(json_string)
      data = JSON.parse(json_string)
      extract_nodes(data)
    rescue JSON::ParserError
      json_string
    end

    def extract_nodes(node)
      return node["text"] || "" if node.is_a?(Hash) && node["text"]
      return "" unless node.is_a?(Hash) && node["children"]

      node["children"].map { |child| extract_nodes(child) }.join(" ").squish
    end
  end
end
