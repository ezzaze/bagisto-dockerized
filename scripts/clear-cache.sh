#!/bin/sh
# Usage: docker compose exec app /var/www/scripts/clear-cache.sh
set -e
cd /var/www/html
php artisan optimize:clear
php artisan cache:clear
echo "[clear-cache] config/route/view/event caches and the app data cache have been cleared."
