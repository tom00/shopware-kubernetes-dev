# syntax=docker/dockerfile:1

# Shopware-builder base image contains all necesary tools to build Shopware with `composer`.
FROM dunglas/frankenphp:1.2.5-php8.3.12-bookworm AS app-builder
ENV COMPOSER_HOME=/tmp/composer
ENV PROJECT_ROOT=/app
ENV UID=33
ENV GID=33
COPY --from=composer:2.7.7 /usr/bin/composer /usr/bin/composer
COPY php.ini.development /usr/local/etc/php/php.ini

RUN apt-get clean && apt-get update
RUN install-php-extensions \
	zip \
    && chown ${UID}:${GID} ${PROJECT_ROOT} \
    && rm -Rf ${PROJECT_ROOT}/* \
    && mkdir ${COMPOSER_HOME} \
    && chown ${UID}:${GID} ${COMPOSER_HOME}

USER www-data
COPY --chown=${UID}:${GID} composer.json composer.json
COPY --chown=${UID}:${GID} custom custom
RUN mkdir -p custom/plugins

# Build application for production/pre-production - no debug tools.
FROM app-builder AS app-builder-prod
RUN composer install --ignore-platform-reqs --no-dev --no-progress -a --apcu-autoloader \
    && composer dump-env prod

# Build dev application with dev dependencies
FROM app-builder AS app-builder-dev
RUN composer install --ignore-platform-reqs --dev --no-progress -a --apcu-autoloader \
    && composer dump-env dev \
    && echo '<?php phpinfo();' > public/info.php

# Build production static binary containing Shopware, PHP and Caddy webserver compiled-in.
FROM dunglas/frankenphp:static-builder AS php-builder-prod
SHELL ["/bin/bash", "-c"]

# build-static.sh script compresses the executable with max compression level only which is too slow
# to be used in the CI. Thus the compression has been carried out of the build-static script,
# thus needs to be disabled via `NO_COMPRESS=1`.
ENV NO_COMPRESS=1
# The List of extensions to build in.
ENV PHP_EXTENSIONS="amqp,apcu,bcmath,bz2,calendar,ctype,curl,dba,dom,exif,fileinfo,filter,gd,gmp,gettext,iconv,igbinary,intl,ldap,mbstring,mysqli,mysqlnd,opcache,openssl,pcntl,pdo,pdo_mysql,pdo_sqlite,phar,posix,protobuf,readline,redis,session,shmop,simplexml,soap,sockets,sodium,sqlite3,ssh2,sysvmsg,sysvsem,sysvshm,tidy,tokenizer,xlswriter,xml,xmlreader,xmlwriter,zip,zlib,yaml,zstd"
ENV PHP_VERSION="8.3"

WORKDIR /go/src/app/dist/app
COPY --from=app-builder-prod /app /go/src/app/dist/app
COPY php.ini.production /go/src/app/dist/app/php.ini

# Build the static binary
WORKDIR /go/src/app/

# Remove pre-compiled php-static library and build the new binary
#RUN rm -Rf dist/static-php-cli/ \
#    && EMBED=dist/app/ ./build-static.sh

RUN EMBED=dist/app/ ./build-static.sh

# Compress the executable.
# Compression level=7 is a good balance between the compression ratio and speed.
RUN export BIN="frankenphp-"$(uname -s | tr '[:upper:]' '[:lower:]')"-"$(uname -m) \
    && upx -7 "dist/${BIN}" \
    && mv "dist/${BIN}" dist/shopware-bin

# Build an image containing the application binary only.
FROM debian:bookworm-slim AS app-prod
ENV UID=33
ENV GID=33
COPY --from=php-builder-prod /go/src/app/dist/shopware-bin /shopware-bin
USER ${UID}:${GID}
ENTRYPOINT ["/shopware-bin"]

# Build dev image with xdebug.
FROM dunglas/frankenphp:1.2.5-php8.3.12-bookworm AS app-dev
ENV PROJECT_ROOT=/app
ENV PHP_EXTENSIONS="amqp,apcu,bcmath,bz2,calendar,ctype,curl,dba,dom,exif,fileinfo,filter,gd,gmp,gettext,iconv,igbinary,intl,ldap,mbstring,mysqli,mysqlnd,opcache,openssl,pcntl,pdo,pdo_mysql,pdo_sqlite,phar,posix,protobuf,readline,redis,session,shmop,simplexml,soap,sockets,sodium,sqlite3,ssh2,sysvmsg,sysvsem,sysvshm,tidy,tokenizer,xlswriter,xml,xmlreader,xmlwriter,zip,zlib,yaml,zstd"
ENV UID=33
ENV GID=33
SHELL ["/bin/bash", "-c"]

COPY --from=composer:2.7.7 /usr/bin/composer /usr/bin/composer
COPY php.ini.development ${PHP_INI_DIR}/php.ini
COPY --chown=${UID}:${GID} --from=app-builder-dev ${PROJECT_ROOT} ${PROJECT_ROOT}

# Install all required prod & dev PHP extensions.
RUN apt update && apt install -y libxml2-dev libcurl4-openssl-dev \
    && REQUIRED_EXT=$(echo ${PHP_EXTENSIONS} | tr ',' '\n' | sort -u) \
    && INSTALLED_EXT=$(php -m | egrep -v '^\[.+\]$' | tr '[:upper:]' '[:lower:]' | sort -u) \
    # Select extensions which haven't been already installed.
    && EXT=$(comm -23 <(echo "${REQUIRED_EXT}") <(echo "${INSTALLED_EXT}") | tr '\n' ' ') \
    && install-php-extensions ${EXT} \
    && ln -s /usr/local/bin/frankenphp /shopware-bin \
    && mkdir -p /data/caddy/ \
    && chown ${UID}:${GID} /data/caddy/

WORKDIR ${PROJECT_ROOT}/public
USER ${UID}:${GID}
ENTRYPOINT ["/shopware-bin"]