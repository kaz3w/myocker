#!/bin/bash

set -xeu

architecture=$(dpkg --print-architecture)

if [ "$architecture" = "amd64" ]; then
  apt-get install -y gcc-multilib lib32ncurses5-dev cmake
fi

if [ "$architecture" = "armhf" ]; then
  apt-get install -y --no-install-recommends \
                                  apt-transport-https \
                                  ca-certificates \
                                  gnupg \
                                  software-properties-common \
                                  wget

  wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
  wget https://github.com/Kitware/CMake/releases/download/v3.24.0/cmake-3.24.0-linux-aarch64.sh && \
  chmod a+x ./cmake-3.24.0-linux-aarch64.sh && \
  ./cmake_bin_sh.exp && \
  cp -rp cmake-3.24.0-linux-x86_64/* /usr/local

  # apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main' && \
  # apt-get update && apt-get install -y cmake=3.19.2-0kitware1ubuntu18.04.1 \
  #                                      cmake-data=3.19.2-0kitware1ubuntu18.04.1
fi

