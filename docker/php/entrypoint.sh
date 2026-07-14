#!/bin/sh
set -e

if [ -n "$DB_HOST" ]; then
  echo "[entrypoint] Waiting for MySQL at ${DB_HOST}:${DB_PORT:-3306}..."
  until php -r "new PDO('mysql:host=${DB_HOST};port=${DB_PORT:-3306}', getenv('DB_USERNAME'), getenv('DB_PASSWORD'));" >/dev/null 2>&1; do
    sleep 2
  done
  echo "[entrypoint] MySQL is reachable."
fi

if [ -n "$REDIS_HOST" ]; then
  echo "[entrypoint] Waiting for Redis at ${REDIS_HOST}:${REDIS_PORT:-6379}..."
  until php -r "(new Redis())->connect(getenv('REDIS_HOST'), (int) getenv('REDIS_PORT') ?: 6379);" >/dev/null 2>&1; do
    sleep 2
  done
  echo "[entrypoint] Redis is reachable."
fi

# php-fpm and supervisord both drop their own worker/program processes to
# www-data (see docker/php/Dockerfile and docker/supervisor/*.conf) and must
# themselves start as root. Everything else invoked through this image
# (install.sh, migrate.sh, an ad-hoc `docker compose exec app ...`) runs
# straight as www-data so it never leaves root-owned files behind in the
# bind-mounted storage/bootstrap/cache directories.
if [ "$(id -u)" = "0" ] && [ "$1" != "php-fpm" ] && [ "$1" != "supervisord" ]; then
  exec gosu www-data "$@"
fi

exec "$@"
