Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up", to: "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "static_pages#home"

  get "about", to: "static_pages#about"
  get "results", to: "events#show_latest"

  get "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  delete "sign_out", to: "sessions#destroy"

  get "forgot_password", to: "passwords#new"
  post "forgot_password", to: "passwords#create"
  get "reset_password/:token", to: "passwords#edit", as: :edit_password
  patch "reset_password/:token", to: "passwords#update"
  put "reset_password/:token", to: "passwords#update"

  get "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"

  get "confirm_email/:token", to: "confirmations#show", as: :confirm_email
  post "confirm_email/resend", to: "confirmations#create", as: :resend_confirmation

  resources :events, param: :number, only: [ :index, :show ]
  resource :user, only: [ :show, :edit, :update ], path: "profile"
  get "profile/results", to: "users#my_results", as: :my_results
  resources :users, only: [ :index ], path: "participants", param: :barcode
  get "participants/:barcode/results", to: "users#results", as: :user_results

  get "courses", to: "static_pages#courses"
  get "courses_new", to: "courses#index"
  get "courses/:slug", to: "courses#show", as: :course

  constraints AdminUser do
    scope :admin, as: :admin do
      resources :events, param: :number, only: [ :new, :create, :edit, :update, :destroy ] do
        member do
          get :edit_results
        end
      end
      resources :locations, controller: "admin/locations"
    end
    scope :admin do
      post :user_import, to: "admin/users#import"
      get :dashboard, to: "static_pages#admin_dashboard"
      get "user_import/template", to: "admin/users#download_template"
      resources :finish_positions, only: [ :create, :destroy ] do
        member do
          get :new_user
          post :create_user
        end
      end
      resources :finish_times, only: [ :create, :destroy ]
      resources :results, only: [ :new, :create, :edit, :update, :destroy ]
      resources :volunteers, only: [ :new, :create, :edit, :update, :destroy ]
      post :finish_time_import, to: "finish_times#import"
      delete :finish_times_destroy_all, to: "finish_times#destroy_all"
      post :result_link, to: "results#link"
      delete :results_destroy_all, to: "results#destroy_all"

      resources :users, controller: "admin/users", except: [ :new, :create, :destroy ], as: :admin_users do
        member do
          patch :confirm
          post :assign_role
          delete :remove_role
        end
      end
    end
  end

  constraints OrganiserUser do
    scope :admin do
      get :dashboard, to: "static_pages#admin_dashboard"
      resources :finish_positions, only: [ :create, :destroy ]
      resources :finish_times, only: [ :destroy ]
      post :finish_time_import, to: "finish_times#import"
    end
  end
end
