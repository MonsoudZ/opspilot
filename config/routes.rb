Rails.application.routes.draw do

  get "up" => "rails/health#show", as: :rails_health_check

  require 'sidekiq/web'
  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end
  
  devise_for :users
  
  devise_scope :user do
    root to: "devise/sessions#new"
  end
  
end