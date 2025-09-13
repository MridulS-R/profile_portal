
# frozen_string_literal: true
Rails.application.routes.draw do
  begin
    require 'sidekiq/web'
    # Mount Sidekiq dashboard in development for convenience
    if Rails.env.development?
      mount Sidekiq::Web => '/sidekiq'
    end
  rescue LoadError
    # sidekiq not available; skip
  end

  root "profiles#home"

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  get "/u/:slug", to: "profiles#show", as: :public_profile
  get "/profile/edit", to: "profiles#edit", as: :edit_profile
  patch "/profile", to: "profiles#update", as: :profile
  post "/profile/sync_github", to: "profiles#sync_github", as: :sync_github

  get "/profile/connect_domain", to: "profiles#connect_domain", as: :connect_domain
  post "/profile/domains",        to: "profiles#create_domain",  as: :domains
  delete "/profile/domains/:id",  to: "profiles#destroy_domain", as: :domain

  get "/demos", to: "projects#index", as: :demos

  get "/up", to: proc { [200, { "Content-Type" => "text/plain" }, ["ok"]] }

  # GitHub Webhook endpoint
  post "/webhooks/github", to: "webhooks/github#receive"
end
