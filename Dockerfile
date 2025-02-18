FROM php:8.3-cli
LABEL maintainer=dubovsky@plzen.eu

ARG timezone=Europe/Prague
ENV TIMEZONE=$timezone
ENV ACCEPT_EULA=Y
ENV DEBIAN_FRONTEND=noninteractive

# Install PHP extensions and PECL modules.
RUN BUILDDEPS=" \
        default-libmysqlclient-dev \
        libbz2-dev \
        libmemcached-dev \
        libsasl2-dev \
    " \
    RUNTIMEDEPS=" \
        apt-utils \
        gnupg2 \
        git \
        gzip \
        lftp \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libldap2-dev \
        libmemcachedutil2 \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
        libonig-dev \
        msmtp \
	    zip \
        npm \
    " \
    && apt-get update && apt install -y $BUILDDEPS $RUNTIMEDEPS \
    && docker-php-ext-install \
        bcmath \
        bz2 \
        calendar \
        iconv \
        intl \
        mbstring \
        mysqli \
        opcache \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        soap \
        zip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install ldap \
    && docker-php-ext-install exif \
    && pecl install memcached redis \
    && docker-php-ext-enable memcached.so redis.so \

    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/*\
    && rm -rf /var/cache/apt/*

# Match system timezone and set up PHP
RUN rm /etc/localtime \
    && ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "$TIMEZONE" > /etc/timezone
COPY php.ini /usr/local/etc/php/
RUN echo "date.timezone = $TIMEZONE" >> /usr/local/etc/php/php.ini
RUN echo "TLS_REQCERT never" > /etc/ldap/ldap.conf

# Lower the built-in OS TLS requirements
RUN sed -i -E 's/(CipherString\s*=\s*DEFAULT@SECLEVEL=)2/\11/' /etc/ssl/openssl.cnf && sed -i -E 's/(MinProtocol\s*=\s*TLSv1.)2/\10/' /etc/ssl/openssl.cnf

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && ln -s $(composer config --global home) /root/composer
ENV PATH=$PATH:/root/composer/vendor/bin COMPOSER_ALLOW_SUPERUSER=1
## Prestissimo is obsolete with Composer 2.0
# RUN composer global require hirak/prestissimo


COPY deploy-nette-ftp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/deploy-nette-ftp.sh
COPY replace-symlinks.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/replace-symlinks.sh
COPY templater /usr/local/bin/
RUN chmod +x /usr/local/bin/templater
COPY sshx /usr/local/bin/
RUN chmod +x /usr/local/bin/sshx
COPY scpx /usr/local/bin/
RUN chmod +x /usr/local/bin/scpx
COPY rsyncx /usr/local/bin/
RUN chmod +x /usr/local/bin/rsyncx



WORKDIR /app
