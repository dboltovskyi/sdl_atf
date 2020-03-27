# Automated Test Framework (ATF)

## Dependencies:
Library                | License
---------------------- | -------------
**Lua libs**           |
liblua5.2              | MIT
json4lua               | MIT
lua-stdlib             | MIT
lua-lpeg               |
**Qt libs**            |
Qt5.9 WebSockets       | LGPL 2.1
Qt5.9 Network          | LGPL 2.1
Qt5.9 Core             | LGPL 2.1
Qt5.9 Test             | LGPL 2.1
**Other libs**         |
lpthread               | LGPL
OpenSSL (ssl, crypto)  | OpenSSL License
libxml2                | MIT
ldoc                   | MIT/X11

## Get source code:
```
git clone --recurse-submodules https://github.com/smartdevicelink/sdl_atf
```
## Compilation:
**1.** Install 3d-parties developers libraries
- Run the following commands :
```
$ sudo apt-get install lua5.2 liblua5.2-dev libxml2-dev lua-lpeg-dev
$ sudo apt-get install openssl libssl1.0-dev
```

**2.** Install Qt5.9+
- For Ubuntu `18.04`:
    - Run the following command :
```
$ sudo apt-get install libqt5websockets5 libqt5websockets5-dev
```

- For Ubuntu `16.04`:
    - Run the following commands :
```
$ sudo add-apt-repository -y ppa:beineri/opt-qt591-xenial
$ sudo apt-get update
$ sudo apt-get install qt59base qt59websockets
```

**3.** Build ATF
CMake 3.15 or newer is required to generate the build files and can be downloaded from [here](https://cmake.org/download/).
- Create a build folder outside of the sdl_atf folder
- cd into your build folder
- Run `cmake ../sdl_atf`
- Run `make`
- Run `make install`

**4.** Copy content of scripts repository
- Run `cp -r <path_to_sdl_atf_test_scripts>/* .`

## Configuration of ATF
ATF configuration is setting up in `modules/configuration` folder.
- `base_config.lua` : base configuration parameters (reporting, paths to SDL e.t.c)
- `connection_config.lua` : configuration parameters related to all connections (mobile, hmi, remote)
- `security_config.lua` : configuration parameters related to security layer of connection
- `app_config.lua` : predefined applications parameters
Each folder in this folder represents values of `--config` option for ATF run: `local`, `remote_linux`, `remote_qnx`
They can override one or more described configuration files.

## Run:

```
./start.sh TEST [OPTIONS]...
```

- TEST - test target, could be one of the following:
  - test script
  - test set
  - folder with test scripts
- [OPTIONS] - options supported by ATF:
  - --sdl-core         - path to SDL binaries
  - --config           - name of configuration
  - --sdl-api          - path to SDL APIs
  - --report           - path to report and logs
  - --parallels        - force to use parallels
  - -j|--jobs n        - number of jobs to start ATF in parallels
  - --third-party str  - path to SDL third party
  - --atf-ts str       - path to ATF test scripts
  - --tmp              - path to temporary folder used by parallels
  - --remote           - force to use remote connection mode

In case if folder is specified:
   - only scripts which name starts with number will be taken into account (e.g. 001, 002 etc.)
   - if there are sub-folders scripts will be run recursively

Besides execution of test scripts start.sh also does auxiliary actions:
   - clean up SDL and ATF folders before running of each script
   - backup and restore SDL important files
   - create report with all required logs for each script

### Modes:
 - Common - test scripts will be run locally
 - Parallels - test scripts will be run locally in isolated environments and, if required, in several threads
 - Remote - test scripts will be run using remote connection.
   In this mode `RemoteTestingAdapterServer` should be run on the same host as SDL

### Advanced usage:
`start.sh` is the main application that will decide which runner to use.

A `runner` is a script which defines the main workflow of running a certain test.
Runners are located at `tools/runners`:
 - `common.sh` - default runner
 - `parallels.sh` - runner for parallels mode
 - `remote.sh` - runner for remote connection mode

## Documentation generation
### Download and install [ldoc](stevedonovan.github.io/ldoc/manual/doc.md.html)
```
$ sudo apt install luarocks
$ sudo luarocks install luasec
$ sudo luarocks install penlight
$ sudo luarocks install ldoc
$ sudo luarocks install discount
```
### Generate ATF documentation
```
cd sdl_atf
ldoc -c docs/config.ld .
```
### Open documentation
```chromium-browser docs/html/index.html```

## Run Unit Tests
``` make test```
