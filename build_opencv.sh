#!/usr/bin/env bash

# Ubuntu dependencies (see https://docs.opencv.org/master/d7/d9f/tutorial_linux_install.html):
# [compiler] sudo apt-get install build-essential
# [required] sudo apt-get install cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
# [optional] sudo apt-get install python-dev python-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev

if [[ "$(uname -s)" == "Darwin" ]]; then
  export NCPUS=$(($(sysctl -n hw.ncpu)))
elif [[ "$(uname -s)" == "Linux" ]]; then
  export NCPUS=$(($(nproc)))
fi

print_help()
{
  echo ""
  echo "Usage:"
  echo "  build_opencv.sh -s [SOURCE_DIR] -t [INSTALL_DIR] (-T [TAG]) (-C [CUDA_ARCH_BIN])"
  echo ""
  echo "where SOURCE_DIR specifies the directory where the source should be"
  echo "cloned to, and INSTALL_DIR specifies the installation directory."
  echo ""
  echo "Optionally, a repository tag can be specified with -T to build a"
  echo "certain release (e.g. '3.4.1'). If not specified, the latest tag will"
  echo "be checked out; this may include pre-release versions."
  echo "The CMake variable CUDA_ARCH_BIN defaults to "5.2 6.1", but can be"
  echo "manually set via the -C option."
  echo ""
  echo "Example:"
  echo "  build_opencv.sh -s ~/devel -t $HOME/local/opencv"
  echo "OpenCV will then be cloned to and built in ~/devel/opencv, and"
  echo "installed to $HOME/local/opencv."
}

while getopts ":s:t:T:C:j:h" opt; do
  case ${opt} in
    s) CLONE_DIR=$OPTARG ;;
    t) INSTALL_DIR=$OPTARG ;;
    T) OPENCV_VERSION=$OPTARG ;;
    C) CUDA_ARCH_BIN=$OPTARG ;;
    j) NCPUS=$OPTARG ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; ARGERR=1 ;;
    \?) echo "Invalid option -$OPTARG"; ARGERR=1 ;;
  esac
done
[[ -z "$CLONE_DIR" ]] && { echo "Missing option -s"; ARGERR=1; }
[[ -z "$INSTALL_DIR" ]] && { echo "Missing option -t"; ARGERR=1; }
[[ -z "$CUDA_ARCH_BIN" ]] && { CUDA_ARCH_BIN="5.2 6.1"; }
[[ ! -z "$ARGERR" ]] && { print_help; exit 1; }

REPO_DIR=${CLONE_DIR}/opencv
CONTRIB_DIR=${CLONE_DIR}/opencv_contrib
BUILD_DIR=${REPO_DIR}/build
echo "Cloning to ${REPO_DIR} and ${CONTRIB_DIR}, and installing to ${INSTALL_DIR}..."
set -e
set -x

# Clone and get to clean slate
mkdir -p ${CLONE_DIR}
git -C ${CLONE_DIR} clone https://github.com/opencv/opencv.git || true
git -C ${REPO_DIR} clean -fxd
git -C ${REPO_DIR} checkout master
git -C ${REPO_DIR} pull --rebase

git -C ${CLONE_DIR} clone https://github.com/opencv/opencv_contrib.git || true
git -C ${CONTRIB_DIR} clean -fxd
git -C ${CONTRIB_DIR} checkout master
git -C ${CONTRIB_DIR} pull --rebase

# Get the tag of the latest released version
if [[ -z "$OPENCV_VERSION" ]]; then
  OPENCV_VERSION=$(git -C ${REPO_DIR} describe --abbrev=0 --tags)
fi
echo "OPENCV_VERSION=${OPENCV_VERSION}"
echo "CUDA_ARCH_BIN=${CUDA_ARCH_BIN}"

git -C ${REPO_DIR} checkout ${OPENCV_VERSION}
git -C ${CONTRIB_DIR} checkout ${OPENCV_VERSION}

# Compile and install
CMK_GENERATOR=""
if [ $(which ninja) ]; then
  CMK_GENERATOR="-G Ninja"
fi

CURRENT_DIR=$(pwd)
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

cmake \
  ${CMK_GENERATOR} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
  -DCUDA_ARCH_BIN=${CUDA_ARCH_BIN} \
  -DOPENCV_EXTRA_MODULES_PATH=${CONTRIB_DIR}/modules \
   ..

cmake --build ${BUILD_DIR} -- -j${NCPUS}
cmake --build ${BUILD_DIR} --target install || { echo "Attempting superuser installation"; sudo cmake --build ${BUILD_DIR} --target install; }

cd ${CURRENT_DIR}

