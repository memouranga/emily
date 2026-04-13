module Emily
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      desc "Copy Emily views to your application for customization"

      def copy_views
        directory Emily::Engine.root.join("app/views/emily"), "app/views/emily"
        say "Emily views copied to app/views/emily/", :green
        say "You can now customize the templates to match your app's design."
      end
    end
  end
end
