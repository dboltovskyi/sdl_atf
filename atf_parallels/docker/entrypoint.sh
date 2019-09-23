#!/bin/bash

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback

USER_ID=${LOCAL_USER_ID:-9001}

useradd --shell /bin/bash -u $USER_ID -o -c "" developer
echo "developer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

chown developer /home/developer
chgrp developer /home/developer

export HOME=/home/developer

echo "export LANG=en_US.UTF-8" >> /home/developer/.zshrc
echo "export LD_LIBRARY_PATH=." >> /home/developer/.zshrc
set -x

cd /home/developer/sdl/atf
sudo -E -u developer ./start.sh "$@"