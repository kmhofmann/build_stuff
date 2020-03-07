FROM ubuntu:19.10
SHELL ["/bin/bash", "-c"]

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  build-essential \
  git

# See https://github.com/cmus/cmus/issues/616#issuecomment-462518660
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  bash-completion \
  libao-dev \
  libasound2-dev \
  libavcodec-dev \
  libavformat-dev \
  libswresample-dev \
  libcddb2-dev \
  libcdio-cdda-dev \
  libcue-dev \
  libdiscid-dev \
  libfaad-dev \
  libflac-dev \
  libjack-dev \
  libmad0-dev \
  libmodplug-dev \
  libmpcdec-dev \
  libncursesw5-dev \
  libopusfile-dev \
  libpulse-dev \
  libroar-dev \
  libsamplerate0-dev \
  libvorbis-dev \
  libwavpack-dev \
  libsystemd-dev \
  pkg-config

WORKDIR /root

RUN mkdir -p /root/_utils
COPY build_cmus.sh /root/
COPY _utils/build_helper_functions.sh /root/_utils/
RUN /root/build_cmus.sh



