#!/bin/sh
set -e

cd /var/www/html

ROLE="${1:-web}"

prepare_storage() {
    mkdir -p \
        storage/app/public \
        storage/framework/cache/data \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
        bootstrap/cache

    if [ "${DB_CONNECTION:-sqlite}" = "sqlite" ]; then
        SQLITE_DATABASE="${DB_DATABASE:-database/database.sqlite}"

        if [ "$SQLITE_DATABASE" != ":memory:" ]; then
            mkdir -p "$(dirname "$SQLITE_DATABASE")"
            touch "$SQLITE_DATABASE"
        fi
    fi

    chown -R www-data:www-data storage bootstrap/cache database
    chmod -R ug+rwX storage bootstrap/cache database
}

run_bootstrap_tasks() {
    if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
        php artisan migrate --force --isolated || php artisan migrate --force
    fi

    if [ "${RUN_STORAGE_LINK:-true}" = "true" ]; then
        php artisan storage:link --force 2>/dev/null || true
    fi

    if [ "${RUN_LARAVEL_OPTIMIZE:-true}" = "true" ]; then
        php artisan optimize:clear
        php artisan optimize
    fi
}

prepare_storage
run_bootstrap_tasks

case "$ROLE" in
    web)
        php-fpm -D
        exec nginx -g "daemon off;"
        ;;

    queue)
        exec php artisan queue:work --sleep="${QUEUE_SLEEP:-3}" --tries="${QUEUE_TRIES:-3}" --max-time="${QUEUE_MAX_TIME:-3600}"
        ;;

    scheduler)
        exec php artisan schedule:work
        ;;

    *)
        exec "$@"
        ;;
esac
