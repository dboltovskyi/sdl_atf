#!/bin/bash

_ubuntu_ver=$1
_ubuntu_ver_default=18

if [ -z $_ubuntu_ver ]; then
  _ubuntu_ver=$_ubuntu_ver_default
  echo "Ubuntu version was not specified, $_ubuntu_ver_default will be used as default"
fi

case $_ubuntu_ver in
  16|18)
    _ubuntu_ver=$_ubuntu_ver.04
    echo "Ubuntu version: "$_ubuntu_ver;;
  *)
    echo "Specified Ubuntu version is unexpected";
    echo "Allowed versions: 16 or 18";
    exit 1;;
esac

docker build --build-arg ubuntu_ver=$_ubuntu_ver -f Dockerfile -t atf_worker .
