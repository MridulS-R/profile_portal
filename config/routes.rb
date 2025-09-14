
# frozen_string_literal: true
Rails.application.routes.draw do
  begin
    require 'sidekiq/web'
    # Mount Sidekiq dashboard in development for convenience
    if Rails.env.development?
      mount Sidekiq::Web => '/sidekiq'
    elsif Rails.env.production?
      # Protect Sidekiq Web UI in production via Basic Auth using env vars
      Sidekiq::Web.use Rack::Auth::Basic do |username, password|
        u = ENV.fetch('SIDEKIQ_ADMIN_USER', nil)
        p = ENV.fetch('SIDEKIQ_ADMIN_PASSWORD', nil)
        next false if u.nil? || p.nil?
        ActiveSupport::SecurityUtils.secure_compare(username, u) &
          ActiveSupport::SecurityUtils.secure_compare(password, p)
      end
      mount Sidekiq::Web => '/sidekiq'
    end
  rescue LoadError
    # sidekiq not available; skip
  end

  root "news#index"

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  get "/u/:slug", to: "profiles#show", as: :public_profile
  get "/u/:slug/resume", to: "profiles#resume", as: :profile_resume
  get "/profile/edit", to: "profiles#edit", as: :edit_profile
  patch "/profile", to: "profiles#update", as: :profile
  post "/profile/sync_github", to: "profiles#sync_github", as: :sync_github

  get "/profile/connect_domain", to: "profiles#connect_domain", as: :connect_domain
  post "/profile/domains",        to: "profiles#create_domain",  as: :domains
  delete "/profile/domains/:id",  to: "profiles#destroy_domain", as: :domain
  get "/profile/domains/:id/verify", to: "profiles#verify_domain", as: :verify_domain

  # Projects listing
  get "/projects", to: "projects#index", as: :projects
  # Backward-compatible route for older links
  get "/demos", to: "projects#index"

  get "/up", to: proc { [200, { "Content-Type" => "text/plain" }, ["ok"]] }

  resources :posts do
    resources :post_comments, only: [:create, :destroy]
    post 'react', to: 'post_reactions#create'
  end
end
