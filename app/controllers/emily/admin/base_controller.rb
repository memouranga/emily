module Emily
  module Admin
    class BaseController < Emily::ApplicationController
      before_action :authenticate_emily_admin!

      private

      def authenticate_emily_admin!
        auth = Emily.configuration&.admin_authenticate
        return unless auth

        instance_exec(&auth)
      end
    end
  end
end
