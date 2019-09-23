# ATF parallels

ATF parallels is a bash based tool to run several ATF instances (and SDL as well)
simultaneously.

## Quick start

* install Docker
* build docker image: in directory `atf_parallels/docker` execute `make`
* install screen: `sudo apt install screen`
* in `main.sh` override following variables:<br>
```
_path_sdl="$HOME/sdl/build_sdl/bin"
_path_3rd_party="$HOME/sdl/3rd_party"
_path_atf="$HOME/sdl/sdl_atf"
_path_atf_test_scripts="$HOME/sdl/sdl_atf_test_scripts"
_path_sdl_api="$HOME/sdl/sdl_core/src/components/interfaces"
```

## Example:
    ./main.sh -j3 -set sdl_atf_test_scripts/test_sets/smoke_tests.txt

## main.sh

`main.sh` is the only script to be run by the user.

ATF parallels runs the defined number of screen sessions. Each screen session runs `loop.sh`. Each `loop.sh` contains an endless loop with concurrent read to the prepared queue of test scripts (test set). For each new test, the corresponding docker container should be run.

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


ATF parralles is a CLI tool and supports the following keys:
 - <b>-j | --jobs n</b> - (spaces are not taken into account) means the number of jobs to be started (number of screen sessions, to be precise)<br>
    <b>ex.:</b> -j3, --jobs 4
 - <b>-set | --test_set set</b> - specifies the test set to be run.
 - <b>-res | --result str</b> - specifies a path to TestingResult to be stored to.
 - <b>-def | --define [define_file_path]</b> - specifies a path to a file with predefined 
 variables. if define_file_path is ommited, the file ./define.sh will be used. The defined file will be sources to ATF parralles.<br>
The following variables could be overwritten:
    * _tmp_dir="/tmp/prepared_env" - the working directory of ATF parallels
    * _sdl_prepared=$_tmp_dir/sdl - path to where the SDL should be copied
    * _path_sdl="$HOME/sdl/build_sdl/bin" - path to bin of SDL
    * _path_3rd_party="$HOME/sdl/3rd_party" - path to 3rd_party libs
    * _path_atf="$HOME/sdl/sdl_atf" - path to ATF
    * _path_atf_test_scripts="$HOME/sdl/sdl_atf_test_scripts" - path to ATF test scripts
    * _path_sdl_api="$HOME/sdl/sdl_core/src/components/interfaces" - path to SDL interfaces
    * _test_result_path="./result" - directory to store TestingResult to
    * _queue=queue.tmp.txt - name of temporary testset (for internal use only. Initial set will be copied to specified file)

Test results will be gathered to a common directory: `<_tmp_dir>/TestingReport`.<br>
Testing report directory contains a singe Report.txt with overall testing status and a bunch of directories per test (with log files from ATF and SDL).
Each subdirectory is named by a number and this number is not related to test name, it's just a test index.

## Docker

Docker image should be previously built to be used by ATF parallels.<br>
Dockerfile is designed in a way to run ATF test. Therefore the only argument should be passed to docker container is a name of script to be run.<br>
The following options are required to run docker container:
* --cap-add NET_ADMIN - to fully use ifconfig to create new connections etc.;
* -e LOCAL_USER_ID=`id -u $USER` - to avoid permissions issues within mounted directories;
* -v <path_to_atf>:/home/developer/atf - path to ATF (path_to_atf in our case is a path to beforehand prepared ATF instance)
* -v <path_to_sdl>:/home/developer/sdl - path to SDL (path_to_sdl in our case is a path to beforehand prepared SDL instance).

#### Please, take into account that ATF could be shared among docker containers while SDL should be unique per container.

## Dependencies:
 - screen
 - Docker
