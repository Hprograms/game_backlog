Rails.application.routes.draw do
  resources :games do
    collection do
      get :search # /games/search というURLが作られます
    end
    member do
      post :timer_update
    end
  end
  resources :trophies, only: [ :index ]
  resources :activities, only: [ :index ]
  resource :profile, only: [ :edit, :update ]
  root to: "home#index"
end
