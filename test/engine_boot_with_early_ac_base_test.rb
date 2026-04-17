require "test_helper"

# Regression test: ensures Emily's helper registration works in downstream apps
# where ActionController::Base is loaded before the engine's initializers run.
#
# Historical context: earlier versions used
#   initializer "emily.helpers" { ActiveSupport.on_load(:action_controller_base) { helper ... } }
# which fired synchronously in apps that had AC::Base loaded early (Devise/Doorkeeper/etc),
# BEFORE Zeitwerk had wired the engine's autoload paths. That caused
# `uninitialized constant Emily::ApplicationHelper` at boot.
#
# Current fix: `config.to_prepare` block runs AFTER all initializers and after
# autoload paths are ready, so constants are resolvable.
class EngineBootWithEarlyAcBaseTest < ActiveSupport::TestCase
  test "ActionController::Base is already loaded (downstream-app scenario)" do
    # In the dummy app AC::Base is loaded during boot, mirroring the real
    # production scenario where this bug surfaced.
    assert defined?(ActionController::Base), "ActionController::Base should be loaded"
  end

  test "Emily::ApplicationHelper is resolvable after boot" do
    # The core of the original bug: this constant could not be resolved
    # during the initializer phase. By the time tests run, to_prepare has
    # fired and the helper must be resolvable via autoload.
    assert_nothing_raised do
      Emily::ApplicationHelper
    end
    assert defined?(Emily::ApplicationHelper), "Emily::ApplicationHelper should be loaded"
  end

  test "Emily::Engine.helpers resolves without raising" do
    # Engine#helpers internally calls constantize on helper paths. This is
    # exactly the call site that used to fail during initializer time.
    # After to_prepare, it must succeed.
    assert_nothing_raised do
      Emily::Engine.helpers
    end
  end

  test "Emily helpers are registered on ActionController::Base" do
    # to_prepare should have wired Emily's helpers into AC::Base by the time
    # the app is ready. Verify the helper module is actually in the ancestry.
    helper_modules = ActionController::Base._helpers.ancestors
    assert helper_modules.any? { |m| m.name.to_s.start_with?("Emily") },
      "Expected an Emily helper module in AC::Base._helpers ancestry, " \
      "got: #{helper_modules.map(&:name).compact.grep(/Emily|Helper/).inspect}"
  end
end
