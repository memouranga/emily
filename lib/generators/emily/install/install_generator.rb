module Emily
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "emily.rb", "config/initializers/emily.rb"
      end

      def mount_engine
        route 'mount Emily::Engine, at: "/emily"'
      end

      def copy_migrations
        rake "emily:install:migrations"
      end

      def show_instructions
        say ""
        say "Emily installed successfully!", :green
        say ""
        say "Next steps:"
        say "  1. Edit config/initializers/emily.rb with your API key"
        say "  2. Run: rails db:migrate"
        say '  3. Add the chat widget to your layout: <%= emily_chat_widget %>'
        say ""
      end
    end
  end
end
