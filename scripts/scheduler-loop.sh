#!/bin/sh
# Laravel has no long-running scheduler daemon; the documented pattern is to
# invoke schedule:run once a minute. This loop is that "cron", containerized.
set -e
cd /var/www/html

while true; do
    php artisan schedule:run --no-interaction
    sleep 60
done
