#!/usr/bin/env bash

if [[ "$(uname -s)" == "Darwin" ]]; then
  export NCPUS=$(($(sysctl -n hw.ncpu)/2))
elif [[ "$(uname -s)" == "Linux" ]]; then
  export NCPUS=$(($(nproc)/2))
fi

print_help()
{
  echo ""
  echo "Usage:"
  echo "  build_ccls.sh -s [SOURCE_DIR] -t [INSTALL_DIR] (-T [TAG])"
  echo ""
  echo "where SOURCE_DIR specifies the directory where the source should be"
  echo "cloned to, and INSTALL_DIR specifies the installation directory."
  echo ""
  echo "Optionally, a repository tag can be specified with -T to build a"
  echo "certain release. If not specified, the latest commit from master"
  echo "will be checked out and built."
  echo ""
  echo "Example:"
  echo "  build_ccls.sh -s ~/devel -t $HOME/local/cmake"
  echo "ccls will then be cloned to and built in ~/devel/ccls, and"
  echo "installed to $HOME/local/ccls."
}

while getopts ":s:t:T:j:h" opt; do
  case ${opt} in
    s) CLONE_DIR=$OPTARG ;;
    t) INSTALL_DIR=$OPTARG ;;
    T) GIT_TAG=$OPTARG ;;
    j) NCPUS=$OPTARG ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; ARGERR=1 ;;
    \?) echo "Invalid option -$OPTARG"; ARGERR=1 ;;
  esac
done
[[ -z "$CLONE_DIR" ]] && { echo "Missing option -s"; ARGERR=1; }
[[ -z "$INSTALL_DIR" ]] && { echo "Missing option -t"; ARGERR=1; }
[[ ! -z "$ARGERR" ]] && { print_help; exit 1; }

REPO_DIR=${CLONE_DIR}/ccls
BUILD_DIR=${REPO_DIR}/build
echo "Cloning to ${REPO_DIR} and installing to ${INSTALL_DIR}..."
set -e
set -x

# Clone and get to clean slate
mkdir -p ${CLONE_DIR}
git -C ${CLONE_DIR} clone --recursive https://github.com/MaskRay/ccls.git || true
git -C ${REPO_DIR} submodule init
git -C ${REPO_DIR} submodule update
git -C ${REPO_DIR} reset HEAD --hard
git -C ${REPO_DIR} clean -fxd
git -C ${REPO_DIR} checkout master
git -C ${REPO_DIR} pull --rebase

# Use user-specified tag, if applicable
if [[ ! -z "$GIT_TAG" ]]; then
  echo "GIT_TAG=${GIT_TAG}"
  git -C ${REPO_DIR} checkout ${GIT_TAG}
fi

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
  -DCMAKE_PREFIX_PATH=$(dirname $(dirname $(which clang))) \
  ${REPO_DIR}

cmake --build ${BUILD_DIR} -- -j${NCPUS}
cmake --build ${BUILD_DIR} --target install || { echo "Attempting superuser installation"; sudo cmake --build ${BUILD_DIR} --target install; }

cd ${CURRENT_DIR}
