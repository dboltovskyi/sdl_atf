#!/usr/bin/env bash

ATF_PATH=$(cd "$(dirname "$0")" && pwd)
REPORT_FILE=Report.txt
REPORT_FILE_CONSOLE=Console.txt
SDL_PROCESS_NAME="smartDeviceLinkCore"
DEBUG=false
LINE="====================================================================================================="

JOBS=1
FORCE_PARALLELS=false
FORCE_REMOTE=false

THIRD_PARTY="$THIRD_PARTY_INSTALL_PREFIX"
ATF_TS_PATH=$(dirname $(realpath test_scripts))
TMP_PATH=/tmp
REPORT_PATH=./TestingReports

# Color modifications
P="\033[0;32m" # GREEN
F="\033[0;31m" # RED
A="\033[0;35m" # MAGENTA
S="\033[0;33m" # YELLOW
N="\033[0m"    # NONE

dbg() { if [ $DEBUG = true ]; then echo "DEBUG: $@"; fi }

log() { echo -e $@; }

show_help() {
  echo "Bash .lua test Script Runner"
  echo
  echo "Usage: start.sh TEST [OPTION]..."
  echo
  echo "TEST - test target, could be one of the following:"
  echo "   - test script"
  echo "   - test set"
  echo "   - folder with test scripts"
  echo "[OPTION] - options supported by ATF:"
  echo "   --sdl-core         - path to SDL binaries"
  echo "   --config           - name of configuration"
  echo "   --sdl-api          - path to SDL APIs"
  echo "   --report           - path to report and logs"
  echo "   --parallels        - force to use parallels mode"
  echo "   -j|--jobs n        - number of jobs to start ATF in parallels"
  echo "   --third-party      - path to SDL third party"
  echo "   --atf-ts           - path to ATF test scripts"
  echo "   --tmp              - path to temporary folder used by parallels"
  echo "   --remote           - force to use remote connection mode"
  echo
  echo "In case if folder is specified as a test target:"
  echo "   - only scripts which name starts with number will be taken into account (e.g. 001, 002 etc.)"
  echo "   - if there are sub-folders scripts will be run recursively"
  echo
  echo "Besides execution of .lua scripts Script Runner also does auxiliary actions:"
  echo "   - clean up SDL and ATF folders before running of each script"
  echo "   - backup and restore SDL important files"
  echo "   - create report with all required logs for each script"
  echo
  exit 0
}

parse_arguments() {
  if [ $# -eq 0 ]; then
    show_help
  fi

  local ARGS=("$@")
  local COUNTER=0
  local NAMELESS_COUNTER=0
  local NAMELESS_ARGS
  while [ $COUNTER -lt $# ]
  do
    local ARG=${ARGS[$COUNTER]}
    let COUNTER=COUNTER+1
    local NEXT_ARG=${ARGS[$COUNTER]}

    if [[ $SKIP_NEXT -eq 1 ]]; then
      SKIP_NEXT=0
      continue
    fi

    local ARG_KEY=""
    local ARG_VAL=""
    if [[ "$ARG" =~ ^\- ]]; then
      # if the format is: -key=value
      if [[ "$ARG" =~ \= ]]; then
        ARG_VAL=$(echo "$ARG" | cut -d'=' -f2)
        ARG_KEY=$(echo "$ARG" | cut -d'=' -f1)
        SKIP_NEXT=0
      # if the format is: -key value
      elif [[ ! "$NEXT_ARG" =~ ^\- ]]; then
        ARG_KEY="$ARG"
        ARG_VAL="$NEXT_ARG"
        SKIP_NEXT=1
      # if the format is: -key (a boolean flag)
      elif [[ "$NEXT_ARG" =~ ^\- ]] || [[ -z "$NEXT_ARG" ]]; then
        ARG_KEY="$ARG"
        ARG_VAL=""
        SKIP_NEXT=0
      fi
    # if the format has not flag, just a value
    else
      ARG_KEY=""
      ARG_VAL="$ARG"
      SKIP_NEXT=0
    fi

    case "$ARG_KEY" in
      --config)
        CONFIG="$ARG_VAL"
      ;;
      --sdl-core)
        SDL_CORE="$ARG_VAL"
      ;;
      --report)
        REPORT_PATH="$ARG_VAL"
      ;;
      --sdl-api)
        SDL_API="$ARG_VAL"
      ;;
      -j|--jobs)
        JOBS="$ARG_VAL"
      ;;
      --third-party)
        THIRD_PARTY="$ARG_VAL"
      ;;
      --atf-ts)
        ATF_TS_PATH="$ARG_VAL"
      ;;
      --parallels)
        FORCE_PARALLELS=true
      ;;
      --tmp)
        TMP_PATH="$ARG_VAL"
      ;;
      --remote)
        FORCE_REMOTE=true
      ;;
      -h|--help|-help|--h)
        show_help
      ;;
      *)
        let NAMELESS_COUNTER=NAMELESS_COUNTER+1
        NAMELESS_ARGS[NAMELESS_COUNTER]="$ARG_VAL"
      ;;
    esac
  done
  # handle nameless arguments
  if [ ${#NAMELESS_ARGS[*]} -eq 1 ]; then
    TEST_TARGET=${NAMELESS_ARGS[1]}
  fi
}

check_arguments() {
  if [ -z $TEST_TARGET ]; then
    echo "Test target was not specified"
    exit 1
  fi
  if [ "${TEST_TARGET: -1}" = "/" ]; then
    TEST_TARGET="${TEST_TARGET:0:-1}"
  fi
  if [ -n "$CONFIG" ] && [ -n "$SDL_CORE" ] ; then
    echo "Invalid options combination: --config and --sdl-core"
    exit 1
  fi
  if [ $FORCE_REMOTE = true ] && [ -n "$SDL_CORE" ] ; then
    echo "Invalid options combination: --remote and --sdl-core"
    exit 1
  fi
  if [ $FORCE_REMOTE = true ] && [ $FORCE_PARALLELS = true ] ; then
    echo "Invalid options combination: --remote and --parallels"
    exit 1
  fi

  OPTIONS=""
  if [ -n "$CONFIG" ]; then OPTIONS="$OPTIONS --config=${CONFIG}"; fi
  if [ -n "$SDL_CORE" ]; then OPTIONS="$OPTIONS --sdl-core=${SDL_CORE}"; fi
  if [ -n "$REPORT_PATH" ]; then OPTIONS="$OPTIONS --report-path=${REPORT_PATH}"; fi
  if [ -n "$SDL_API" ]; then OPTIONS="$OPTIONS --sdl-interfaces=${SDL_API}"; fi
  if [ $FORCE_REMOTE = true ]; then OPTIONS="$OPTIONS --storeFullSDLLogs"; fi

  dbg "Parameters:"
  dbg "TEST_TARGET: "$TEST_TARGET
  dbg "REPORT_PATH: "$REPORT_PATH
  dbg "OPTIONS: "$OPTIONS
}

create_report_folder() {
  REPORT_PATH_TS=${REPORT_PATH}/$(date +"%Y-%m-%d_%H-%M-%S")
  mkdir -p ${REPORT_PATH_TS}
}

parse_arguments "$@"

check_arguments

create_report_folder

if [ $FORCE_REMOTE = true ]; then
  dbg "Mode: Remote"
  source tools/runners/remote.sh
elif [ $JOBS -gt 1 ] || [ $FORCE_PARALLELS = true ]; then
  dbg "Mode: Parallels"
  source tools/runners/parallels.sh
else
  dbg "Mode: Regular"
  source tools/runners/common.sh
fi

StartUp

Run

TearDown
