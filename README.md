
# Profile Portal (Full Rails App)

Features:
- Devise auth (email/password) + GitHub OAuth
- Public profiles at /u/:slug, home shows site owner's profile by default
- Demos list GitHub repos with stars/forks/issues/topics/last updated
- Custom banners and social links
- Custom domains: host -> user profile mapping
- Fly.io ready: Dockerfile, fly.toml, Procfile

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

## Deploy (Fly.io)

```bash
fly launch --copy-config
fly secrets set RAILS_MASTER_KEY=$(<config/master.key) SITE_OWNER_GITHUB=your_github GITHUB_CLIENT_ID=xxx GITHUB_CLIENT_SECRET=yyy
fly deploy
```
