FROM php:8.2-fpm-alpine  AS base

LABEL MAINTAINER="MD.AL-AMIN" \
      "GitHub Link"="https://github.com/alaminAppnap" \
      "PHP Version"="8.2"

RUN apk update

# Set working directory
WORKDIR /app

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Install system dependencies
RUN apk add --no-cache mysql-client msmtp perl wget libzip libpng libjpeg-turbo libwebp freetype icu icu-data-full nginx supervisor

RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install uploadprogress \
    && docker-php-ext-enable uploadprogress \
    && apk del .build-deps $PHPIZE_DEPS \
    && chmod uga+x /usr/local/bin/install-php-extensions && sync \
    && install-php-extensions bcmath \
            curl \
            exif \
            fileinfo \
            gd \
            intl \
            mbstring \
            mcrypt \
            mysqli \
            opcache \
            openssl \
            pdo \
            pdo_mysql \
            redis \
            zip \
    &&  echo -e "\n opcache.enable=1 \n opcache.enable_cli=1 \n opcache.memory_consumption=128 \n opcache.interned_strings_buffer=8 \n opcache.max_accelerated_files=4000 \n opcache.revalidate_freq=60 \n opcache.fast_shutdown=1" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini


COPY . /app


# Copy nginx/php/supervisor configs
RUN cp docker/dev/supervisor.conf /etc/supervisord.conf
RUN cp docker/dev/php.ini /usr/local/etc/php/conf.d/app.ini
RUN cp docker/dev/nginx.conf /etc/nginx/http.d/default.conf

# PHP Error Log Files
RUN mkdir /var/log/php
RUN touch /var/log/php/errors.log && chmod 777 /var/log/php/errors.log


RUN chmod +x /app/docker/dev/run.sh

EXPOSE 80

ENTRYPOINT ["/app/docker/dev/run.sh"]