#!/usr/bin/env bash

function background {

  # Start crond as a background process
  runcrond="crond -b" && bash -c "${runcrond}"

  # Start monit process to monitor crond
  monit -Iv -c /etc/monitrc -l /dev/null

}

function start() {
      background
}

"$@"
