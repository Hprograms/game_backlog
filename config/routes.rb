Rails.application.routes.draw do
  resources :games do
    collection do
      get :search # /games/search というURLが作られます
    end
  end
  resources :trophies, only: [ :index ]
  resources :activities, only: [ :index ]
  resource :profile, only: [ :edit, :update ]
  root to: "home#index"
end
