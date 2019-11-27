# ATF parallels

ATF parallels is a bash based tool to run several ATF instances (and SDL as well)
simultaneously.

## Quick start

* install Docker
* build docker image:<br>
In directory `atf_parallels/docker`:
    * execute `./build.sh <ubuntu_version>`<br>
    <b>Note:</b> supported versions are <b>16</b> and <b>18</b> (will be processed as <b>16.04</b> and <b>18.04</b> correspondingly)
* install screen: `sudo apt install screen`

## Example:
    ./start.sh sdl_atf_test_scripts/test_sets/smoke_tests.txt -j 3

### Working hierarchy:
```
main-
    |
    | screen session -
                     | loop.sh -- docker container (one-by-one)
    | screen session -
                     | loop.sh -- docker container (one-by-one)
    | screen session -
                     | loop.sh -- docker container (one-by-one)
```

## Docker

Docker image should be previously built to be used by ATF parallels.<br>
Dockerfile is designed in a way to run ATF test. Therefore the only argument should be passed to docker container is a name of script to be run.<br>
The following options are required to run docker container:
* --cap-add NET_ADMIN - to fully use ifconfig to create new connections etc.;
* -e LOCAL_USER_ID=`id -u $USER` - to avoid permissions issues within mounted directories;
* -v <path_to_atf>:/home/developer/atf - path to ATF (path_to_atf in our case is a path to beforehand prepared ATF instance)
* -v <path_to_sdl>:/home/developer/sdl - path to SDL (path_to_sdl in our case is a path to beforehand prepared SDL instance).

## Dependencies:
 - screen
 - Docker
 - rsync
