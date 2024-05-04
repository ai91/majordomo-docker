#FROM ubuntu:22.04
FROM php:7.4.25-apache

RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli

COPY majordomo.sh /usr/local/bin/

COPY majordomo /var/www/html

COPY config-docker.php /var/www/html/config.php
COPY db_terminal_init.php /var/www/html/db_terminal_init.php

CMD ["/bin/sh", "/usr/local/bin/majordomo.sh"]