module Emily
  class ApplicationController < ActionController::Base
    layout :emily_layout

    private

    def emily_layout
      Emily.configuration&.layout || "emily/application"
    end

    def current_emily_user
      method_name = Emily.configuration&.current_user_method || :current_user
      return nil unless respond_to?(method_name, true)

      send(method_name)
    end
  end
end
