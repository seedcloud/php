{{ getenv "BASE_IMAGE" }}

ENV GOTLP_VER 0.1.5
ENV RABBITMQ_C_VER 0.8.0
ENV WALTER_VER 1.3.0

ENV APP_ROOT /var/www/html

# Recreate user with correct params
RUN deluser www-data && \
	addgroup -g 82 -S www-data && \
	adduser -u 82 -D -S -s /bin/bash -G www-data www-data && \
	sed -i '/^www-data/s/!/*/' /etc/shadow

RUN set -xe && \
    apk add --update \
{{ range jsonArray (getenv "PACKAGES") }}
        {{ . }} \{{ end }}
        && \

    apk add --update --no-cache --virtual .build-deps \
{{ range jsonArray (getenv "BUILD_PACKAGES") }}
        {{ . }} \{{ end }}
        && \

    docker-php-source extract && \

    docker-php-ext-install \
{{ range jsonArray (getenv "EXTENSIONS") }}
        {{ . }} \{{ end }}
        && \

    && docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ && \
      NPROC=$(getconf _NPROCESSORS_ONLN) && \
      docker-php-ext-install -j${NPROC} gd && \

    # RabbitMQ C client
    wget -qO- https://github.com/alanxz/rabbitmq-c/releases/download/v${RABBITMQ_C_VER}/rabbitmq-c-${RABBITMQ_C_VER}.tar.gz \
        | tar xz -C /tmp/ && \
    cd /tmp/rabbitmq-c-${RABBITMQ_C_VER} && \
    mkdir -p build && cd build && \
    cmake .. \
    		-DCMAKE_INSTALL_PREFIX=/usr \
    		-DCMAKE_INSTALL_LIBDIR=lib \
    		-DCMAKE_C_FLAGS="$CFLAGS" && \
    cmake --build . --target install && \

    # PECL extensions
    pecl config-set php_ini "$PHP_INI_DIR/php.ini" && \

    pecl install \
{{ range jsonArray (getenv "PECL_EXTENSIONS") }}{{ $name := split . "-" }}
        {{ . }} \{{ end }}
        && \

    docker-php-ext-enable \
{{ range jsonArray (getenv "PECL_EXTENSIONS") }}{{ $name := split . "-" }}
        {{ index $name 0 }} \{{ end }}
        && \

{{ range jsonArray (getenv "GIT_EXTENSIONS") }}
    git clone {{ if .branch }}--branch {{ .branch }}{{ end }} {{ .url }} /usr/src/php/ext/{{ .name }}/ && \
    docker-php-ext-configure {{ .name }} && \
    docker-php-ext-install {{ .name }} && \
{{ end }}

    # Download and install Gotlp
    wget -qO- https://github.com/wodby/gotpl/releases/download/${GOTLP_VER}/gotpl-alpine-linux-amd64-${GOTLP_VER}.tar.gz \
        | tar xz -C /usr/local/bin && \

    # Install composer
    wget -qO- https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \

    # Install composer parallel install plugin
    su-exec www-data composer global require hirak/prestissimo:^0.3 && \

    # Install PHPUnit
    wget -qO- https://phar.phpunit.de/{{ getenv "PHPUNIT" }} > /usr/local/bin/phpunit && \
    chmod +x /usr/local/bin/phpunit && \

    # Install Walter tool
    wget -qO- https://github.com/walter-cd/walter/releases/download/v${WALTER_VER}/walter_${WALTER_VER}_linux_amd64.tar.gz \
        | tar xz -C /tmp/ && \
    mv /tmp/walter_linux_amd64/walter /usr/local/bin && \

    # Create working dir
    mkdir -p $APP_ROOT && \
    chown -R www-data:www-data /var/www && \

    # Disable Xdebug by default
    rm -f $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini && \

    # Update SSHd config
    echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /etc/ssh/ssh_config && \
    sed -i '/PermitUserEnvironment/c\PermitUserEnvironment yes' /etc/ssh/sshd_config && \

    # Add composer bins to $PATH
    su-exec www-data echo "export PATH=/home/www-data/.composer/vendor/bin:$PATH" > /home/www-data/.profile && \

    # Clean up root crontab
    truncate -s 0 /etc/crontabs/root && \

    # Cleanup
    su-exec www-data composer clear-cache && \
    docker-php-source delete && \
    apk del --purge \
        *-dev \
        autoconf \
        build-base \
        cmake \
        libtool && \

    rm -rf \
        /usr/src/php.tar.xz \
        /usr/src/php/ext/memcached \
        /usr/src/php/ext/uploadprogress \
        /usr/include/php \
        /usr/lib/php/build \
        /var/cache/apk/* \
        /tmp/* \
        /root/.composer

ENV PATH "/home/www-data/.composer/vendor/bin:$PATH"

WORKDIR $APP_ROOT
EXPOSE 9000

COPY templates /etc/gotpl/
COPY docker-entrypoint.sh /
COPY actions /usr/local/bin/
COPY php.ini ${PHP_INI_DIR}

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["php-fpm"]
