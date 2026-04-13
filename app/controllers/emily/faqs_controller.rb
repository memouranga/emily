module Emily
  class FaqsController < ApplicationController
    def index
      @faqs = KnowledgeArticle.faqs
      @categories = @faqs.pluck(:category).compact.uniq

      respond_to do |format|
        format.html
        format.json { render json: @faqs }
      end
    end
  end
end
