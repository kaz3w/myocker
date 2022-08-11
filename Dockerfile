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

RUN ["/bin/bash", "-c", "DISTRO='fsl-imx-wayland' MACHINE='imx8mmevk' LANG=en_US.UTF-8 source ./setup-environment bitbake imx-image-core"]

## BUILD EVK-SDK
ARG BUILD_SDK_TARGET="build_sdk"
ARG BUILD_ROOT="${WSRC_ROOT}/${BUILD_SDK_TARGET}"

RUN ["/bin/bash", "-c", "cd ${WSRC_ROOT}; source ./imx-setup-release.sh -b ./${BUILD_SDK_TARGET}"]

RUN echo 'BB_NUMBER_THREADS = "8"' >> ${WSRC_ROOT}/${BUILD_SDK_TARGET}/conf/local.conf \
 && echo 'PARALLEL_MAKE = "-j 8"' >> ${WSRC_ROOT}/${BUILD_SDK_TARGET}/conf/local.conf

RUN ["/bin/bash", "-c", "cd ${WSRC_ROOT}; source ./setup-environment ${BUILD_SDK_TARGET}; bitbake core-image-minimal -c populate_sdk"] 

RUN cd ${BUILD_ROOT}/tmp/deploy/sdk \
 && echo | ./fsl-imx-wayland-glibc-x86_64-core-image-minimal-aarch64-imx8mmevk-toolchain-5.4-zeus.sh

 ## BUILD EVK-BOOTLOADER

ARG BUILD_TARGET_BOOT="imx-boot-bin"
ARG BUILD_ROOT__IMX_BOOT_BIN="/home/${USERNAME}/${BUILD_TARGET_BOOT}"
ARG TARGET_UBOOT_IMX="uboot-imx"

## U-BOOT
WORKDIR ${BUILD_ROOT__IMX_BOOT_BIN}
RUN git clone https://source.codeaurora.org/external/imx/${TARGET_UBOOT_IMX}.git

WORKDIR ${TARGET_UBOOT_IMX}
RUN git checkout -b imx_v2020.04_5.4.70_2.3.0 origin/imx_v2020.04_5.4.70_2.3.0 
ENV ARCH=arm 

RUN DEBIAN_FRONTEND=noninteractive \
 && sudo apt-get install -y gcc-aarch64-linux-gnu 

ENV CROSS_COMPILE=aarch64-linux-gnu-

RUN ["/bin/bash", "-c", "ARCH=arm;cd ${BUILD_ROOT__IMX_BOOT_BIN}/${TARGET_UBOOT_IMX}; source /opt/fsl-imx-wayland/5.4-zeus/environment-setup-aarch64-poky-linux"]

RUN ARCH=arm \
 && make clean \
 && make imx8mm_evk_defconfig \
 && make -j8

## Download and build the ARM Trusted Firmware
ARG TARGET_IMX_ATF="imx-atf"
WORKDIR ${BUILD_ROOT__IMX_BOOT_BIN}
RUN git clone https://source.codeaurora.org/external/imx/${TARGET_IMX_ATF}.git

WORKDIR  ${TARGET_IMX_ATF}
RUN git checkout -b imx_5.4.70_2.3.0 origin/imx_5.4.70_2.3.0 \
 && unset LDFLAGS \
 && make -j8 PLAT=imx8mm bl31

## LPDDR4 training binaries(Caribration)
ARG TARGET_FIRMWARE_IMX="firmware-imx"
WORKDIR ${BUILD_ROOT__IMX_BOOT_BIN}/${TARGET_FIRMWARE_IMX}

RUN wget https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/firmware-imx-8.5.bin \
 && chmod a+x firmware-imx-8.5.bin

COPY --chown=${USERNAME}:${USERNAME} /firmware-imx.exp .
# RUN sudo chown ${USERNAME}:${USERNAME} firmware-imx.exp
# RUN expect firmware-imx.exp
# RUN ["/bin/bash", "-c", "cd ${BUILD_ROOT__IMX_BOOT_BIN}/${TARGET_FIRMWARE_IMX}; ./firmware-imx-8.5.bin; echo y"]
# RUN find . > ${BUILD_ROOT__IMX_BOOT_BIN}/t.txt

COPY --chown=${USERNAME}:${USERNAME} /firmware-imx-8.5/ firmware-imx-8.5


# ## iMX mkimage
ARG TARGET_IMX_MKIMAGE="imx-mkimage"
WORKDIR ${BUILD_ROOT__IMX_BOOT_BIN}
RUN git clone https://source.codeaurora.org/external/imx/${TARGET_IMX_MKIMAGE}.git

WORKDIR ${BUILD_ROOT__IMX_BOOT_BIN}/${TARGET_IMX_MKIMAGE}
RUN git checkout -b imx_5.4.70_2.3.0 origin/imx_5.4.70_2.3.0

# ## copy files
WORKDIR ${BUILD_ROOT__IMX_BOOT_BIN}/${TARGET_IMX_MKIMAGE}
RUN cp ../${TARGET_UBOOT_IMX}/spl/u-boot-spl.bin iMX8M/
RUN cp ../${TARGET_UBOOT_IMX}/u-boot-nodtb.bin iMX8M/
RUN cp ../${TARGET_UBOOT_IMX}/arch/arm/dts/imx8mm-evk.dtb iMX8M/
RUN cp ../${TARGET_IMX_ATF}/build/imx8mm/release/bl31.bin iMX8M/
RUN cp ../${TARGET_FIRMWARE_IMX}/firmware-imx-8.5/firmware/ddr/synopsys/lpddr4_pmu_train_* iMX8M/
RUN cp ../${TARGET_UBOOT_IMX}/tools/mkimage iMX8M/mkimage_uboot

RUN DEBIAN_FRONTEND=noninteractive \
 && sudo apt-get install -y device-tree-compiler 

RUN make SOC=iMX8MM flash_evk

