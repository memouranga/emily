module Emily
  class ApplicationController < ActionController::Base
    layout :emily_layout

    # Widget endpoints are same-origin XHR from a Stimulus controller; visitor
    # abuse is covered by hashcash and rate limiting. Enforcing CSRF here
    # breaks the chat whenever the host session is invalidated (e.g., logout
    # regenerates the token but the open tab still holds the stale one),
    # which is an unacceptable UX cost for the limited CSRF threat surface.
    skip_forgery_protection

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
