#!/usr/bin/env bash

# Ubuntu dependencies (see https://docs.opencv.org/master/d7/d9f/tutorial_linux_install.html):
# [compiler] sudo apt-get install build-essential
# [required] sudo apt-get install cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
# [optional] sudo apt-get install python-dev python-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev

if [[ "$(uname -s)" == "Darwin" ]]; then
  export nr_cpus=$(($(sysctl -n hw.ncpu)))
elif [[ "$(uname -s)" == "Linux" ]]; then
  export nr_cpus=$(($(nproc)))
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
    s) clone_dir=$OPTARG ;;
    t) install_dir=$OPTARG ;;
    T) OPENCV_VERSION=$OPTARG ;;
    C) CUDA_ARCH_BIN=$OPTARG ;;
    j) nr_cpus=$OPTARG ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; arg_err=1 ;;
    \?) echo "Invalid option -$OPTARG"; arg_err=1 ;;
  esac
done
[[ -z "$clone_dir" ]] && { echo "Missing option -s"; arg_err=1; }
[[ -z "$install_dir" ]] && { echo "Missing option -t"; arg_err=1; }
[[ -z "$CUDA_ARCH_BIN" ]] && { CUDA_ARCH_BIN="5.2 6.1"; }
[[ ! -z "$arg_err" ]] && { print_help; exit 1; }

repo_dir=${clone_dir}/opencv
CONTRIB_DIR=${clone_dir}/opencv_contrib
build_dir=${repo_dir}/build
echo "Cloning to ${repo_dir} and ${CONTRIB_DIR}, and installing to ${install_dir}..."
set -e
set -x

# Clone and get to clean slate
mkdir -p ${clone_dir}
git -C ${clone_dir} clone https://github.com/opencv/opencv.git || true
git -C ${repo_dir} clean -fxd
git -C ${repo_dir} checkout master
git -C ${repo_dir} pull --rebase

git -C ${clone_dir} clone https://github.com/opencv/opencv_contrib.git || true
git -C ${CONTRIB_DIR} clean -fxd
git -C ${CONTRIB_DIR} checkout master
git -C ${CONTRIB_DIR} pull --rebase

# Get the tag of the latest released version
if [[ -z "$OPENCV_VERSION" ]]; then
  OPENCV_VERSION=$(git -C ${repo_dir} describe --abbrev=0 --tags)
fi
echo "OPENCV_VERSION=${OPENCV_VERSION}"
echo "CUDA_ARCH_BIN=${CUDA_ARCH_BIN}"

git -C ${repo_dir} checkout ${OPENCV_VERSION}
git -C ${CONTRIB_DIR} checkout ${OPENCV_VERSION}

# Compile and install
CMK_GENERATOR=""
if [ $(which ninja) ]; then
  CMK_GENERATOR="-G Ninja"
fi

current_dir=$(pwd)
mkdir -p ${build_dir}
cd ${build_dir}

cmake \
  ${CMK_GENERATOR} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${install_dir} \
  -DCUDA_ARCH_BIN=${CUDA_ARCH_BIN} \
  -DOPENCV_EXTRA_MODULES_PATH=${CONTRIB_DIR}/modules \
   ..

cmake --build ${build_dir} -- -j${nr_cpus}
cmake --build ${build_dir} --target install || { echo "Attempting superuser installation"; sudo cmake --build ${build_dir} --target install; }

cd ${current_dir}

