#!/usr/bin/env bash
set -e

echo "=== WP Instant Init ==="

echo "Waiting for MySQL..."
until docker compose exec db mysqladmin ping -uroot -proot --silent; do
  sleep 2
done

if docker compose exec wpcli wp core is-installed --allow-root --path=/var/www/html >/dev/null 2>&1; then
  echo "WordPress already installed. Skipping core install."
else
  echo "Installing WordPress..."
  docker compose exec wpcli wp core install \
    --url="$SITE_URL" \
    --title="$SITE_TITLE" \
    --admin_user="$ADMIN_USER" \
    --admin_password="$ADMIN_PASS" \
    --admin_email="$ADMIN_EMAIL" \
    --skip-email \
    --allow-root \
    --path=/var/www/html
fi

echo "Installing public plugins..."

if docker compose exec wpcli wp plugin is-installed all-in-one-wp-migration --allow-root --path=/var/www/html >/dev/null 2>&1; then
  echo "Plugin all-in-one-wp-migration already installed."
else
  docker compose exec wpcli wp plugin install all-in-one-wp-migration \
    --activate \
    --allow-root \
    --path=/var/www/html
fi

PRIVATE_PLUGIN_ZIP="/plugins-private/allinonewpmigrationgdriveextension.zip"

echo "Installing private plugins..."

if docker compose exec wpcli test -f "$PRIVATE_PLUGIN_ZIP"; then
  if docker compose exec wpcli wp plugin is-installed all-in-one-wp-migration-gdrive-extension --allow-root --path=/var/www/html >/dev/null 2>&1; then
    echo "Private plugin already installed."
  else
    docker compose exec wpcli wp plugin install "$PRIVATE_PLUGIN_ZIP" \
      --activate \
      --allow-root \
      --path=/var/www/html
  fi
else
  echo "Private plugin ZIP not found, skipping."
fi

echo "DONE"
