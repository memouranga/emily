require "test_helper"

module Emily
  class KnowledgeArticleTest < ActiveSupport::TestCase
    test "creates article" do
      article = create_article
      assert article.persisted?
    end

    test "requires title" do
      assert_raises(ActiveRecord::RecordInvalid) do
        KnowledgeArticle.create!(content: "Some content")
      end
    end

    test "requires content" do
      assert_raises(ActiveRecord::RecordInvalid) do
        KnowledgeArticle.create!(title: "Some title")
      end
    end

    test "validates content_format" do
      assert_raises(ActiveRecord::RecordInvalid) do
        create_article(content_format: "invalid")
      end
    end

    test "published scope" do
      published = create_article(published: true)
      unpublished = create_article(published: false, title: "Draft")

      assert_includes KnowledgeArticle.published, published
      assert_not_includes KnowledgeArticle.published, unpublished
    end

    test "faqs scope returns public_faq articles ordered by position" do
      faq1 = create_article(public_faq: true, position: 2, title: "Second")
      faq2 = create_article(public_faq: true, position: 1, title: "First")
      non_faq = create_article(public_faq: false, title: "Not FAQ")

      faqs = KnowledgeArticle.faqs
      assert_includes faqs, faq1
      assert_includes faqs, faq2
      assert_not_includes faqs, non_faq
      assert_equal faq2, faqs.first
    end

    test "search finds by title" do
      article = create_article(title: "Swimming techniques")
      create_article(title: "Cooking recipes")

      results = KnowledgeArticle.search("swimming")
      assert_includes results, article
    end

    test "search finds by content" do
      article = create_article(content: "Improve your backstroke technique")

      results = KnowledgeArticle.search("backstroke")
      assert_includes results, article
    end

    test "plain_content strips HTML for html format" do
      article = create_article(content: "<h1>Title</h1><p>Hello <strong>world</strong></p>", content_format: "html")
      assert_equal "TitleHello world", article.plain_content
    end

    test "plain_content returns content as-is for markdown" do
      article = create_article(content: "## Hello\n**world**", content_format: "markdown")
      assert_equal "## Hello\n**world**", article.plain_content
    end

    test "plain_content returns content as-is for plain" do
      article = create_article(content: "Just text", content_format: "plain")
      assert_equal "Just text", article.plain_content
    end

    test "rendered_content converts markdown to html" do
      article = create_article(content: "**bold** text", content_format: "markdown")
      assert_includes article.rendered_content, "<strong>bold</strong>"
    end

    test "by_category scope" do
      swimming = create_article(category: "swimming", title: "Swim")
      running = create_article(category: "running", title: "Run")

      results = KnowledgeArticle.by_category("swimming")
      assert_includes results, swimming
      assert_not_includes results, running
    end
  end
end
