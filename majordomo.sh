#!/bin/sh

# check if /var/www/html/cms is empty
if [ -z "$(ls -A /var/www/html/cms)" ]; then
    # If empty, copy contents from /var/www/html/cms.default
    echo "cms directory is empty. Copying default content"
    cp -r /var/www/html/cms.default/* /var/www/html/cms/
    find /var/www/html/cms/ -type d -exec /bin/sh -c "chmod 777 {} && chown www-data:www-data {}" \;
    find /var/www/html/cms/ -type f -exec /bin/sh -c "chmod 666 {} && chown www-data:www-data {}" \;
fi

# check if /var/www/html/modules is empty
if [ -z "$(ls -A /var/www/html/modules)" ]; then
    # If empty, copy contents from /var/www/html/modules.default
    echo "modules directory is empty. Copying default content"
    cp -r /var/www/html/modules.default/* /var/www/html/modules/
    find /var/www/html/modules/ -type d -exec /bin/sh -c "chmod 777 {} && chown www-data:www-data {}" \;
    find /var/www/html/modules/ -type f -exec /bin/sh -c "chmod 666 {} && chown www-data:www-data {}" \;
fi

php /var/www/html/db_terminal_init.php

export -p > /root/env.sh
service majordomo start

/usr/local/bin/apache2-foreground