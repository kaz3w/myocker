#!/bin/bash

set -xeu

architecture=$(dpkg --print-architecture)

if [ "$architecture" = "armhf" ]; then
  apt-get install -y --no-install-recommends \
                                  apt-transport-https \
                                  ca-certificates \
                                  gnupg \
                                  software-properties-common \
                                  wget
  wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null && \
  apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main' && \
  apt-get update && apt-get install -y cmake=3.19.2-0kitware1ubuntu20.04.1 \
                                       cmake-data=3.19.2-0kitware1ubuntu20.04.1
fi

