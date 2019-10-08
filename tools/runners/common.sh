#!/usr/bin/env bash

logf() { log "$@" | tee >(sed "s/\x1b[^m]*m//g" >> ${REPORT_PATH_TS}/${REPORT_FILE}); }

status() {
  logf "TOTAL: " $ID
  logf "${P}PASSED: " ${#LIST_PASSED[@]} "${N}"
  # for i in ${LIST_PASSED[@]}; do logf "${i//|/ }"; done
  logf "${F}FAILED: " ${#LIST_FAILED[@]} "${N}"
  for i in ${LIST_FAILED[@]}; do logf "${i//|/ }"; done
  logf "${A}ABORTED: " ${#LIST_ABORTED[@]} "${N}"
  for i in ${LIST_ABORTED[@]}; do logf "${i//|/ }"; done
  logf "${S}SKIPPED: " ${#LIST_SKIPPED[@]} "${N}"
  for i in ${LIST_SKIPPED[@]}; do logf "${i//|/ }"; done
  logf ${LINE}
  log
}

log_test_run_details() {
  logf ${LINE}
  logf "SDL: " $SDL_CORE
  logf "Test target: " $TEST_TARGET
  logf ${LINE}
}

process() {
  ID=0
  local EXT=${TEST_TARGET: -3}
  if [ $EXT = "txt" ]; then
    while read -r ROW; do
      if [ ${ROW:0:1} = ";" ]; then continue; fi
      local script=$(echo $ROW | awk '{print $1}')
      local issue=$(echo $ROW | awk '{print $2}')
      local total_num_of_scripts=$(cat $TEST_TARGET | egrep -v -c '^;')
      run $script $total_num_of_scripts $issue
    done < "$TEST_TARGET"
  elif [ $EXT = "lua" ]; then
    run $TEST_TARGET 1
  else
    local LIST=($(find $TEST_TARGET -iname "[0-9]*.lua" | sort))
    for ROW in ${LIST[@]}; do
      run $ROW ${#LIST[@]}
    done
  fi
  log ${LINE}
}

run() {
  local SCRIPT=$1
  local NUM_OF_SCRIPTS=$2
  local ISSUE=$3

  log ${LINE}

  let ID=ID+1

  log "Processing script: ${ID}(${NUM_OF_SCRIPTS}) ["\
    "${P}PASSED: ${#LIST_PASSED[@]}, "\
    "${F}FAILED: ${#LIST_FAILED[@]}, "\
    "${A}ABORTED: ${#LIST_ABORTED[@]}, "\
    "${S}SKIPPED: ${#LIST_SKIPPED[@]}"\
    "${N}]"

  kill_sdl

  clean

  clean_atf_logs

  restore

  local ID_SFX=$(printf "%0${#NUM_OF_SCRIPTS}d" $ID)

  REPORT_PATH_TS_SCRIPT=${REPORT_PATH_TS}/${ID_SFX}
  mkdir ${REPORT_PATH_TS_SCRIPT}

  local OPTIONS="--sdl-core=${SDL_CORE} --report-path=${REPORT_PATH} $OPTIONS"
  dbg "OPTIONS: "$OPTIONS

  ./bin/interp modules/launch.lua \
    $SCRIPT \
    $OPTIONS \
    | tee >(sed "s/\x1b[^m]*m//g" > ${REPORT_PATH_TS_SCRIPT}/${REPORT_FILE_CONSOLE})

  local RESULT_CODE=${PIPESTATUS[0]}
  local RESULT_STATUS="NOT_DEFINED"

  case "${RESULT_CODE}" in
    0)
      RESULT_STATUS="PASSED"
      LIST_PASSED[ID]="$ID_SFX|$SCRIPT|$ISSUE"
    ;;
    1)
      RESULT_STATUS="ABORTED"
      LIST_ABORTED[ID]="$ID_SFX|$SCRIPT|$ISSUE"
    ;;
    2)
      RESULT_STATUS="FAILED"
      LIST_FAILED[ID]="$ID_SFX|$SCRIPT|$ISSUE"
    ;;
    4)
      RESULT_STATUS="SKIPPED"
      LIST_SKIPPED[ID]="$ID_SFX|$SCRIPT|$ISSUE"
    ;;
  esac

  log "SCRIPT STATUS: " ${RESULT_STATUS}

  kill_sdl

  copy_logs

  clean_atf_logs

  log
}

clean_atf_logs() {
  local REPORT_DIR_PTRNS=("SDLLogs*" "ATFLogs*" "XMLReports*")
  for DIR in ${REPORT_DIR_PTRNS[@]}; do
    rm -rf ${REPORT_PATH}/$DIR
  done
}

clean() {
  log "Cleaning up ATF folder"
  for FILE in ${ATF_CLEAN_UP[*]}; do rm -rf ${ATF_PATH}/${FILE}; done
  log "Cleaning up SDL folder"
  for FILE in ${SDL_CLEAN_UP[*]}; do rm -rf ${SDL_CORE}/${FILE}; done
}

copy_logs() {
  local REPORT_DIR_PTRNS=("SDLLogs*" "ATFLogs*" "XMLReports*")
  for PTRN in ${REPORT_DIR_PTRNS[@]}; do
    for DIR in $(find ${REPORT_PATH} -name "$PTRN"); do
      for FILE in $(find $DIR -type f); do
        cp $FILE ${REPORT_PATH_TS_SCRIPT}/
      done
    done
  done
  local SDL_LOG=$SDL_CORE/SmartDeviceLinkCore.log
  if [ -f $SDL_LOG ]; then
    cp $SDL_LOG ${REPORT_PATH_TS_SCRIPT}/
  fi
}

kill_sdl() {
  local PIDS=$(ps -ao user:20,pid,command | grep -e "^$(whoami).*$SDL_PROCESS_NAME" | grep -v grep | awk '{print $2}')
  for PID in $PIDS
  do
    local PID_INFO=$(pstree -sg $PID | head -n 1 | grep -vE "docker|containerd")
    if [ ! -z "$PID_INFO" ]; then
      log "'$SDL_PROCESS_NAME' is running, PID: $PID, terminating ..."
      kill -s SIGTERM $PID
      await $PID 5
      log "Done"
    fi
  done
}

await() {
  local PID=$1
  local TIMEOUT=$2
  local TIME_LEFT=0
  while true
  do
    if ! ps -p $PID > /dev/null; then
      return 0
    fi
    if [ $TIME_LEFT -lt $TIMEOUT ]; then
      let TIME_LEFT=TIME_LEFT+1
      sleep 1
    else
      echo "Timeout ($TIMEOUT sec) expired. Force killing: ${PID} ..."
      kill -s SIGKILL ${PID}
      sleep 0.5
      return 0
    fi
  done
}

ctrl_c() {
  echo "Scripts processing is cancelled"
  kill_sdl
  copy_logs
  clean_atf_logs
  restore
  clean_backup
  status
  exit 1
}

function StartUp() {
    trap ctrl_c INT

    log_test_run_details
}

function Run() {
    process
}

function TearDown() {
    status
}
