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

      def copy_stimulus_controller
        copy_file Emily::Engine.root.join("app/javascript/emily/controllers/emily_chat_controller.js"),
                  "app/javascript/controllers/emily_chat_controller.js"
      end

      def pin_actioncable
        return unless File.exist?("config/importmap.rb")

        importmap = File.read("config/importmap.rb")
        unless importmap.include?("@rails/actioncable")
          append_to_file "config/importmap.rb", "\npin \"@rails/actioncable\", to: \"actioncable.esm.js\"\n"
        end
      end

      def add_stylesheet_to_layout
        layout_path = "app/views/layouts/application.html.erb"
        return unless File.exist?(layout_path)

        layout = File.read(layout_path)
        return if layout.include?("emily/application")

        inject_into_file layout_path,
          after: /stylesheet_link_tag.*"application".*\n/ do
          "    <%= stylesheet_link_tag \"emily/application\", \"data-turbo-track\": \"reload\" %>\n"
        end
      end

      def add_chat_widget_to_layout
        layout_path = "app/views/layouts/application.html.erb"
        return unless File.exist?(layout_path)

        layout = File.read(layout_path)
        return if layout.include?("emily/shared/chat_widget")

        inject_into_file layout_path,
          before: "</body>" do
          "    <%= render \"emily/shared/chat_widget\" %>\n"
        end
      end

      def show_instructions
        say ""
        say "Emily installed successfully!", :green
        say ""
        say "Next steps:"
        say "  1. Edit config/initializers/emily.rb with your API key"
        say "  2. Run: rails db:migrate"
        say "  3. Start your server and try the chat widget!"
        say ""
      end
    end
  end
end
