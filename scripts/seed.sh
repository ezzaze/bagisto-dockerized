#!/bin/sh
# Usage: docker compose exec app /var/www/scripts/seed.sh [artisan db:seed flags]
set -e
cd /var/www/html
php artisan db:seed --force "$@"
