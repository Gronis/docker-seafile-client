#!/bin/bash

set -e
set -u
set -o pipefail

DATA_DIR="${DATA_DIR:-/data}"
SEAFILE_UID="${SEAFILE_UID:-1000}"
SEAFILE_GID="${SEAFILE_GID:-1000}"
SEAFILE_UMASK="${SEAFILE_UMASK:-022}"
CONNECT_RETRIES="${CONNECT_RETRIES:-5}"
DISABLE_VERIFY_CERTIFICATE="${DISABLE_VERIFY_CERTIFICATE:-false}"

start_seafile(){
  retries="${CONNECT_RETRIES}"
  count=0
  set +e
  su - seafile -c "seaf-cli start"
  su - seafile -c "seaf-cli config -k disable_verify_certificate -v $DISABLE_VERIFY_CERTIFICATE"
  while :
  do
    su - seafile -c "seaf-cli status"
    exit=$?
    wait=$((2 ** $count))
    count=$(($count + 1))
    if [ $exit -eq 0 ]; then
      echo "exiting"
      return 0
    fi
    if [ $count -lt $retries ]; then
      echo "Retry $count/$retries exited $exit, retrying in $wait seconds..."
      sleep $wait
    else
      echo "Retry $count/$retries exited $exit, no more retries left."
      return $exit
    fi
  done
  set -e
  return 0
}

get () {
    NAME="$1"
    JSON="$2"
    # Tries to regex setting name from config. Only works with strings for now
    echo $JSON | grep -Po '"'"$NAME"'"\s*:\s*.*?[^\\]"+,*' | sed -n -e 's/.*: *"\(.*\)",*/\1/p'
}

setup_lib_sync(){
    if [ ! -d $DATA_DIR ]; then
      echo "Using new data directory: $DATA_DIR"
      mkdir -p $DATA_DIR
      chown seafile:seafile -R $DATA_DIR
    fi
    TOKEN_JSON=$(curl -d "username=$USERNAME" -d "password=$PASSWORD" ${SERVER_URL}:${SERVER_PORT}/api2/auth-token/ 2> /dev/null)
    TOKEN=$(get token "$TOKEN_JSON")
    if [ "$TOKEN" == "" ]; then
      echo "Unable to get token. Check your user credentials, server url and server port."
      return
    fi
    LIBS_IN_SYNC=$(su - seafile -c 'seaf-cli list')
    LIBS=(${LIBRARY_ID//:/ })
    for i in "${!LIBS[@]}"
    do
      LIB="${LIBS[i]}"
      LIB_JSON=$(curl -G -H "Authorization: Token $TOKEN" -H 'Accept: application/json; indent=4' ${SERVER_URL}:${SERVER_PORT}/api2/repos/${LIB}/ 2> /dev/null)
      LIB_NAME=$(get name "$LIB_JSON")
      LIB_NAME_NO_SPACE=$(echo $LIB_NAME|sed 's/[ \(\)]/_/g')
      LIB_DIR=${DATA_DIR}/${LIB_NAME_NO_SPACE}
      set +e
      LIB_IN_SYNC=$(echo "$LIBS_IN_SYNC" | grep "$LIB")
      set -e
      if [ ${#LIB_IN_SYNC} -eq 0 ]; then
        echo "Syncing $LIB_NAME"
        mkdir -p $LIB_DIR
        chown seafile:seafile -R $LIB_DIR
        su - seafile -c "seaf-cli sync -l \"\"$LIB\"\" -s \"${SERVER_URL}:${SERVER_PORT}\" -d \"$LIB_DIR\" -u \"$USERNAME\" -p \"$PASSWORD\""
      fi
    done
}

setup_uid(){
    # Setup umask
    umask "${SEAFILE_UMASK}"
    # Setup user id
    if [ ! "$(id -u seafile)" -eq "${SEAFILE_UID}" ]; then
        # Change the SEAFILE_UID
        usermod -o -u "${SEAFILE_UID}" seafile
    fi
    # Setup group id
    if [ ! "$(id -g seafile)" -eq "${SEAFILE_GID}" ]; then
        # Change the SEAFILE_UID
        groupmod -o -g "${SEAFILE_GID}" seafile
    fi
    id seafile
    echo "UID='${SEAFILE_UID}' GID='${SEAFILE_GID}'"
}

keep_in_foreground() {
  # As there seems to be no way to let Seafile processes run in the foreground we
  # need a foreground process. This has a dual use as a supervisor script because
  # as soon as one process is not running, the command returns an exit code >0
  # leading to a script abortion thanks to "set -e".
  while true
  do
    for SEAFILE_PROC in "ccnet" "seaf-daemon"
    do
      pkill -0 -f "${SEAFILE_PROC}"
      sleep 1
    done
    date +"%Y-%m-%d %H:%M:%S"
    su - seafile -c "seaf-cli status"
    sleep 60
  done
}

setup_uid
start_seafile
setup_lib_sync
keep_in_foreground
