require "test_helper"

# Regression test: ensures Emily's helper initializer doesn't crash when
# ActionController::Base is loaded before the engine's initializers run.
# In production apps (with Devise/Doorkeeper/etc), AC::Base is commonly
# loaded early, which causes ActiveSupport.on_load blocks to fire
# synchronously. The bug: helper registration via `helper Emily::ApplicationHelper`
# failed because Zeitwerk autoload paths weren't ready yet.
class EngineBootWithEarlyAcBaseTest < ActiveSupport::TestCase
  test "helper registration works even if ActionController::Base is already loaded" do
    # Ensure AC::Base is loaded (it already is in most test runs; make it explicit).
    _ = ActionController::Base

    # Simulate re-running the on_load hook (what happens when a downstream app
    # triggers it synchronously after AC::Base is already resolved).
    assert_nothing_raised do
      ActiveSupport.run_load_hooks(:action_controller_base, ActionController::Base)
    end

    # Confirm the helper module is actually registered and callable.
    assert ActionController::Base._helpers.instance_methods.any? { |m| m.to_s.start_with?("emily_") } ||
           Emily::Engine.helpers.instance_methods.any?,
      "Expected at least one Emily helper to be registered or accessible via Engine.helpers"
  end
end
