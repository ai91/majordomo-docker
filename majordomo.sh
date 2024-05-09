#!/bin/sh

# prepare list of files to be ignored during restoring content
echo "" > /tmp/excludes
if [ -n "$MAJORDOMO_DONT_RESTORE_FILES_FILE" ]; then
  cp $MAJORDOMO_DONT_RESTORE_FILES_FILE /tmp/excludes
fi
if [ -n "$MAJORDOMO_DONT_RESTORE_FILES" ]; then
  echo "$MAJORDOMO_DONT_RESTORE_FILES" | tr ',' '\n' >> /tmp/excludes
fi

# append default content from cms
echo "Appending default content of cms directory."
rsync -a --exclude-from=/tmp/excludes /var/www/html/cms.default/ /var/www/html/cms/
find /var/www/html/cms/ -type d -exec /bin/sh -c "chmod 777 {} && chown www-data:www-data {}" \;
find /var/www/html/cms/ -type f -exec /bin/sh -c "chmod 666 {} && chown www-data:www-data {}" \;

# append default content from modules
echo "Appending default content of modules directory."
rsync -a --exclude-from=/tmp/excludes /var/www/html/modules.default/ /var/www/html/modules/
find /var/www/html/modules/ -type d -exec /bin/sh -c "chmod 777 {} && chown www-data:www-data {}" \;
find /var/www/html/modules/ -type f -exec /bin/sh -c "chmod 666 {} && chown www-data:www-data {}" \;

# append default content from scripts
rsync -a --exclude-from=/tmp/excludes /var/www/html/scripts.default/ /var/www/html/scripts/
echo "Appending default content of scripts directory."
find /var/www/html/scripts/ -type d -exec /bin/sh -c "chmod 777 {} && chown www-data:www-data {}" \;
find /var/www/html/scripts/ -type f -exec /bin/sh -c "chmod 666 {} && chown www-data:www-data {}" \;

# initialize db_terminal database if necessary
php /var/www/html/db_terminal_init.php
if [ $? -ne 0 ]; then
    echo "The database initialization script failed to proceed."
    exit 1
fi

# register and start majormodo service
export -p > /root/env.sh
service majordomo start

# finally start apache
/usr/local/bin/apache2-foreground