#!/usr/bin/env bash

source tools/runners/common.sh

OPTIONS="--config=${CONFIG} --report-path=${REPORT_PATH} --sdl-interfaces=${SDL_API}"

SDL_BACK_UP=()
SDL_CLEAN_UP=()
