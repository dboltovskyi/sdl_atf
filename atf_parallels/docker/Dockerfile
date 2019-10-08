ARG ubuntu_ver

FROM ubuntu:${ubuntu_ver}

RUN apt-get update

RUN apt-get -q -y install locales net-tools sudo

RUN apt-get -q -y install libssl1.0.0 libusb-1.0-0 libbluetooth3 \
  libssl-doc- libusb-1.0-doc- manpages- manpages-dev-

RUN apt-get -q -y install openssl liblua5.2-0 psmisc \
  autotools-dev- binutils- build-essential- bzip2- cpp- cpp-5- dpkg-dev- fakeroot- \
  manpages- manpages-dev-

RUN apt-get -q -y install sqlite3 libqt5websockets5 \
  qttranslations5-l10n- xdg-user-dirs- xml-core- dbus-

RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN chmod u+s /sbin/ifconfig

RUN mkdir /home/developer

COPY entrypoint.sh /usr/bin/

ENTRYPOINT ["/bin/bash", "-e", "/usr/bin/entrypoint.sh"]
