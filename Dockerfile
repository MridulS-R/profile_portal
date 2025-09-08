
FROM ruby:3.2

RUN apt-get update -y &&     apt-get install -y build-essential git curl libpq-dev &&     gem install bundler

WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle install --without development test

COPY . .

ENV RAILS_ENV=production RACK_ENV=production PORT=8080
EXPOSE 8080

CMD bash -lc "bundle exec rails db:migrate && bundle exec puma -C config/puma.rb"
