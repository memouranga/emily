Emily::Engine.routes.draw do
  # Chat
  resources :conversations, only: [ :create, :show ] do
    resources :messages, only: [ :create ]
  end

  # Tickets
  resources :tickets, only: [ :create, :index, :show, :update ]

  # Public FAQs page
  resources :faqs, only: [ :index ]

  # Admin
  namespace :admin do
    resources :knowledge_articles
    resource :analytics, only: [ :index ], controller: "analytics"
  end
end
