FROM php:8.0.3-apache-buster

RUN apt-get update && apt-get install -y \
    sqlite3 \
    git \
    zip \
    curl \
    sudo \
    unzip \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    g++ \
    libmemcached-dev \
    zlib1g-dev \
    libzip-dev \
    libssl-dev \
    pkg-config

RUN pecl install memcached \
    && pecl install redis \
    && pecl install zip \
    && docker-php-ext-enable memcached redis zip

# Apache configuration
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN a2enmod rewrite headers

# Configure ZIP
#RUN docker-php-ext-configure zip --with-libzip


# Common PHP Extensions
RUN docker-php-ext-install \
    bz2 \
    intl \
    iconv \
    bcmath \
    opcache \
    pcntl \
    gettext \
    gd \
    pdo_sqlite

# Ensure PHP logs are captured by the container
ENV LOG_CHANNEL=stderr

# Copy prod php config
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

VOLUME /var/www/html

# Copy code and run composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY . /var/www/tmp

RUN cd /var/www/tmp && composer install --no-dev

# Ensure the entrypoint file can be run
RUN chmod +x /var/www/tmp/docker-entrypoint.sh
ENTRYPOINT ["/var/www/tmp/docker-entrypoint.sh"]

CMD ["apache2-foreground"]
