FROM ubuntu:18.04

RUN apt-get update && apt-get -q -y install \
  locales \
  net-tools \
  libssl1.0-dev \
  libbluetooth3 \
  libusb-1.0-0-dev \
  sudo \
  libqt5websockets5-dev \
  liblua5.2-dev

RUN locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    chmod u+s /sbin/ifconfig

COPY entrypoint.sh /usr/bin/

ENTRYPOINT ["/bin/bash", "-e", "/usr/bin/entrypoint.sh"]
