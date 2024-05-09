FROM php:7.4.25-apache

RUN docker-php-ext-install mysqli && docker-php-ext-install sockets && docker-php-ext-enable mysqli && a2enmod rewrite

RUN apt update && apt install -y iputils-ping rsync

COPY majordomo.sh /usr/local/bin/

COPY majordomo.init.d /etc/init.d/majordomo

RUN chmod 0755 /etc/init.d/majordomo

COPY majordomo /var/www/html

RUN mv /var/www/html/cms /var/www/html/default_distribution/ && mkdir /var/www/html/cms && \
    mv /var/www/html/modules /var/www/html/default_distribution/ && mkdir /var/www/html/modules && \
    mv /var/www/html/scripts /var/www/html/default_distribution/ && mkdir /var/www/html/scripts

COPY config-docker.php /var/www/html/config.php
COPY db_terminal_init.php /var/www/html/db_terminal_init.php

CMD ["/bin/sh", "/usr/local/bin/majordomo.sh"]