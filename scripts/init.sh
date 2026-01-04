#!/usr/bin/env bash
set -e

echo "=== WP Instant Init (Pure WP-CLI) ==="

# --------------------------------------------------
# Load .env (CRITICAL FIX)
# --------------------------------------------------
if [ -f .env ]; then
  echo "Loading .env..."
  set -a
  source .env
  set +a
else
  echo "ERROR: .env file not found"
  exit 1
fi

WP_PATH=/var/www/html

# --------------------------------------------------
# 1. Wait for MySQL
# --------------------------------------------------
echo "Waiting for MySQL to be healthy..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  # Check if db service is healthy
  DB_HEALTH=$(docker compose ps db --format json 2>/dev/null | grep -o '"Health":"[^"]*"' | cut -d'"' -f4)
  
  if [ "$DB_HEALTH" = "healthy" ]; then
    echo "MySQL is ready and healthy."
    break
  fi
  
  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "Waiting for MySQL... ($RETRY_COUNT/$MAX_RETRIES)"
  sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "ERROR: MySQL failed to become healthy after $MAX_RETRIES attempts"
  echo "Check logs with: docker compose logs db"
  exit 1
fi

# --------------------------------------------------
# 2. Ensure WordPress core exists
# --------------------------------------------------
if ! docker compose exec wpcli test -f $WP_PATH/wp-load.php; then
  echo "Downloading WordPress core..."
  docker compose exec wpcli wp core download \
    --path=$WP_PATH \
    --allow-root
else
  echo "WordPress core already exists."
fi

# --------------------------------------------------
# 3. Create wp-config.php
# --------------------------------------------------
if ! docker compose exec wpcli test -f $WP_PATH/wp-config.php; then
  echo "Creating wp-config.php..."
  docker compose exec wpcli wp config create \
    --path=$WP_PATH \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASS" \
    --dbhost="db" \
    --skip-check \
    --allow-root
  
  # Add WordPress configuration constants
  echo "Configuring WordPress settings..."
  docker compose exec wpcli wp config set FS_METHOD 'direct' --raw --allow-root --path=$WP_PATH
  docker compose exec wpcli wp config set WP_MEMORY_LIMIT '256M' --allow-root --path=$WP_PATH
  docker compose exec wpcli wp config set WP_MAX_MEMORY_LIMIT '512M' --allow-root --path=$WP_PATH
  docker compose exec wpcli wp config set DISABLE_WP_CRON false --raw --allow-root --path=$WP_PATH
  docker compose exec wpcli wp config set DISALLOW_FILE_EDIT true --raw --allow-root --path=$WP_PATH
  
  # Fix loopback request issues
  docker compose exec wpcli wp config set WP_HTTP_BLOCK_EXTERNAL false --raw --allow-root --path=$WP_PATH
  docker compose exec wpcli wp config set WP_ACCESSIBLE_HOSTS 'localhost,127.0.0.1' --allow-root --path=$WP_PATH
  docker compose exec wpcli wp config set AUTOMATIC_UPDATER_DISABLED false --raw --allow-root --path=$WP_PATH
else
  echo "wp-config.php already exists."
fi

# --------------------------------------------------
# 4. Install WordPress (DATABASE)
# --------------------------------------------------
if docker compose exec wpcli wp core is-installed \
  --path=$WP_PATH \
  --allow-root >/dev/null 2>&1; then
  echo "WordPress already installed. Skipping."
else
  echo "Installing WordPress..."
  docker compose exec wpcli wp core install \
    --path=$WP_PATH \
    --url="$SITE_URL" \
    --title="$SITE_TITLE" \
    --admin_user="$ADMIN_USER" \
    --admin_password="$ADMIN_PASS" \
    --admin_email="$ADMIN_EMAIL" \
    --skip-email \
    --allow-root
fi

# --------------------------------------------------
# 5. Install PUBLIC plugin
# --------------------------------------------------
docker compose exec wpcli wp plugin is-installed all-in-one-wp-migration \
  --path=$WP_PATH \
  --allow-root >/dev/null 2>&1 \
|| docker compose exec wpcli wp plugin install all-in-one-wp-migration \
  --path=$WP_PATH \
  --activate \
  --allow-root

# --------------------------------------------------
# 6. Install PRIVATE plugin
# --------------------------------------------------
PRIVATE_PLUGIN="/plugins-private/allinonewpmigrationgdriveextension.zip"

if docker compose exec wpcli test -f "$PRIVATE_PLUGIN"; then
  docker compose exec wpcli wp plugin is-installed all-in-one-wp-migration-gdrive-extension \
    --path=$WP_PATH \
    --allow-root >/dev/null 2>&1 \
  || docker compose exec wpcli wp plugin install "$PRIVATE_PLUGIN" \
    --path=$WP_PATH \
    --activate \
    --allow-root
fi

# --------------------------------------------------
# 7. Create .htaccess for permalinks
# --------------------------------------------------
echo "Creating .htaccess..."
docker compose exec wpcli wp rewrite structure '/%postname%/' --allow-root --path=$WP_PATH
docker compose exec wpcli wp rewrite flush --allow-root --path=$WP_PATH

echo "DONE"
