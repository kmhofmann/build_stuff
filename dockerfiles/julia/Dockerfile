FROM ubuntu:19.10
SHELL ["/bin/bash", "-c"]

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  build-essential \
  git \
  #libatomic1 \
  python3 \
  gfortran \
  #perl \
  wget \
  m4 \
  cmake \
  pkg-config

WORKDIR /root

RUN mkdir -p /root/_utils
COPY build_julia.sh /root/
COPY _utils/build_helper_functions.sh /root/_utils/
RUN /root/build_julia.sh


