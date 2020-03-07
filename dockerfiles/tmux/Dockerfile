FROM ubuntu:19.10
SHELL ["/bin/bash", "-c"]

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  build-essential \
  git \
  automake \
  pkg-config \
  bison \
  libevent-dev \
  libncurses-dev

WORKDIR /root

RUN mkdir -p /root/_utils
COPY build_tmux.sh /root/
COPY _utils/build_helper_functions.sh /root/_utils/
RUN /root/build_tmux.sh
