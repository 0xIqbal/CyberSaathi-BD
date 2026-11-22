#!/usr/bin/env bash
set -e

php artisan config:clear
php artisan route:clear
php artisan config:cache
php artisan route:cache

exec php artisan serve --host=0.0.0.0 --port="${PORT:-8000}"