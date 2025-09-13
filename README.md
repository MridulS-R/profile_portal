
# Profile Portal (Full Rails App)

Features:
- Devise auth (email/password) + GitHub OAuth
- Public profiles at /u/:slug, home shows site owner's profile by default
- Demos list GitHub repos with stars/forks/issues/topics/last updated
- Custom banners and social links
- Custom domains: host -> user profile mapping
- Deployment ready: Dockerfile, Procfile
- Background sync with Sidekiq + daily cron

## Setup (Local)

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails s
```

Default login: `admin@example.com` / `password` (from seeds)

## ENV

- SITE_OWNER_GITHUB=your_github
- GITHUB_TOKEN=
- GITHUB_CLIENT_ID=
- GITHUB_CLIENT_SECRET=
- DEVISE_SECRET_KEY= (optional)
- REDIS_URL=redis://localhost:6379/0 (for Sidekiq)

## Deploy

Use any platform that supports a standard Ruby on Rails setup. A `Dockerfile` and `Procfile` are included for containerized or Procfile-based deployments.

## Background Jobs

- Sidekiq is used for background processing. A cron job runs daily at 03:00 UTC to sync GitHub repos for all users with a `github_username`.
- Run locally:

```bash
bundle exec sidekiq -C config/sidekiq.yml
```

- Dashboard (development): visit `/sidekiq`.
