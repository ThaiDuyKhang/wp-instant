FROM wordpress:php8.4-apache

RUN apt-get update && apt-get install -y \
    unzip \
    less \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

COPY docker/wordpress/php.ini /usr/local/etc/php/conf.d/custom.ini

WORKDIR /var/www/html
