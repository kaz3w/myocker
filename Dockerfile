FROM ubuntu:18.04

RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# WORKDIR /
# COPY ./helper_script_for_armhf.sh .
# RUN ["/bin/bash", "-c", "./helper_script_for_armhf.sh"] 


RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
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
	cmake \
	openssh-client \
	supervisor \
	expect \
	autoconf \
	libncurses5-dev \
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
	locales

RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && apt-file update


# COPY ./source /source

# WORKDIR /source
# RUN cmake .
