#!/usr/bin/env bash

set -o nounset
set -o pipefail

function crond() {

if [[ -n "$RCLONE_CROND_SOURCE_PATH" ]] || [[ -n "$RCLONE_CROND_DESTINATION_PATH" ]]; then

echo "OK: Source and destination environment variables for rclone and crond are present. Configuring..."

# Create the environment file for crond
if [[ ! -d /cron ]]; then mkdir -p /cron;fi

# Create the environment file for crond
printenv | sed 's/^\([a-zA-Z0-9_]*\)=\(.*\)$/export \1="\2"/g' | grep -E "^export RCLONE" > /cron/rclone.env

if [[ -f /cron/rclone.env ]]; then echo "OK: The rclone ENV file is present. Continuing..."; else echo "ERROR: The rclone ENV is missing. Please check your config file" && exit 1; fi

# Set a default if a schedule is not present
if [[ -z "$RCLONE_CROND_SCHEDULE" ]]; then export RCLONE_CROND_SCHEDULE="0 0 * * *"; fi
if [[ -z $RCLONE_CROND_HEALTHCHECK_URL ]]; then
echo "OK: Setting the crontab file now..."
cat << EOF > /cron/crontab.conf
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
${RCLONE_CROND_SCHEDULE} /usr/bin/env bash -c /rclone.sh 2>&1
EOF
else
echo "OK: Setting the crontab file with healthchecks now..."
cat << EOF > /cron/crontab.conf
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
${RCLONE_CROND_SCHEDULE} /usr/bin/env bash -c /rclone.sh && curl -fsS --retry 3 ${RCLONE_CROND_HEALTHCHECK_URL} > /dev/null
EOF
fi

if [[ -f /cron/crontab.conf ]]; then echo "OK: The crond config is present. Continuing..."; else echo "ERROR: crond config is missing. Please check your crond settings" && exit 1; fi

# Add the crond config
cat /cron/crontab.conf | crontab - && crontab -l
# Start crond
runcrond="crond -b" && bash -c "${runcrond}"

else

echo "INFO: There is no CROND configs present. Skipping use of CROND"

fi

}

function monit() {

# Start Monit
cat << EOF > /etc/monitrc
set daemon 10
set pidfile /var/run/monit.pid
set statefile /tmp/monit.state
set httpd port 2849 and
    use address localhost
    allow localhost
set logfile syslog
set eventqueue
    basedir /var/run
    slots 100
include /etc/monit.d/*
EOF

chmod 700 /etc/monitrc
run="monit -c /etc/monitrc" && bash -c "${run}"

}

function run() {
crond
monit
echo "OK: All processes have completed. rclone service is starting..."
}

run
exec "$@"
