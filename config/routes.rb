Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  resources :games
  resources :account_activations, only: [:edit]
  root to: "home#index"
end