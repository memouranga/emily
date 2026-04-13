module Emily
  class ApplicationController < ActionController::Base
    layout :emily_layout

    private

    def emily_layout
      Emily.configuration&.layout || "emily/application"
    end
  end
end
