Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up", to: "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "static_pages#home"

  get "about", to: "static_pages#about"
  get "courses", to: "static_pages#courses"
  get "results", to: "static_pages#results"
  get "new_results", to: "events#show_latest"

  resource :session, only: [ :new, :create, :destroy ]

  resources :events, param: :number, only: [ :index, :show ]
end
