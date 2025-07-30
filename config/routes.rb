Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  require 'sidekiq/web'
  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  # Invite-only Devise (no public signup)
  devise_for :users, skip: [:registrations]
  devise_scope :user do
    get 'users/sign_up', to: redirect('/users/sign_in')
    post 'users', to: redirect('/users/sign_in')
  end

  # Single root route that handles both authenticated and unauthenticated users
  root to: 'dashboard#index'
end