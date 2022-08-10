FROM ubuntu:18.04

RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

COPY ./helper_script_for_armhf.sh /helper_script_for_armhf.sh
RUN /helper_script_for_armhf.share

COPY ./source_dir /source_dir

WORKDIR /source_dir
RUN cmake .
