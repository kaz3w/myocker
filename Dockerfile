FROM ubuntu:18.04

COPY ./helper_script_for_armhf.sh /helper_script_for_armhf.sh  # 細工部分
RUN /helper_script_for_armhf.sh                                # 細工部分

COPY ./source_dir /source_dir

WORKDIR /source_dir
RUN cmake .
