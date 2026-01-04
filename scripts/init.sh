#!/usr/bin/env bash
set -e

echo "=== WP Instant Init ==="

echo "Waiting for MySQL..."
until docker compose exec db mysqladmin ping -uroot -proot --silent; do
  sleep 2
done

if docker compose exec wpcli wp core is-installed --allow-root >/dev/null 2>&1; then
  echo "WordPress already installed. Skipping."
  exit 0
fi

echo "Downloading latest WordPress..."
docker compose exec wpcli wp core download --allow-root

echo "Creating wp-config.php..."
docker compose exec wpcli wp config create \
  --dbname="$DB_NAME" \
  --dbuser="$DB_USER" \
  --dbpass="$DB_PASS" \
  --dbhost="db" \
  --skip-check \
  --allow-root

echo "Installing WordPress..."
docker compose exec wpcli wp core install \
  --url="$SITE_URL" \
  --title="$SITE_TITLE" \
  --admin_user="$ADMIN_USER" \
  --admin_password="$ADMIN_PASS" \
  --admin_email="$ADMIN_EMAIL" \
  --skip-email \
  --allow-root

echo "Installing public plugin..."
docker compose exec wpcli wp plugin is-installed all-in-one-wp-migration --allow-root \
  || docker compose exec wpcli wp plugin install all-in-one-wp-migration --activate --allow-root

echo "Installing private plugin..."
if [[ -f plugins-private/allinonewpmigrationgdriveextension.zip ]]; then
  docker compose exec wpcli wp plugin is-installed all-in-one-wp-migration-gdrive-extension --allow-root \
    || docker compose exec wpcli wp plugin install \
      /plugins-private/allinonewpmigrationgdriveextension.zip \
      --activate \
      --allow-root
fi

echo "DONE"
