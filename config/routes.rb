Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  resources :circles, only: %i[new create destroy show] do
    resources :user_circles, only: %i[create]
    resources :circle_messages, only: %i[create]
    resources :events, only: %i[new create]
    resources :users, only: :index
    resources :circle_playlists, only: %i[create]
  end

  resources :events, only: %i[new create update show] do
    resources :user_events, only: %i[create]
    resources :event_messages, only: %i[create]
    resources :circle_events, only: %i[create]
    resources :event_playlists, only: %i[create]
    resources :payments, only: %i[new create]
  end


  get "profile", to: "users#profile"

  resources :dashboard, only: :show

end
