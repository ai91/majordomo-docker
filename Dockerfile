#FROM ubuntu:22.04
FROM php:7.4.25-apache

RUN apk add --no-cache mysql-client

COPY majordomo.sh /usr/local/bin/

COPY majordomo /var/www/html

COPY config-docker.php /var/www/html/config.php

CMD ["/bin/sh", "/usr/local/bin/majordomo.sh"]