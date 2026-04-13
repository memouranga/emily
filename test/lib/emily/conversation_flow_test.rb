require "test_helper"

module Emily
  class ConversationFlowTest < ActiveSupport::TestCase
    setup do
      @tree = {
        greeting: "How can I help?",
        options: [
          {
            label: "Sales",
            next: {
              greeting: "What project type?",
              options: [
                { label: "Web app", tag: "lead:web" },
                { label: "Mobile", tag: "lead:mobile" }
              ]
            }
          },
          { label: "Support", tag: "support" },
          { label: "Talk to someone", tag: "escalate" }
        ]
      }
      @flow = ConversationFlow.new(@tree)
    end

    test "root returns the full tree" do
      assert_equal "How can I help?", @flow.root[:greeting]
      assert_equal 3, @flow.root[:options].size
    end

    test "navigate to first level option" do
      node = @flow.navigate([0])
      assert_equal "What project type?", node[:greeting]
      assert_equal 2, node[:options].size
    end

    test "navigate to leaf node" do
      node = @flow.navigate([0, 0])
      assert_equal "lead:web", node[:tag]
    end

    test "leaf? returns true for node with tag and no next" do
      node = { label: "Web app", tag: "lead:web" }
      assert @flow.leaf?(node)
    end

    test "leaf? returns false for node with next" do
      node = @flow.root[:options][0]
      assert_not @flow.leaf?(node)
    end

    test "navigate returns nil for invalid path" do
      assert_nil @flow.navigate([99])
    end
  end
end
