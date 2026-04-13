module Emily
  class MarkdownRenderer
    # Lightweight markdown to HTML — no extra gem dependency.
    # Covers the basics: headings, bold, italic, links, code, lists, paragraphs.
    # For full markdown support, the host app can override with redcarpet/commonmarker.
    def self.render(text)
      return "" if text.blank?

      html = text.dup

      # Code blocks (```...```)
      html.gsub!(/```(\w*)\n(.*?)```/m) { "<pre><code>#{CGI.escapeHTML(Regexp.last_match(2).strip)}</code></pre>" }

      # Inline code (`...`)
      html.gsub!(/`([^`]+)`/) { "<code>#{CGI.escapeHTML(Regexp.last_match(1))}</code>" }

      # Headings
      html.gsub!(/^### (.+)$/, '<h3>\1</h3>')
      html.gsub!(/^## (.+)$/, '<h2>\1</h2>')
      html.gsub!(/^# (.+)$/, '<h1>\1</h1>')

      # Bold and italic
      html.gsub!(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
      html.gsub!(/\*(.+?)\*/, '<em>\1</em>')

      # Links
      html.gsub!(/\[([^\]]+)\]\(([^)]+)\)/, '<a href="\2" target="_blank" rel="noopener">\1</a>')

      # Unordered lists
      html.gsub!(/^- (.+)$/, '<li>\1</li>')
      html.gsub!(%r{(<li>.*</li>\n?)+}m) { "<ul>#{Regexp.last_match(0)}</ul>" }

      # Paragraphs (lines not already wrapped in HTML tags)
      lines = html.split("\n\n")
      lines.map! do |line|
        if line.match?(/\A\s*<(h[1-6]|ul|ol|pre|li|div|table)/)
          line
        else
          "<p>#{line.strip}</p>"
        end
      end

      lines.join("\n").html_safe
    end
  end
end
