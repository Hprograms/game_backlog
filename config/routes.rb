Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  resources :games do
    collection do
      get :search # /games/search というURLが作られます
    end
  end
  resources :account_activations, only: [:edit]
  root to: "home#index"
end