#!/usr/bin/env bash
set -e

echo "=== WordPress Instant Setup ==="

if [ ! -f ".env" ]; then
  cp .env.example .env
  echo "Created .env from .env.example"
else
  echo ".env already exists, skipped"
fi

read -p "Database name: " DB_NAME
read -p "Database user: " DB_USER
read -s -p "Database password: " DB_PASS
echo ""

read -p "Site title: " SITE_TITLE
read -p "Admin username: " ADMIN_USER
read -s -p "Admin password: " ADMIN_PASS
echo ""
read -p "Admin email: " ADMIN_EMAIL

echo "Starting Docker..."
docker compose up -d

echo "Waiting for MySQL..."
sleep 15

echo "Creating database & user..."

docker compose exec db mysql -uroot -proot -e "
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
"

echo "Checking WordPress installation..."

if docker compose exec wpcli wp core is-installed --allow-root >/dev/null 2>&1; then
  echo "WordPress already installed. Skipping download & install."
else
  echo "Downloading WordPress..."
  docker compose exec wpcli wp core download --allow-root

  echo "Creating wp-config.php..."
  docker compose exec wpcli wp config create \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASS}" \
    --dbhost="db" \
    --skip-check \
    --allow-root

  echo "Installing WordPress..."
  docker compose exec wpcli wp core install \
    --url="http://localhost:8080" \
    --title="${SITE_TITLE}" \
    --admin_user="${ADMIN_USER}" \
    --admin_password="${ADMIN_PASS}" \
    --admin_email="${ADMIN_EMAIL}" \
    --skip-email \
    --allow-root

  echo "Installing plugins from plugins.txt..."

  if [[ -f plugins.txt ]]; then
    while read -r plugin; do
      [[ -z "$plugin" || "$plugin" == \#* ]] && continue

      echo "Installing plugin: $plugin"
      docker compose exec wpcli wp plugin install "$plugin" --activate --allow-root

    done < plugins.txt
  else
    echo "No plugins.txt found, skipping plugin installation."
  fi
  

  echo "Checking private plugins..."

  if [[ -d plugins-private ]] && compgen -G "plugins-private/*.zip" > /dev/null; then
    echo "Installing private plugins..."

    for zip in plugins-private/*.zip; do
      echo "Installing private plugin: $(basename "$zip")"
      docker compose exec wpcli wp plugin install "/plugins-private/$(basename "$zip")" --activate --allow-root
    done
  else
    echo "No private plugins found, skipping."
  fi

fi

echo "DONE!"
echo "Open: http://localhost:8080"

echo "Unlinking project from wp-instant Git repository..."
rm -rf .git
echo "Git repository has been removed. This project is now standalone."