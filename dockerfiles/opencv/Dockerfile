# TODO:
# - OpenBLAS is not found
# - Java compilation does not work
# - Actually test the script instead of a manual build process

FROM ubuntu:19.10
SHELL ["/bin/bash", "-c"]

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  build-essential \
  git \
  cmake \
  ninja-build \
  pkg-config \
  ccache

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  gfortran \
  libatlas-base-dev \
  libopenblas-dev \
  liblapacke-dev \
  libeigen3-dev \
  libceres-dev

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  libprotobuf-dev \
  libgflags-dev \
  libgoogle-glog-dev \
  libhdf5-dev \
  libtbb2 \
  libtbb-dev

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  libjpeg-dev \
  libpng-dev \
  libtiff-dev \
  libwebp-dev \
  #libjasper-dev \
  libopenexr-dev

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  libavcodec-dev \
  libavformat-dev \
  libswscale-dev \
  libv4l-dev \
  libxvidcore-dev \
  libx264-dev \
  libdc1394-22-dev \
  libavresample-dev

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  libgtk-3-dev \
  libgstreamer-plugins-base1.0-dev

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  python3-dev \
  python3-numpy
  #default-jdk \
  #ant

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  tesseract-ocr \
  libtesseract-dev \
  doxygen

WORKDIR /root

#RUN mkdir -p /root/_utils
#COPY build_opencv.sh /root/
#COPY _utils/build_helper_functions.sh /root/_utils/
#RUN /root/build_opencv.sh

RUN git clone https://github.com/opencv/opencv.git
RUN git clone https://github.com/opencv/opencv_contrib.git

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  cmake-curses-gui \
  intel-mkl

RUN export ANT_HOME=/usr/share/ant \
 && mkdir /root/opencv/build \
 && cd /root/opencv/build \
 && cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DOPENCV_EXTRA_MODULES_PATH=/root/opencv_contrib/modules \
  -DOPENCV_ENABLE_NONFREE=ON \
  -DBUILD_DOCS=ON \
  -DBUILD_EXAMPLES=ON \
  -DWITH_TBB=ON \
  -DWITH_OPENMP=ON \
   ..
