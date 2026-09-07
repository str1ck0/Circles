Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :circles, only: %i[new create destroy show] do
    resources :user_circles, only: %i[create]
    resources :circle_messages, only: %i[create]
    resources :events, only: %i[new create]
    resources :users, only: :index
    resources :circle_playlists, only: %i[create]
    resources :invitations, only: %i[create]
  end

  resources :invitations, only: [] do
    member do
      post :accept
      post :decline
    end
  end

  get  "invites/:token", to: "invite_links#show",   as: :invite_link
  post "invites/:token", to: "invite_links#accept", as: :accept_invite_link

  resources :events, only: %i[new create update show] do
    resources :user_events, only: %i[create]
    resources :event_messages, only: %i[create]
    resources :circle_events, only: %i[create]
    resources :event_playlists, only: %i[create]
    resources :payments, only: %i[new create]
  end

  resources :notifications, only: %i[index show]
  resources :users, only: %i[index show]
  resources :dashboard, only: :show
end
