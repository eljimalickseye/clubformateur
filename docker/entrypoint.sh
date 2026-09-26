#!/bin/sh
set -e

cd /var/www/html

# Ensure .env exists
if [ ! -f ".env" ]; then
    if [ -f ".env.docker" ]; then
        cp .env.docker .env
    elif [ -f ".env.example" ]; then
        cp .env.example .env
    fi
fi

# Ensure storage and cache directories exist and are writable
mkdir -p storage/framework/sessions \
         storage/framework/views \
         storage/framework/cache/data \
         storage/app/public/uploads \
         bootstrap/cache \
         database

chown -R www-data:www-data storage bootstrap/cache database
chmod -R 775 storage bootstrap/cache database

# If using SQLite, make sure database.sqlite exists
DB_CONN=$(grep -E '^DB_CONNECTION=' .env | cut -d '=' -f2 | tr -d '\r"' || echo "sqlite")
if [ "${DB_CONNECTION:-$DB_CONN}" = "sqlite" ]; then
    if [ ! -f "database/database.sqlite" ]; then
        touch database/database.sqlite
        chown www-data:www-data database/database.sqlite
        chmod 664 database/database.sqlite
    fi
fi

# Wait for MySQL if DB_CONNECTION is mysql
if [ "${DB_CONNECTION:-$DB_CONN}" = "mysql" ]; then
    echo "En attente de la base de données MySQL (${DB_HOST:-db}:${DB_PORT:-3306})..."
    MAX_TRIES=30
    COUNT=0
    until php -r "try { new PDO('mysql:host=' . (getenv('DB_HOST') ?: 'db') . ';port=' . (getenv('DB_PORT') ?: '3306'), getenv('DB_USERNAME') ?: 'club_user', getenv('DB_PASSWORD') ?: 'club_password'); exit(0); } catch (Exception \$e) { exit(1); }" >/dev/null 2>&1; do
        COUNT=$((COUNT + 1))
        if [ $COUNT -ge $MAX_TRIES ]; then
            echo "Attention: MySQL ne répond pas après $MAX_TRIES tentatives, poursuite du démarrage..."
            break
        fi
        sleep 2
    done
    echo "Connexion MySQL prête !"
fi

# Run migrations and seed if database is empty
php artisan config:clear || true
php artisan storage:link --force || true
php artisan migrate --force || true

USER_COUNT=$(php artisan tinker --execute="echo \App\Models\User::count();" 2>/dev/null | tr -d '\r\n' || echo "0")
if [ "$USER_COUNT" = "0" ] || [ -z "$USER_COUNT" ]; then
    echo "Initialisation des données de démonstration (DatabaseSeeder)..."
    php artisan db:seed --force || true
fi

echo "Backend Laravel Club des Formateurs démarré sur le port 8000 (/api/v1)"
exec "$@"
