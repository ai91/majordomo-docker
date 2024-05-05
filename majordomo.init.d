#!/bin/sh
### BEGIN INIT INFO
# Provides: SmartLiving
# Required-Start:    $remote_fs $syslog apache2
# Required-Stop:     $remote_fs $syslog apache2
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO

dir="/var/www/html/"
user="root"
cmd="php /var/www/html/cycle.php"

name='majordomo'
pid_file="/var/run/$name.pid"
stdout_log="/var/log/$name.log"
stderr_log="/var/log/$name.err"

get_pid() {
    cat "$pid_file"
}

is_running() {
    [ -f "$pid_file" ] && ps `get_pid` > /dev/null 2>&1
}

case "$1" in
    start)
    if is_running; then
        echo "Already started"
    else
        echo "Starting $name"
        cd "$dir"

. /root/env.sh

(while true; do
    $cmd
done)>> "$stdout_log" 2>> "$stderr_log" &

        echo $! > "$pid_file"
        if ! is_running; then
            echo "Unable to start, see $stdout_log and $stderr_log"
            exit 1
        fi
    fi
    ;;
    stop)
    if is_running; then
        echo -n "Stopping MajorDoMo $name.."
        touch /var/www/html/reboot
        chown www-data:www-data /var/www/html/reboot
        chmod 666 /var/www/html/reboot
       # wait until file deleted, but not longer than  5 minutes
        t=0
        while [  "$t" -lt 60 -a -e /var/www/html/reboot ]; do
          t=$((t+1))
          sleep 5
        done
        kill `get_pid`
        pkill php
        for i in {1..10}
        do
            if ! is_running; then
                break
            fi

            echo -n "."
            sleep 1
        done
        echo

        if is_running; then
            echo "Not stopped; may still be shutting down or shutdown may have failed"
            exit 1
        else
            echo "Stopped"
            if [ -f "$pid_file" ]; then
                rm "$pid_file"
            fi
        fi
    else
        echo "Not running"
        pkill php
    fi
    ;;
    restart)
    $0 stop
    if is_running; then
        echo "Unable to stop, will not attempt to start"
        exit 1
    fi
    $0 start
    ;;
    status)
    if is_running; then
        echo "Running"
    else
        echo "Stopped"
        exit 1
    fi
    ;;
    *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac

exit 0