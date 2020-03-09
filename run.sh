#!/usr/bin/env bash

## Local

./start.sh \
  $2 \
  --sdl-core=$1 \
  --sdl-api=$(readlink -m ~/ramdrv/sdl_core/src/components/interfaces) \
  --report=$(readlink -m ~/ramdrv/TestingReports) \
  --tmp=$(readlink -m ~/ramdrv/Tmp) \
  --jobs 1 #\
  # --parallels

## Remote

# ./start.sh \
#   $2 \
#   --config=$1 \
#   --sdl-api=$(readlink -m ~/ramdrv/sdl_core/src/components/interfaces) \
#   --report=$(readlink -m ~/ramdrv/TestingReports) \
#   --remote

