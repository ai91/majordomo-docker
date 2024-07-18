#!/bin/sh

TODO on first start also restore base installation* (ignoring existing files)
3rdparty
css
objects
pChart
rc
templates_alt
.htaccess
config.php.sample
favicon.ico
index.php
install-linux.sh
LICENSE
obj.bat
README.md
robots.txt

# prepare list of files to be ignored during restoring content
# Note: when existing installation is "broken", then ignore DONT_RESTORE_FILES
#       and restore everything. As a "broken"-indicator - we check absence of cycle.php
echo "" > /tmp/excludes
if [ -f "/var/www/html/cycle.php" ]; then
  if [ -n "$MAJORDOMO_DONT_RESTORE_FILES_FILE" ]; then
    cp $MAJORDOMO_DONT_RESTORE_FILES_FILE /tmp/excludes
    echo "\n" >> /tmp/excludes
  fi
  if [ -n "$MAJORDOMO_DONT_RESTORE_FILES" ]; then
    echo "$MAJORDOMO_DONT_RESTORE_FILES" | tr ',' '\n' >> /tmp/excludes
  fi
fi

if [ -z ${MAJORDOMO_SOFT_RESTORE+x} ]; then
  RSYNC_OPT="";
else
  RSYNC_OPT="--ignore-existing"; 
fi

# Copy content from /var/www/majordomo into /var/www/html
echo "Updating installation directories with default majordomo files"
find /var/www/majordomo/ -type d -exec /bin/sh -c "chmod 777 {} && chown www-data:www-data {}" \;
find /var/www/majordomo/ -type f -exec /bin/sh -c "chmod 666 {} && chown www-data:www-data {}" \;
rsync -a $RSYNC_OPT --include="config.php" --include="db_terminal_init.php" --exclude-from=/tmp/excludes /var/www/majordomo/ /var/www/html/

# initialize db_terminal database if necessary
php /var/www/html/db_terminal_init.php
if [ $? -ne 0 ]; then
    echo "The database initialization script failed to proceed."
    exit 1
fi

# Check if startup script has been passed. If yes, execute it.
if [ -n "$MAJORDOMO_STARTUP_SCRIPT" ]; then
  if [ -f "$MAJORDOMO_STARTUP_SCRIPT" ]; then
    if [ ! -x "$MAJORDOMO_STARTUP_SCRIPT" ]; then
        chmod +x "$MAJORDOMO_STARTUP_SCRIPT"
    fi
    "$MAJORDOMO_STARTUP_SCRIPT"
  fi
fi

# register and start majormodo service
export -p > /root/env.sh
service majordomo start

# finally start apache
/usr/local/bin/apache2-foreground