#!/bin/sh

# check if /var/www/html/cms is empty
if [ -z "$(ls -A /var/www/html/cms)" ]; then
    # If empty, copy contents from /var/www/html/cms.default
    echo "cms directory is empty. Copying default content"
    cp -r /var/www/html/cms.default/* /var/www/html/cms/
fi

docker-php-entrypoint