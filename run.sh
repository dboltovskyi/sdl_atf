#!/usr/bin/env bash

./start.sh \
  $1 \
  $2 \
  --report-path=$(readlink -m ~/ramdrv/TestingReports) \
  --sdl-interfaces=$(readlink -m ~/ramdrv/sdl_core/src/components/interfaces) \
