require "test_helper"

module Emily
  class MarkdownRendererTest < ActiveSupport::TestCase
    test "renders headings" do
      assert_includes MarkdownRenderer.render("# Title"), "<h1>Title</h1>"
      assert_includes MarkdownRenderer.render("## Subtitle"), "<h2>Subtitle</h2>"
      assert_includes MarkdownRenderer.render("### Small"), "<h3>Small</h3>"
    end

    test "renders bold" do
      assert_includes MarkdownRenderer.render("**bold**"), "<strong>bold</strong>"
    end

    test "renders italic" do
      assert_includes MarkdownRenderer.render("*italic*"), "<em>italic</em>"
    end

    test "renders links" do
      result = MarkdownRenderer.render("[Click](https://example.com)")
      assert_includes result, 'href="https://example.com"'
      assert_includes result, "Click"
    end

    test "renders inline code" do
      result = MarkdownRenderer.render("Use `gem install`")
      assert_includes result, "<code>gem install</code>"
    end

    test "returns empty string for blank input" do
      assert_equal "", MarkdownRenderer.render("")
      assert_equal "", MarkdownRenderer.render(nil)
    end

    test "wraps plain text in paragraphs" do
      result = MarkdownRenderer.render("Hello world")
      assert_includes result, "<p>"
    end
  end
end
