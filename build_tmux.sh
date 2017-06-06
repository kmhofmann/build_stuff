#!/usr/bin/env bash

if [[ "$(uname -s)" == "Darwin" ]]; then
  export NCPUS=`sysctl -n hw.ncpu`
elif [[ "$(uname -s)" == "Linux" ]]; then
  export NCPUS=`nproc`
fi

print_help()
{
  echo ""
  echo "Usage:"
  echo "  build_tmux.sh -s [SOURCE_DIR] -t [INSTALL_DIR]"
  echo "where SOURCE_DIR specifies the directory where the source should be"
  echo "cloned to, and INSTALL_DIR specifies the installation directory."
  echo "Example:"
  echo "  build_tmux.sh -s ~/devel -t /usr/local"
  echo "tmux will then be cloned to and built in ~/devel/tmux, and installed"
  echo "to /usr/local."
}

while getopts ":s:t:h" opt; do
  case ${opt} in
    s) CLONE_DIR=$OPTARG ;;
    t) INSTALL_DIR=$OPTARG ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; ARGERR=1 ;;
    \?) echo "Invalid option -$OPTARG"; ARGERR=1 ;;
  esac
done
[[ -z "$CLONE_DIR" ]] && { echo "Missing option -s"; ARGERR=1; }
[[ -z "$INSTALL_DIR" ]] && { echo "Missing option -t"; ARGERR=1; }
[[ ! -z "$ARGERR" ]] && { print_help; exit 1; }

set -e
REPO_DIR=${CLONE_DIR}/tmux
echo "Cloning to ${REPO_DIR}, and installing to ${INSTALL_DIR}..."

# Clone and get to clean slate
mkdir -p ${CLONE_DIR}
git -C ${CLONE_DIR} clone https://github.com/tmux/tmux.git || true
git -C ${REPO_DIR} clean -fxd
git -C ${REPO_DIR} checkout master
git -C ${REPO_DIR} pull --rebase
# Check out the latest released version
TMUX_VERSION=$(git -C ${REPO_DIR} describe --abbrev=0 --tags)
git -C ${REPO_DIR} checkout ${TMUX_VERSION}

# Compile and install
CURRENT_DIR=$(pwd)
mkdir -p ${INSTALL_DIR}

cd ${REPO_DIR}
sh autogen.sh
./configure --prefix=${INSTALL_DIR}
make -j${NCPUS}
make install || { echo "Attempting superuser installation"; sudo make install; }

cd ${CURRENT_DIR}

