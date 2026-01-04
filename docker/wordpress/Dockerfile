FROM php:8.4-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    unzip \
    less \
    mariadb-client \
    curl \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libmagickwand-dev \
    libwebp-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
    mysqli \
    pdo_mysql \
    gd \
    zip \
    opcache \
    exif \
    intl

# Install imagick from PECL
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Enable Apache mod_rewrite for WordPress permalinks
RUN a2enmod rewrite

# Configure Apache ServerName to suppress warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Configure PHP for WordPress
RUN { \
    echo 'memory_limit = 512M'; \
    echo 'upload_max_filesize = 64M'; \
    echo 'post_max_size = 64M'; \
    echo 'max_execution_time = 300'; \
    echo 'opcache.enable = 1'; \
    echo 'opcache.memory_consumption = 128'; \
    echo 'opcache.interned_strings_buffer = 8'; \
    echo 'opcache.max_accelerated_files = 4000'; \
    echo 'opcache.revalidate_freq = 60'; \
    } > /usr/local/etc/php/conf.d/wordpress.ini

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Create entrypoint script to fix permissions
RUN echo '#!/bin/bash\n\
    set -e\n\
    \n\
    # Fix permissions for wp-content if it exists\n\
    if [ -d "/var/www/html/wp-content" ]; then\n\
    echo "Fixing wp-content permissions..."\n\
    chown -R www-data:www-data /var/www/html/wp-content\n\
    chmod -R 755 /var/www/html/wp-content\n\
    chmod -R 775 /var/www/html/wp-content/uploads 2>/dev/null || true\n\
    chmod -R 775 /var/www/html/wp-content/plugins 2>/dev/null || true\n\
    fi\n\
    \n\
    # Execute the original command\n\
    exec "$@"' > /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /var/www/html

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
