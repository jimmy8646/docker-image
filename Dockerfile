FROM php:7.1.16-apache

MAINTAINER yujiechueh@gmail.com

# Add Healthcheck
HEALTHCHECK --timeout=30s --interval=30s --retries=10 \
    CMD curl -s --fail http://localhost:80/ || exit 1

RUN a2enmod rewrite

# install the PHP extensions we need
RUN set -ex \
    && buildDeps=' \
    libjpeg62-turbo-dev \
    libpng12-dev \
    libpq-dev \
    ' \
    && apt-get update && apt-get install -y --no-install-recommends $buildDeps && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd \
    --with-jpeg-dir=/usr \
    --with-png-dir=/usr \
    && docker-php-ext-install -j "$(nproc)" gd opcache mbstring pdo pdo_mysql pdo_pgsql zip exif \
    # PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/local/lib/php/extensions/no-debug-non-zts-20151012/gd.so' - libjpeg.so.62: cannot open shared object file: No such file or directory in Unknown on line 0
    # PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/local/lib/php/extensions/no-debug-non-zts-20151012/pdo_pgsql.so' - libpq.so.5: cannot open shared object file: No such file or directory in Unknown on line 0
    && apt-mark manual \
    libjpeg62-turbo \
    libpq5 \
    && apt-get purge -y --auto-remove $buildDeps

# Install openssh && nano && supervisor && git
RUN apt-get update && apt-get install -y openssh-server nano supervisor git
RUN export TERM=xterm

# Install mysql-clients && rsync. In order to sync database with the container
RUN apt-get install -y rsync mysql-client

# Install Composer In order to use compose
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# ADD Configuration to the Container
ADD conf/supervisord.conf /etc/supervisord.conf
ADD conf/apache2.conf /etc/apache2/apache2.conf
ADD conf/000-default.conf /etc/apache2/sites-available/000-default.conf
ADD conf/php.ini /usr/local/etc/php/

# Add Scripts
ADD scripts/start.sh /start.sh
RUN chmod 755 /start.sh

EXPOSE 443 80

CMD ["/start.sh"]