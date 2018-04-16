#!/usr/bin/env bash
set -e
source /etc/profile.d/rvm.sh

cmd="bundle exec unicorn -E production -c config/unicorn.rb"
timer="5"

# wait for postgres to be ready before preparing
until pg_isready -q -h postgres; do
  echo "Postgres is unavailable - sleeping for $timer seconds"
  sleep $timer
done

echo "Postgres is up"
echo "Preparing assets"

bundle exec rake assets:precompile
bundle exec rake db:migrate
bundle exec rake db:seed || echo "db is already seeded"

echo "starting helpy"

exec $cmd