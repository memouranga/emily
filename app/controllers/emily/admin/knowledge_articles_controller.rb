module Emily
  module Admin
    class KnowledgeArticlesController < BaseController
      def index
        @articles = KnowledgeArticle.order(:category, :position, :title)
        render json: @articles
      end

      def show
        @article = KnowledgeArticle.find(params[:id])
        render json: @article
      end

      def create
        @article = KnowledgeArticle.new(article_params)
        if @article.save
          render json: @article, status: :created
        else
          render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        @article = KnowledgeArticle.find(params[:id])
        if @article.update(article_params)
          render json: @article
        else
          render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @article = KnowledgeArticle.find(params[:id])
        @article.destroy
        head :no_content
      end

      private

      def article_params
        params.require(:knowledge_article).permit(
          :title, :content, :category, :source_url, :source_type,
          :published, :public_faq, :position, tags: []
        )
      end
    end
  end
end
