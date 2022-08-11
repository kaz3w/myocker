FROM ubuntu:18.04

RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
	gpg \
	debian-keyring \
	git-all \
	gawk \
	git-core \
	diffstat \
	unzip \
	texinfo \
	build-essential \
	chrpath \
	socat \
	cpio \
	python \
	python3 \
	python3-pip \
	python3-pexpect \
	xz-utils \
	debianutils \
	iputils-ping \
	python3-git \
	python3-jinja2 \
	libegl1-mesa \
	libsdl1.2-dev \
	pylint3 \
	xterm \
	wget \
	build-essential \
	openssh-client \
	supervisor \
	expect \
	autoconf \
	libncurses5-dev \
	software-properties-common \
	apt-file \
	curl \
	vim \
	tree \
	sudo \
	locales-all \
	rsync \
	bison \
	flex \
	locales

RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && apt-file update

COPY cmake_bin_sh.exp .
COPY ./helper_script_for_armhf.sh .
RUN ["/bin/bash", "-c", "./helper_script_for_armhf.sh"] 

## Build sample c project
# WORKDIR /source
# COPY ./source/ .
# RUN cmake .

WORKDIR /usr/local/bin
RUN set -x \
 && curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo \
 && chmod a+x /usr/local/bin/repo

RUN locale-gen
RUN locale-gen en_US.UTF-8
RUN locale=en_US.UTF-8

RUN set -x \
 && curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo \
 && chmod a+x /usr/local/bin/repo

# For derivation --->
ENV USERNAME="build"
ENV USERPASSWD="passwd"
# ---> For derivation

ARG GROUPNAME=${USERNAME}
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID $GROUPNAME \
 && useradd -m -s /bin/bash -u $UID -g $GID -G sudo,root ${USERNAME} \
 && echo ${USERNAME}:${USERPASSWD} | chpasswd

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# To supress Yes/No Loop
ENV EULA=1

###################################
# Switch to privilege of ${USERNAME}
###################################

USER ${USERNAME}

ENV LANG=en_US.UTF-8
ENV SRC_ROOT=/home/${USERNAME}/imx-yocto-bsp

WORKDIR ${SRC_ROOT}

RUN set -x \
 && git config --global user.email "${USERNAME}@builder.local" \
 && git config --global user.name "${USERNAME}001"

RUN set -x \
 && repo init -u https://source.codeaurora.org/external/imx/imx-manifest -b imx-linux-zeus -m imx-5.4.70-2.3.7.xml \
 && repo sync

ENV DISTRO="fsl-imx-wayland"
ENV MACHINE="imx8mmevk"

ARG BUILD_TARGET="build_imx8"
RUN ["/bin/bash", "-c", "cd ${SRC_ROOT}; LANG=en_US.UTF-8;source ./imx-setup-release.sh -b ./${BUILD_TARGET}"] 

# RUN echo `grep cpu.cores /proc/cpuinfo | sort -u | grep -E '([0-9]+)'`

RUN echo 'BB_NUMBER_THREADS = "8"' >> ${SRC_ROOT}/${BUILD_TARGET}/conf/local.conf \
 && echo 'PARALLEL_MAKE = "-j 8"' >> ${SRC_ROOT}/${BUILD_TARGET}/conf/local.conf

