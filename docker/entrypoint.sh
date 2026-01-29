#!/bin/bash

set -e

role=${CONTAINER_ROLE:-app}
env=${APP_ENV:-development}

echo "Container role: $role"
echo "Environment: $env"

# Wait for MySQL to be ready
if [ "$role" = "app" ] || [ "$role" = "queue" ] || [ "$role" = "scheduler" ]; then
    echo "Waiting for MySQL to be ready..."
    while ! nc -z mysql 3306; do
        sleep 1
    done
    echo "MySQL is ready!"
fi

# Install composer dependencies if vendor directory doesn't exist
if [ ! -d "vendor" ]; then
    echo "Installing composer dependencies..."
    composer install --no-interaction --prefer-dist --optimize-autoloader
fi

# Run migrations only for app role
if [ "$role" = "app" ]; then
    echo "Running migrations..."
    php artisan migrate --force || true

    echo "Clearing cache..."
    php artisan config:clear
    php artisan cache:clear
    php artisan view:clear

    if [ "$env" != "production" ]; then
        echo "Caching configuration for non-production..."
        php artisan config:cache
    fi
fi

# Execute based on role
if [ "$role" = "app" ]; then
    echo "Starting PHP-FPM..."
    exec php-fpm
elif [ "$role" = "queue" ]; then
    echo "Starting queue worker..."
    exec php artisan queue:work --verbose --tries=3 --timeout=90
elif [ "$role" = "scheduler" ]; then
    echo "Starting scheduler..."
    # Add cron job for Laravel scheduler
    echo "* * * * * cd /var/www && php artisan schedule:run >> /dev/null 2>&1" | crontab -
    exec cron -f
else
    echo "Unknown role: $role"
    exit 1
fi
