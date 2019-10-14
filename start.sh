#!/usr/bin/env bash

ATF_PATH=$(cd "$(dirname "$0")" && pwd)
REPORT_FILE=Report.txt
REPORT_FILE_CONSOLE=Console.txt
DEBUG=false
LINE="====================================================================================================="

JOBS=1
FORCE_PARALLELS=false

THIRD_PARTY="$THIRD_PARTY_INSTALL_PREFIX"
ATF_TS_PATH=$(dirname $(realpath test_scripts))
TMP_PATH=/tmp

# Color modifications
P="\033[0;32m" # GREEN
F="\033[0;31m" # RED
A="\033[0;35m" # MAGENTA
S="\033[0;33m" # YELLOW
N="\033[0m"    # NONE

dbg() { if [ $DEBUG = true ]; then echo "$@"; fi }

log() { echo -e $@; }

show_help() {
  echo "Bash .lua test Script Runner"
  echo "Besides execution of scripts it also does auxiliary actions:"
  echo "   - clean up SDL and ATF folders before running of each script"
  echo "   - backup and restore SDL important files"
  echo "   - create report with all required logs for each script"
  echo
  echo "Usage: start.sh SDL TEST [OPTION]..."
  echo
  echo "SDL  - path to SDL binaries"
  echo "TEST - test target, could be one of the following:"
  echo "   - test script"
  echo "   - test set"
  echo "   - folder with test scripts"
  echo "[OPTION] - options supported by ATF:"
  echo "   --sdl-api          - path to SDL APIs"
  echo "   --report-path      - path to report and logs"
  echo "   -j|--jobs n        - number of jobs to start ATF in parallels"
  echo "   --third-party str  - path to SDL third party"
  echo "   --atf-ts str       - path to ATF test scripts"
  echo "   --parallels        - force to use parallels"
  echo "   --tmp              - path to temporary folder used by parallels"
  echo
  echo "In case if folder is specified as a test target:"
  echo "   - only scripts which name starts with number will be taken into account (e.g. 001, 002 etc.)"
  echo "   - if there are sub-folders scripts will be run recursively"
  echo
  exit 0
}

get_param_from_atf_config() {
  for i in `sed s'/=/ /g' $1 | grep "$2 " | awk '{print $2}'`; do echo $i | sed 's/"//g'; done
}

set_default_params_from_atf_config() {
  local CONFIG_FILE=${ATF_PATH}/modules/config.lua
  REPORT_PATH=$(get_param_from_atf_config ${CONFIG_FILE} "config.reportPath")
  SDL_CORE=$(get_param_from_atf_config ${CONFIG_FILE} "config.pathToSDL")
  SDL_API=$(get_param_from_atf_config ${CONFIG_FILE} "config.pathToSDLInterfaces")
  SDL_PROCESS_NAME=$(get_param_from_atf_config ${CONFIG_FILE} "config.SDL")
  dbg "Default arguments from ATF config:"
  dbg "  SDL_CORE: "$SDL_CORE
  dbg "  REPORT_PATH: "$REPORT_PATH
  dbg "  SDL_PROCESS_NAME: "$SDL_PROCESS_NAME
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
      --sdl-core)
        SDL_CORE="$ARG_VAL"
      ;;
      --report-path)
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
      -h|--help|-help|--h)
        show_help
      ;;
      -*)
        local DLM=""
        if [ -n "$ARG_VAL" ]; then DLM="="; fi
        if [ -n "${OPTIONS}" ]; then OPTIONS="${OPTIONS} "; fi
        OPTIONS="${OPTIONS}${ARG_KEY}${DLM}${ARG_VAL}"
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
  elif [ ${#NAMELESS_ARGS[*]} -ge 2 ]; then
    SDL_CORE=${NAMELESS_ARGS[1]}
    TEST_TARGET=${NAMELESS_ARGS[2]}
  fi
}

check_arguments() {
  # check presence of mandatory arguments
  if [ -z $SDL_CORE ]; then
    echo "Path to SDL binaries was not specified"
    exit 1
  fi
  if [ -z $TEST_TARGET ]; then
    echo "Test target was not specified"
    exit 1
  fi
  # check if defined path exists
  if [ ! -d $SDL_CORE ]; then
    echo "SDL core binaries was not found by defined path"
    exit 1
  fi
  # add '/' to the end of the path if it missing
  if [ "${SDL_CORE: -1}" = "/" ]; then
    SDL_CORE="${SDL_CORE:0:-1}"
  fi
  if [ "${TEST_TARGET: -1}" = "/" ]; then
    TEST_TARGET="${TEST_TARGET:0:-1}"
  fi
  dbg "Updated arguments:"
  dbg "  SDL_CORE: "$SDL_CORE
  dbg "  TEST_TARGET: "$TEST_TARGET
  dbg "  REPORT_PATH: "$REPORT_PATH
  dbg "  OPTIONS: "$OPTIONS
}

create_report_folder() {
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  REPORT_PATH_TS=${REPORT_PATH}/${TIMESTAMP}
  mkdir -p ${REPORT_PATH_TS}
}

set_default_params_from_atf_config
parse_arguments "$@"
check_arguments

create_report_folder

if [ $JOBS -gt 1 ] || [ $FORCE_PARALLELS = true ]; then
  source tools/runners/parallels.sh
else
  source tools/runners/common.sh
fi

StartUp
Run
TearDown
