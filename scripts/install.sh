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

echo "[install] Waiting for MySQL at ${DB_HOST:-mysql}:${DB_PORT:-3306}..."
until php -r "new PDO('mysql:host=${DB_HOST:-mysql};port=${DB_PORT:-3306}', getenv('DB_USERNAME'), getenv('DB_PASSWORD'));" >/dev/null 2>&1; do
    sleep 2
done
echo "[install] MySQL is reachable."

INSTALL_FLAGS="--no-interaction"
if [ "${BAGISTO_DEMO_SAMPLES:-false}" = "true" ]; then
    INSTALL_FLAGS="$INSTALL_FLAGS --demo-samples"
fi

echo "[install] Running php artisan bagisto:install ${INSTALL_FLAGS}..."
# shellcheck disable=SC2086
php artisan bagisto:install ${INSTALL_FLAGS}

echo "[install] Bagisto is ready."
echo "[install] Run scripts/optimize.sh before deploying to production."
