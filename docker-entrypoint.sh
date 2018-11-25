#!/usr/bin/env bash

set -o nounset
set -o pipefail

# Make sure we always have a healthcheck URL variable empty unless specified
: ${RCLONE_CROND_HEALTHCHECK_URL:=""}

#---------------------------------------------------------------------
# configure crond
#---------------------------------------------------------------------

function crond() {

if [[ -f ${RCLONE_CRONFILE} ]]; then

  # If using your own cron config, use that now else we create one for you
   RCLONE_CRONFILE=/cron/crontab.conf
   export RCLONE_CRONFILE

  else

  # For the use of /rclone.sh and crond

  if [[ -n "${RCLONE_CROND_SOURCE_PATH:-}" ]] || [[ -n "${RCLONE_CROND_DESTINATION_PATH:-}" ]]; then

    if [[ ! -f /cron/rclone.env ]]; then exit 1; fi
    if [[ ! -d /cron ]]; then mkdir -p /cron; fi

    # Set a default if a schedule is not present
    if [[ -z "${RCLONE_CROND_SCHEDULE:-}" ]]; then RCLONE_CROND_SCHEDULE="0 0 * * *" && export RCLONE_CROND_SCHEDULE; fi

    if [[ ! -z ${RCLONE_CROND_SOURCE_SIZE} ]]; then
      {
        echo 'check program foldersize with path "/bin/bash -c '/rclone.sh foldersize'"'
        echo '    if status != 0 for 2 cycles then exec "/usr/bin/env bash -c '/rclone.sh run'"'
      } | tee /etc/monit.d/check_foldersize
    fi

    if [[ -z ${RCLONE_CROND_HEALTHCHECK_URL:-} ]]; then
      {
        echo 'SHELL=/bin/bash'
        echo 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
        echo '{{RCLONE_CROND_SCHEDULE}} /usr/bin/env bash -c "/rclone.sh run" 2>&1'
      } | tee ${RCLONE_CRONFILE}

      sed -i 's|{{RCLONE_CROND_SCHEDULE}}|'"${RCLONE_CROND_SCHEDULE}"'|g' ${RCLONE_CRONFILE}
    else
      {
        echo 'SHELL=/bin/bash'
        echo 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
        echo '{{RCLONE_CROND_SCHEDULE}} /usr/bin/env bash -c "/rclone.sh run" && curl -fsS --retry 3'
        echo '{{RCLONE_CROND_HEALTHCHECK_URL}} > /dev/null'
      } | tee ${RCLONE_CRONFILE}

      sed -i 's|{{RCLONE_CROND_SCHEDULE}}|'"${RCLONE_CROND_SCHEDULE}"'|g' ${RCLONE_CRONFILE}
      sed -i 's|{{RCLONE_CROND_HEALTHCHECK_URL}}|'"${RCLONE_CROND_HEALTHCHECK_URL}"'|g' ${RCLONE_CRONFILE}
    fi

    if [[ ! -f ${RCLONE_CRONFILE} ]]; then exit 1; fi

  fi
fi

# Load crontab config and start RCLONE_CROND_DESTINATION_PATH
if [[ -f ${RCLONE_CRONFILE} ]]; then cat ${RCLONE_CRONFILE} | crontab - && crontab -l && runcrond="crond -b" && bash -c "${runcrond}"; fi

}

#---------------------------------------------------------------------
# configure monit
#---------------------------------------------------------------------

function monit() {

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
run="monit -c /etc/monitrc" && bash -c "${run}"

}

#---------------------------------------------------------------------
# run services
#---------------------------------------------------------------------

function run() {

if [[ ! -z "${RCLONE_CROND_SCHEDULE:-}" ]] || [[ ! -z "${RCLONE_CRONFILE:-}" ]]; then crond && monit; fi

}

run
exec "$@"
