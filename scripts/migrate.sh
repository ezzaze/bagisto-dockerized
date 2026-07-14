#!/bin/sh
# Usage: docker compose exec app /var/www/scripts/migrate.sh [artisan migrate flags]
set -e
cd /var/www/html
php artisan migrate --force "$@"
