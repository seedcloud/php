#!/usr/bin/env bash

set -ex

array=("5.3", "5.6", "7.0", "7.1")

export BASE_IMAGE=$(wget -qO- https://raw.githubusercontent.com/docker-library/php/master/7.1/alpine/Dockerfile)

packages=(
    "bash",
    "bzip2",
    "ca-certificates",
    "c-client",
    "git",
    "gzip",
    "icu-libs",
    "imagemagick",
    "imap",
    "libbz2",
    "libjpeg-turbo",
    "libmcrypt",
    "libpng",
    "libxslt",
    "make",
    "mariadb-client",
    "libmemcached-libs",
    "openssh",
    "openssh-client",
    "openssl",
    "patch",
    "postgresql-client",
    "rsync",
    "su-exec",
    "tar",
    "wget",
    "yaml"
)

buildPackages=(
    "autoconf",
    "cmake",
    "build-base",
    "bzip2-dev",
    "freetype-dev",
    "icu-dev",
    "imagemagick-dev",
    "imap-dev",
    "jpeg-dev",
    "libjpeg-turbo-dev",
    "libmemcached-dev",
    "libmcrypt-dev",
    "libpng-dev",
    "libtool",
    "libxslt-dev",
    "openldap-dev",
    "pcre-dev",
    "postgresql-dev",
    "yaml-dev"
)

extensions=(
    "bcmath",
    "bz2",
    "calendar",
    "exif",
    "imap",
    "intl",
    "ldap",
    "mcrypt",
    "mysqli",
    "opcache",
    "pdo_mysql",
    "pdo_pgsql",
    "pgsql",
    "phar",
    "soap",
    "sockets",
    "xmlrpc",
    "xsl",
    "zip"
)

peclExtensions=(
    "amqp",
    "apcu",
    "oauth",
    "imagick",
    "mongodb",
    "redis",
    "xdebug-2.5.1",
    "yaml-2.0.0",
    "amqp",
    "apcu",
    "oauth",
    "imagick",
    "mongodb",
    "redis",
    "xdebug",
    "yaml"
)

export GIT_EXTENSIONS='[
    {
        "url": "https://github.com/php/pecl-php-uploadprogress",
        "name": "uploadprogress"
    },
    {
        "url": "https://github.com/php-memcached-dev/php-memcached",
        "name": "memcached",
        "branch": "php7"
    },
    {
        "url": "https://github.com/nikic/php-ast",
        "name": "ast"
    }
]'

gotpl Dockerfile.tpl > Dockerfile
