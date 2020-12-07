FROM php:7.3.23-fpm-stretch

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libmcrypt-dev \
        libjpeg-dev \
        libpng-dev \
        libpq-dev \
        git \
        libaio1 \
        zip \
        gpg \
        wget \
        libxrender1 \
        libfontconfig \
        libc-client-dev \
        libkrb5-dev \                     
    && ldconfig \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && docker-php-ext-install mbstring \    
    && docker-php-ext-enable xdebug \  
    && docker-php-ext-enable opcache    

RUN mkdir /opt/oracle \
    && curl 'https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-basic-linux.x64-19.6.0.0.0dbru.zip' --output /opt/oracle/instantclient-basic-linux.zip \
    && curl 'https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip' --output /opt/oracle/instantclient-sdk-linux.zip \
    && unzip '/opt/oracle/instantclient-basic-linux.zip' -d /opt/oracle \
    && unzip '/opt/oracle/instantclient-sdk-linux.zip' -d /opt/oracle \
    && rm /opt/oracle/instantclient-*.zip \
    && mv /opt/oracle/instantclient_* /opt/oracle/instantclient \
    && docker-php-ext-configure oci8 --with-oci8=instantclient,/opt/oracle/instantclient \
    && docker-php-ext-install oci8 \
    && echo /opt/oracle/instantclient/ > /etc/ld.so.conf.d/oracle-insantclient.conf \
    && ldconfig

ENV ORACLE_HOME /opt/oracle/instantclient

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

WORKDIR /application

# Copy codebase
COPY . ./

# Override with custom php settings
COPY php.ini $PHP_INI_DIR/conf.d/

# COPY ./bootstrap.sh ./
COPY app/composer.json /application
RUN composer install --prefer-dist --no-scripts --no-autoloader && rm -rf /root/.composer

# Finish composer
RUN composer dump-autoload --no-scripts --optimize

RUN chown -R www-data:www-data .
