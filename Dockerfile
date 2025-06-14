# Stage 1: Composer dependencies
FROM php:8.2-cli-alpine as composer

# Install system dependencies and PHP extensions for composer install
RUN apk add --no-cache git unzip icu-dev libzip-dev oniguruma-dev libxml2-dev \
    && docker-php-ext-install intl zip bcmath soap

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# Stage 2: Production image
FROM php:8.2-fpm-alpine

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    nginx supervisor bash icu-dev libzip-dev libpng-dev \
    jpegoptim optipng pngquant gifsicle unzip git oniguruma-dev libxml2-dev \
    && docker-php-ext-install pdo_mysql intl zip bcmath soap

WORKDIR /var/www/html
COPY --from=composer /app /var/www/html
COPY . /var/www/html

# Stage 3: Production image
FROM php:8.2-fpm-alpine

# Install system dependencies
RUN apk add --no-cache nginx supervisor bash icu-dev libzip-dev libpng-dev jpegoptim optipng pngquant gifsicle unzip git oniguruma-dev

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql intl zip

# Copy application code
WORKDIR /var/www/html
COPY --from=composer /app /var/www/html
COPY . /var/www/html

# Optional: copy built assets if you have them
# COPY --from=assets /app/public /var/www/html/public

# Copy Nginx config
COPY .docker/nginx.conf /etc/nginx/nginx.conf

# Copy Supervisor config to run PHP-FPM and Nginx together
COPY .docker/supervisord.conf /etc/supervisord.conf

# Set permissions (tune for your setup)
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/web/cpresources

# Expose HTTP
EXPOSE 80

# Start supervisor (runs both Nginx and PHP-FPM)
CMD ["supervisord", "-c", "/etc/supervisord.conf"]