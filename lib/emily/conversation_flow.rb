module Emily
  # Decision tree for guided conversations.
  #
  # Configure in initializer:
  #
  #   config.conversation_flow = {
  #     greeting: "How can I help you?",
  #     options: [
  #       {
  #         label: "I want to learn about your services",
  #         next: {
  #           greeting: "What type of project are you looking for?",
  #           options: [
  #             { label: "Web application", tag: "lead:web" },
  #             { label: "Mobile app", tag: "lead:mobile" },
  #             { label: "Consulting", tag: "lead:consulting" }
  #           ]
  #         }
  #       },
  #       {
  #         label: "I need technical support",
  #         next: {
  #           greeting: "What product do you need help with?",
  #           options: [
  #             { label: "CloudHealth", tag: "support:cloudhealth" },
  #             { label: "SkillsNT", tag: "support:skillsnt" }
  #           ]
  #         }
  #       },
  #       { label: "I want to talk to someone", tag: "escalate" }
  #     ]
  #   }
  #
  # When user picks an option:
  # - If it has `next:` → show next level of options
  # - If it has `tag:` → save tag to conversation metadata, switch to AI chat
  # - If tag is "escalate" → create ticket immediately
  #
  class ConversationFlow
    attr_reader :tree

    def initialize(tree)
      @tree = tree.deep_symbolize_keys
    end

    def root
      @tree
    end

    def navigate(path)
      node = @tree
      path.each do |index|
        option = node[:options]&.at(index.to_i)
        return nil unless option
        node = option[:next] || option
      end
      node
    end

    def leaf?(node)
      node[:tag].present? && node[:next].nil?
    end
  end
end
