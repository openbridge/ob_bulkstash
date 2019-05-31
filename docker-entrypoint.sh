#!/usr/bin/env bash

set -o nounset
set -o pipefail

# Make sure we always have a healthcheck URL variable empty unless specified
: ${RCLONE_CROND_HEALTHCHECK_URL:=""}

#---------------------------------------------------------------------
# configure crond
#---------------------------------------------------------------------

function crond() {

# Create the environment file for crond
if [[ -n "${RCLONE_CRONFILE:-}" ]] || [[ -n "${RCLONE_SYNC_COMMAND:-}" ]]; then

    echo "OK CRON It is"
    if [[ ! -d /cron ]]; then mkdir -p /cron;fi

    RCLONE_CRONFILE=/cron/crontab.conf
    # If using your own cron config, use that now else we create one for you
    export RCLONE_CRONFILE

    printenv | sed 's/^\([a-zA-Z0-9_]*\)=\(.*\)$/export \1="\2"/g' | grep -E "^export RCLONE" > /cron/rclone.env

    if [[ -f /cron/rclone.env ]]; then echo "OK: The you set CROND to run. A ENV file was created here /cron/rclone.env. Continuing..."; else echo "ERROR: The CROND ENV is missing even though you want to run CROND. Please check your config file"; fi

fi


if [[ -n "${RCLONE_SYNC_COMMAND:-}" ]]; then
    echo "INFO: RCLONE_CROND_SCHEDULE variable is present. Generating ${RCLONE_CRONFILE}..."
      {
        echo 'SHELL=/bin/bash'
        echo 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
        echo '{{RCLONE_SYNC_COMMAND}}'
      } | tee ${RCLONE_CRONFILE}

      sed -i 's|{{RCLONE_SYNC_COMMAND}}|'"${RCLONE_SYNC_COMMAND}"'|g' ${RCLONE_CRONFILE}

      if [[ ! -f ${RCLONE_CRONFILE} ]]; then exit 1; fi
fi

# Add the crond config
cat /cron/crontab.conf | crontab - && crontab -l

}

#---------------------------------------------------------------------
# configure monit
#---------------------------------------------------------------------

function monit() {

  if [[ ! -z ${RCLONE_CROND_SOURCE_SIZE:-} ]]; then
    {
      echo 'check program foldersize with path "/bin/bash -c '/rclone.sh foldersize'"'
      echo '    if status != 0 for 2 cycles then exec "/usr/bin/env bash -c '/rclone.sh run'"'
    } | tee /etc/monit.d/check_foldersize
  fi

  # Create monit config
  {
      echo 'set daemon 10'
      echo 'set pidfile /var/run/monit.pid'
      echo 'set statefile /var/run/monit.state'
      echo 'set httpd port 2849 and'
      echo '    use address localhost'
      echo '    allow localhost'
      echo 'set logfile syslog'
      echo 'set eventqueue'
      echo '    basedir /var/run'
      echo '    slots 100'
      echo 'include /etc/monit.d/*'

  } | tee /etc/monitrc

chmod 700 /etc/monitrc

}

#---------------------------------------------------------------------
# run services
#---------------------------------------------------------------------

function run() {

if [[ ! -z "${RCLONE_SYNC_COMMAND:-}" ]] || [[ ! -z "${RCLONE_CRONFILE:-}" ]]; then crond && monit; fi

}

run
exec "$@"
