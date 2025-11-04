FROM php:8.4-fpm-alpine

# Установка необходимых пакетов и PHP-расширений для PostgreSQL и общих библиотек
RUN apk add --no-cache \
    curl \
    $PHPIZE_DEPS \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    oniguruma-dev \
    libzip-dev \
    linux-headers \
    fcgi \
    postgresql-dev \
    && pecl channel-update pecl.php.net \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && docker-php-ext-install \
    pdo \
    pdo_pgsql \
    pgsql \
    mbstring \
    xml \
    gd \
    bcmath \
    zip \
    && apk del $PHPIZE_DEPS

# Composer (копируем бинарник Composer в образ)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Рабочая директория (workdir)
WORKDIR /var/www/html

# Открываем порт FPM по TCP (только внутри сети Docker)
EXPOSE 9000

# Запуск PHP-FPM
CMD ["php-fpm"]
