#!/usr/bin/env bash

# Get the env variables so crond has them
source /cron/rclone.env

function check {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "An rclone error with $1 occured" >&2
    else
      # Send the payload to the API
      if [[ -z $RCLONE_CROND_HEALTHCHECK_URL ]]; then
         echo "INFO: A health check has not been set. Not using health check services"
      else
         echo "OK: All tests passed, sending message to API..."
         POST=$(curl -s -S "$RCLONE_CROND_HEALTHCHECK_URL");
         # Check if the message posted to the API. It should return "ok". Anything other than "ok" indicates an issue
         if test "${POST}" != OK; then echo "ERROR: The check to the API failed (${POST})" && return 1; else echo "OK: Message successfully sent to the health check"; fi
      fi
    fi
    return $status
}

function rclone {
(
  flock -n 200 || exit 1
  sync_command="rclone copy ${RCLONE_CROND_SOURCE_PATH} ${RCLONE_CROND_DESTINATION_PATH}"
  if [ "$RCLONE_SYNC_COMMAND" ]; then
  sync_command="$RCLONE_SYNC_COMMAND"
  else
    if [[ -z "$RCLONE_CROND_SOURCE_PATH" ]] || [[ -z "$RCLONE_CROND_DESTINATION_PATH" ]]; then
      echo "Error: A RCLONE PATH environment variable was not set or passed to the container. Please review your RCLONE source/destination paths."
      exit 1
    fi
  fi
  echo "Executing => $sync_command"
  eval "$sync_command" || send
) 200>/tmp/rclone.lock
}

function run() {
      check $rclone
      echo "OK: All rclone tasks have completed."
}

run
