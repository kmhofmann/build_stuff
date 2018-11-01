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
  echo "  build_cmake.sh -s [SOURCE_DIR] -t [INSTALL_DIR] (-T [TAG])"
  echo ""
  echo "where SOURCE_DIR specifies the directory where the source should be"
  echo "cloned to, and INSTALL_DIR specifies the installation directory."
  echo ""
  echo "Optionally, a repository tag can be specified with -T to build a"
  echo "certain release (e.g. 'v3.11.1'). If not specified, the latest tag will"
  echo "be checked out; this may include pre-release versions."
  echo ""
  echo "Example:"
  echo "  build_cmake.sh -s ~/devel -t $HOME/local/cmake"
  echo "CMake will then be cloned to and built in ~/devel/cmake, and"
  echo "installed to $HOME/local/cmake."
}

while getopts ":s:t:T:C:h" opt; do
  case ${opt} in
    s) CLONE_DIR=$OPTARG ;;
    t) INSTALL_DIR=$OPTARG ;;
    T) CMAKE_VERSION=$OPTARG ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; ARGERR=1 ;;
    \?) echo "Invalid option -$OPTARG"; ARGERR=1 ;;
  esac
done
[[ -z "$CLONE_DIR" ]] && { echo "Missing option -s"; ARGERR=1; }
[[ -z "$INSTALL_DIR" ]] && { echo "Missing option -t"; ARGERR=1; }
[[ ! -z "$ARGERR" ]] && { print_help; exit 1; }

set -e
REPO_DIR=${CLONE_DIR}/cmake
echo "Cloning to ${REPO_DIR} and installing to ${INSTALL_DIR}..."

# Clone and get to clean slate
mkdir -p ${CLONE_DIR}
git -C ${CLONE_DIR} clone https://gitlab.kitware.com/cmake/cmake.git || true
git -C ${REPO_DIR} clean -fxd
git -C ${REPO_DIR} checkout master
git -C ${REPO_DIR} pull --rebase

# Get the tag of the latest released version
if [[ -z "$CMAKE_VERSION" ]]; then
  echo "Determining latest release tag..."
  CMAKE_VERSION=$(git -C ${REPO_DIR} describe --abbrev=0 --tags)
fi
echo "CMAKE_VERSION=${CMAKE_VERSION}"

git -C ${REPO_DIR} checkout ${CMAKE_VERSION}

# Compile and install
CURRENT_DIR=$(pwd)

cd ${REPO_DIR}
./bootstrap --prefix=${INSTALL_DIR} --parallel=${NCPUS}
make -j${NCPUS}
mkdir -p ${INSTALL_DIR}
make install || { echo "Attempting superuser installation"; sudo make install; }

cd ${CURRENT_DIR}

