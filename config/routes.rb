Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  resources :circles, only: %i[new create destroy show] do
    resources :user_circles, only: %i[create update]
    resources :circle_events, only: %i[create destroy]
    resources :circle_messages, only: %i[create]
    resources :events, only: %i[new create]
    resources :users, only: :index
    resources :circle_playlists, only: %i[new create destroy]
  end

  resources :events, only: %i[new create destroy edit update show] do
    resources :user_events, only: %i[create update destroy]
    resources :event_messages, only: %i[create]
    resources :circle_events, only: %i[create]
    resources :event_playlists, only: %i[new create destroy]
    resources :payments, only: %i[new create]
  end


  get "profile", to: "users#profile"

  resources :dashboard, only: :show

end
