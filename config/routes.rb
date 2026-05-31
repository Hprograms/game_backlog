Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  resources :games do
    member do
      post :destroy_image
    end
  end
  resources :account_activations, only: [:edit]
  root to: "home#index"
end