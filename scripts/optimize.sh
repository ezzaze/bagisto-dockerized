#!/bin/sh
# Production-style optimization pass: bake config/route/view/event caches and
# an optimized autoloader. Run this after every deploy, not during local dev
# (route:cache in particular will make newly edited routes invisible until
# cleared, which is the wrong trade-off while iterating).
set -e
cd /var/www/html

echo "[optimize] Optimizing composer autoloader..."
composer dump-autoload --optimize --no-dev 2>/dev/null || composer dump-autoload --optimize

echo "[optimize] Caching config..."
php artisan config:cache

echo "[optimize] Caching routes..."
php artisan route:cache

echo "[optimize] Caching views..."
php artisan view:cache

echo "[optimize] Caching events..."
php artisan event:cache

echo "[optimize] Done."
