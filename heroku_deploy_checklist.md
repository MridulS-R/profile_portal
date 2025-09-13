# Heroku Deployment Checklist

## 1. Gem and Dependency Changes
- [ ] Ensure all required gems are included in the `Gemfile`.
- [ ] Run `bundle install` to install any new gems.
- [ ] Check for any outdated gems with `bundle outdated` and update as necessary.

## 2. Database Configuration
- [ ] Ensure the `database.yml` file is properly configured for production.
- [ ] Set up the Heroku Postgres database by running `heroku addons:create heroku-postgresql:hobby-dev`.
- [ ] Run database migrations using `heroku run rails db:migrate`.

## 3. Procfile
- [ ] Create a `Procfile` in the root directory if it does not exist.
- [ ] Define the web server process, e.g., `web: bundle exec puma -C config/puma.rb`.

## 4. Environment Variables
- [ ] Set environment variables using `heroku config:set VAR_NAME=value` for sensitive data like API keys.
- [ ] Ensure that `config/secrets.yml` is correctly set up for production.

## 5. Asset Setup
- [ ] Precompile assets for production using `rails assets:precompile`.
- [ ] Verify that assets are served correctly in production.

## 6. Cloud Storage
- [ ] Set up cloud storage (e.g., AWS S3) if the app requires file uploads.
- [ ] Configure environment variables for cloud storage credentials.

## 7. Heroku Best Practices
- [ ] Ensure logging is properly set up with `heroku logs --tail` to monitor app performance.
- [ ] Use the Heroku dashboard to monitor app metrics.
- [ ] Regularly check for security updates and apply them.

## 8. Final Checks
- [ ] Test the app locally with the production environment settings.
- [ ] Ensure that the app runs without errors before deploying.

---
This checklist should be followed to ensure a smooth deployment process to Heroku. Adjust as necessary for specific application needs.