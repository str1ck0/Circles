#!/usr/bin/env bash
# Build script run by Render on every deploy.
# Docs: https://render.com/docs/deploy-rails
set -o errexit

bundle install
yarn install --frozen-lockfile

# Compile JS (jsbundling runs `yarn build`) and CSS.
bundle exec rails assets:precompile
bundle exec rails assets:clean

# Create/migrate the database, then seed it once if it's empty (so the live
# demo always has data without wiping visitor-created content on every deploy).
bundle exec rails db:prepare
bundle exec rails runner "Rails.application.load_seed if User.count.zero?"
