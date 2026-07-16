#!/bin/sh
# Idempotent Bagisto bootstrap — safe to run on every `docker compose up -d`.
# Skips straight through once storage/installed exists (created by the
# bagisto:install artisan command itself).
set -e

cd /var/www/html

if [ -f storage/installed ]; then
    echo "[install] Bagisto is already installed — skipping."
    exit 0
fi

# The dev image intentionally ships no vendor/ (see docker/php/Dockerfile) and
# relies on the bind-mounted host code. On a fresh clone that directory is
# empty, so bootstrap Composer deps before artisan needs the autoloader.
if [ ! -f vendor/autoload.php ]; then
    echo "[install] vendor/autoload.php missing — running composer install..."
    composer install --no-interaction --prefer-dist
fi

echo "[install] Waiting for MySQL at ${DB_HOST:-mysql}:${DB_PORT:-3306}..."
until php -r "new PDO('mysql:host=${DB_HOST:-mysql};port=${DB_PORT:-3306}', getenv('DB_USERNAME'), getenv('DB_PASSWORD'));" >/dev/null 2>&1; do
    sleep 2
done
echo "[install] MySQL is reachable."

INSTALL_FLAGS="--no-interaction"
if [ "${BAGISTO_DEMO_SAMPLES:-false}" = "true" ]; then
    if [ "${APP_ENV:-local}" = "production" ]; then
        echo "[install] APP_ENV=production — ignoring BAGISTO_DEMO_SAMPLES=true. Demo/sample catalog data is never seeded in production, regardless of that flag."
    else
        INSTALL_FLAGS="$INSTALL_FLAGS --demo-samples"
    fi
fi

echo "[install] Running php artisan bagisto:install ${INSTALL_FLAGS}..."
# shellcheck disable=SC2086
php artisan bagisto:install ${INSTALL_FLAGS}

echo "[install] Bagisto is ready."
echo "[install] Run scripts/optimize.sh before deploying to production."
