#!/bin/sh
# Usage: docker compose exec app /var/www/scripts/update.sh
# Run after pulling new backend code: refreshes dependencies, migrates the
# database, and drops any stale caches. Does not reinstall Bagisto.
set -e
cd /var/www/html

echo "[update] composer install..."
composer install --no-interaction --optimize-autoloader

echo "[update] Running database migrations..."
php artisan migrate --force

echo "[update] Clearing caches..."
php artisan optimize:clear

echo "[update] Done. Run optimize.sh before deploying to production."
