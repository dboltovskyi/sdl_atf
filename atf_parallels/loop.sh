#!/bin/bash

_tmpdirname=$1; shift
_atf_ts_dir=$1; shift
_queue=$1; shift
_sdl_core_path=$1; shift
_sdl_api_path=$1; shift
_report_path=$1; shift

_lockfile=.lock

_image_name=atf_worker
_container_name=$(basename $_tmpdirname)



####################################################################
#   The following code has to be run in several different processes
#       i.e. `screen -d -m 'script_to_run.sh'`
####################################################################

function docker_run {
    docker run --rm \
        --name $_container_name \
        --cap-add NET_ADMIN \
        -e LOCAL_USER_ID=`id -u $USER` \
        -v $_atf_ts_dir:/home/developer/atf_ts \
        -v $_tmpdirname:/home/developer/sdl \
        $_image_name "$@"
}

function docker_stop {
    docker stop $(docker ps -q -f "name=$_container_name")
    for id in $container_ids;
    do
        docker stop $id
    done
}

function pop {
    FILE=$1
    if (set -o noclobber; echo "$$" > "$_lockfile") 2> /dev/null; then
        trap 'rm -f "$_lockfile"; exit $?' TERM EXIT

        LINE=$(head -n 1 $FILE | awk '{print $1}')
        sed -i '1d' $FILE

        echo $LINE
        sleep 0.2
        rm -f "$_lockfile"
        trap - TERM EXIT
        return 0
    else
        return 1
    fi
}

function int_handler() {
    echo "Stopping docker containers"

    # Stop handling sigint
    trap - INT

    rm -f $_lockfile
    docker_stop

    exit 0
}

function main {
    trap 'int_handler' INT

    while true; do
        script_name=$(pop $_queue)
        if [[ ! $? == 0 ]]; then
            sleep 0.1
            continue
        fi

        [ -z "$script_name" ] && break;

        docker_run $script_name \
            --sdl-core=$_sdl_core_path \
            --sdl-api=$_sdl_api_path \
            --report=$_report_path

        sleep 0.1
    done
}

main
