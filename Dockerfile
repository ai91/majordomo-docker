FROM php:7.4.25-apache

RUN apt update && \
    apt install -y iputils-ping rsync zlib1g-dev libpng-dev

RUN docker-php-ext-install mysqli && \
    docker-php-ext-install sockets && \
    docker-php-ext-install gd && \
    docker-php-ext-enable mysqli && \
    a2enmod rewrite

COPY majordomo.sh /usr/local/bin/

COPY majordomo.init.d /etc/init.d/majordomo

RUN chmod 0755 /etc/init.d/majordomo

COPY majordomo /var/www/html

RUN mkdir /var/www/html/default_distribution && \
    mv /var/www/html/cms /var/www/html/default_distribution/cms && mkdir /var/www/html/cms && \
    mv /var/www/html/modules /var/www/html/default_distribution/modules && mkdir /var/www/html/modules && \
    mv /var/www/html/scripts /var/www/html/default_distribution/scripts && mkdir /var/www/html/scripts && \
    mv /var/www/html/templates /var/www/html/default_distribution/templates && mkdir /var/www/html/templates

COPY config-docker.php /var/www/html/config.php
COPY db_terminal_init.php /var/www/html/db_terminal_init.php

CMD ["/bin/sh", "/usr/local/bin/majordomo.sh"]