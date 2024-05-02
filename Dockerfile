#FROM ubuntu:22.04
FROM php:7.4.25-apache

COPY majordomo /var/www/html

COPY config-docker.php /var/www/html/config.php