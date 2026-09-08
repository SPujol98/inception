#!/bin/sh
set -e

# 1. Prevent 'admin' or 'administrator' in admin username (42 subject rule)
case "$(echo "$WP_ADMIN_USER" | tr 'A-Z' 'a-z')" in
    *admin*)
        echo "Error: WP_ADMIN_USER must not contain 'admin' or 'administrator'." >&2
        exit 1
        ;;
esac

# 2. Wait for MariaDB with a 120s timeout limit
tries=0
until mariadb -h mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" --silent -e "SELECT 1;" >/dev/null 2>&1; do
    tries=$((tries + 1))
    if [ "$tries" -ge 60 ]; then
        echo "Error: MariaDB not reachable after 120s, aborting." >&2
        exit 1
    fi
    echo "Waiting for MariaDB..."
    sleep 2
done

# 3. Download WordPress core and generate wp-config.php
if [ ! -f "wp-config.php" ]; then
    wp core download --allow-root
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb:3306" \
        --allow-root
fi

# 4. Install WordPress and create users if database is not initialized yet
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="Inception" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    wp user create \
        "$WP_USER" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASSWORD" \
        --allow-root
fi

# 5. Fix permissions and run PHP-FPM in foreground
chown -R nobody:nobody /var/www/html
exec php-fpm81 -F