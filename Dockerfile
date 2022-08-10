FROM ubuntu:18.04

RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# COPY ./helper_script_for_armhf.sh /helper_script_for_armhf.sh
# RUN /helper_script_for_armhf.sh

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
	debian-keyring \
	git-all \
	gawk \
	git-core \
	diffstat \
	unzip \
	texinfo \
	gcc-multilib \
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
	libncurses5-dev \
	wget \
	build-essential \
	cmake \
	openssh-client \
	supervisor \
	expect \
	autoconf \
	libncurses5-dev \
	lib32ncurses5-dev \
	software-properties-common \
	apt-file \
	curl \
	vim \
	vim-bitbake \
	tree \
	sudo \
	locales-all \
	rsync \
	bison \
	flex \
	locales \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && apt-file update


# COPY ./source /source

# WORKDIR /source
# RUN cmake .
