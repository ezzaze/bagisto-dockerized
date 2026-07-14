FROM php:8.3-fpm AS base

RUN apt-get update && apt-get install -y --no-install-recommends \
        git unzip libpng-dev libjpeg62-turbo-dev libfreetype6-dev libwebp-dev \
        libzip-dev libicu-dev libonig-dev libxml2-dev libpq-dev \
        default-mysql-client supervisor netcat-openbsd gosu \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j"$(nproc)" \
        pdo_mysql mbstring exif pcntl bcmath gd zip intl opcache calendar \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ARG UID=1000
ARG GID=1000
RUN groupmod -g ${GID} www-data && usermod -u ${UID} -g www-data www-data

COPY docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY docker/supervisor/supervisord.queue.conf /etc/supervisor/supervisord.queue.conf
COPY docker/supervisor/supervisord.scheduler.conf /etc/supervisor/supervisord.scheduler.conf

WORKDIR /var/www/html
EXPOSE 9000
ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm"]

# ---------------------------------------------------------------------------
# dev: runtime only. Application code (incl. vendor/) is bind-mounted from
# the host at ./backend, so nothing is copied into the image here.
# ---------------------------------------------------------------------------
FROM base AS dev

ARG INSTALL_XDEBUG=false
RUN if [ "$INSTALL_XDEBUG" = "true" ]; then \
        pecl install xdebug && docker-php-ext-enable xdebug; \
    fi

COPY docker/php/php.dev.ini /usr/local/etc/php/conf.d/99-app.ini
COPY scripts/ /var/www/scripts/
RUN chmod +x /var/www/scripts/*.sh

# Stays root: php-fpm's own pool config (www.conf) drops its worker
# processes to www-data, and supervisord (queue/scheduler containers) needs
# root to spawn its `user=www-data` programs. entrypoint.sh gosu's every
# other command (install.sh, ad-hoc artisan calls, etc.) down to www-data so
# storage/bootstrap/cache files stay consistently owned.

# ---------------------------------------------------------------------------
# vendor: production dependency build, isolated so the prod stage doesn't
# carry build tooling or the full composer cache.
# ---------------------------------------------------------------------------
FROM base AS vendor

COPY --chown=www-data:www-data backend/composer.json backend/composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

COPY --chown=www-data:www-data backend/ .
RUN composer dump-autoload --optimize --no-dev \
    && composer run-script post-autoload-dump --no-dev || true

# ---------------------------------------------------------------------------
# prod: immutable image with code + vendor baked in, OPcache tuned for
# production, no bind mounts expected.
# ---------------------------------------------------------------------------
FROM base AS prod

COPY docker/php/php.prod.ini /usr/local/etc/php/conf.d/99-app.ini
COPY scripts/ /var/www/scripts/
RUN chmod +x /var/www/scripts/*.sh

COPY --from=vendor --chown=www-data:www-data /var/www/html /var/www/html
RUN chown -R www-data:www-data storage bootstrap/cache
