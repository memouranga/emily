module Emily
  module ApplicationHelper
    def emily_chat_widget
      render partial: "emily/shared/chat_widget"
    end

    # Returns true when the current request has no authenticated user
    # as far as Emily can tell (host app's current_user_method returns nil
    # or is unavailable).
    def emily_visitor?
      user_method = Emily.configuration&.current_user_method || :current_user
      !(respond_to?(user_method) && send(user_method).present?)
    end
  end
end
