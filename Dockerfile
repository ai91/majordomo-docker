FROM php:7.4.25-apache

RUN apt update && \
    apt install -y iputils-ping rsync zlib1g-dev libpng-dev && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install sockets && \
    docker-php-ext-install gd && \
    docker-php-ext-enable mysqli && \
    a2enmod rewrite

COPY majordomo.sh /usr/local/bin/

COPY majordomo.init.d /etc/init.d/majordomo

RUN chmod 0755 /etc/init.d/majordomo

RUN mkdir /var/www/majordomo
COPY majordomo /var/www/majordomo/

COPY config-docker.php /var/www/html/config.php
COPY db_terminal_init.php /var/www/html/db_terminal_init.php

CMD ["/bin/sh", "/usr/local/bin/majordomo.sh"]