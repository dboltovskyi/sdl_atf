ARG ubuntu_ver

FROM ubuntu:${ubuntu_ver}

RUN apt-get update && apt-get -q -y install locales sudo

RUN apt-get update && apt-get -q -y install libssl1.0.0 libusb-1.0-0 libbluetooth3 \
  libssl-doc- libusb-1.0-doc- manpages- manpages-dev-

RUN apt-get update && apt-get -q -y install openssl liblua5.2-0 psmisc libexpat1-dev \
  autotools-dev- binutils- build-essential- bzip2- cpp- cpp-5- dpkg-dev- fakeroot- \
  manpages- manpages-dev-

RUN apt-get update && apt-get -q -y install sqlite3 libqt5websockets5 net-tools iproute2 \
  qttranslations5-l10n- xdg-user-dirs- xml-core- dbus-

RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8

RUN chmod u+s /sbin/ifconfig /sbin/ip && mkdir /home/developer

COPY entrypoint.sh /usr/bin/

ENTRYPOINT ["/bin/bash", "-e", "/usr/bin/entrypoint.sh"]
