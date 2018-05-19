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
  echo "  build_cmus.sh -s [SOURCE_DIR] -t [INSTALL_DIR] (-T [TAG])"
  echo ""
  echo "where SOURCE_DIR specifies the directory where the source should be"
  echo "cloned to, and INSTALL_DIR specifies the installation directory."
  echo ""
  echo "Optionally, a repository tag can be specified with -T to build a"
  echo "certain release. If not specified, the latest tag will be checked"
  echo "out; this may include pre-release versions."
  echo ""
  echo "Example:"
  echo "  build_cmus.sh -s ~/devel -t $HOME/local/cmus"
  echo "cmus will then be cloned to and built in ~/devel/cmus, and"
  echo "installed to $HOME/local/cmus."
}

while getopts ":s:t:T:C:h" opt; do
  case ${opt} in
    s) CLONE_DIR=$OPTARG ;;
    t) INSTALL_DIR=$OPTARG ;;
    T) CMUS_VERSION=$OPTARG ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; ARGERR=1 ;;
    \?) echo "Invalid option -$OPTARG"; ARGERR=1 ;;
  esac
done
[[ -z "$CLONE_DIR" ]] && { echo "Missing option -s"; ARGERR=1; }
[[ -z "$INSTALL_DIR" ]] && { echo "Missing option -t"; ARGERR=1; }
[[ ! -z "$ARGERR" ]] && { print_help; exit 1; }

set -e
REPO_DIR=${CLONE_DIR}/cmus
echo "Cloning to ${REPO_DIR} and installing to ${INSTALL_DIR}..."

# Clone and get to clean slate
mkdir -p ${CLONE_DIR}
git -C ${CLONE_DIR} clone https://github.com/cmus/cmus.git || true
git -C ${REPO_DIR} reset HEAD --hard
git -C ${REPO_DIR} clean -fxd
git -C ${REPO_DIR} fetch

# Get the tag of the latest released version
#if [[ -z "$CMUS_VERSION" ]]; then
#  CMUS_VERSION=$(git -C ${REPO_DIR} describe --abbrev=0 --tags)
#fi

if [[ "$CMUS_VERSION" ]]; then
  echo "CMUS_VERSION=${CMUS_VERSION}"
  git -C ${REPO_DIR} checkout ${CMUS_VERSION}
else
  git -C ${REPO_DIR} checkout master
fi

# Compile and install
CURRENT_DIR=$(pwd)

cd ${REPO_DIR}
./configure prefix=${INSTALL_DIR}
make -j${NCPUS}
mkdir -p ${INSTALL_DIR}
make install || { echo "Attempting superuser installation"; sudo make install; }

cd ${CURRENT_DIR}

