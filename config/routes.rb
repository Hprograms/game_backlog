Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" },
             skip: [ :sessions, :registrations ]
  get "/users/sign_in", to: "clerk_sessions#sign_in", as: :new_user_session
  get "/users/sign_up", to: "clerk_sessions#sign_up", as: :new_user_registration
  resources :games do
    collection do
      get :search # /games/search というURLが作られます
    end
  end
  resources :account_activations, only: [ :edit ]
  root to: "home#index"
end
