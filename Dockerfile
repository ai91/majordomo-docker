#FROM ubuntu:22.04
FROM php:7.4.25-apache

RUN docker-php-ext-install mysqli && docker-php-ext-install sockets && docker-php-ext-enable mysqli && a2enmod rewrite

COPY majordomo.sh /usr/local/bin/

COPY majordomo.init.d /etc/init.d/majordomo

RUN chmod 0755 /etc/init.d/majordomo

COPY majordomo /var/www/html

COPY config-docker.php /var/www/html/config.php
COPY db_terminal_init.php /var/www/html/db_terminal_init.php

CMD ["/bin/sh", "/usr/local/bin/majordomo.sh"]