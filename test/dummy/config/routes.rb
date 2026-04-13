Rails.application.routes.draw do
  mount Emily::Engine, at: "/emily"
end
