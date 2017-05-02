#!/usr/bin/env bash

if [ "$(uname -s)" == "Darwin" ]; then
  export NCPUS=`sysctl -n hw.ncpu`
elif [ "$(uname -s)" == "Linux" ]; then
  export NCPUS=`nproc`
fi

# TODO: user-configurable source and install directories
CLONE_DIR=$HOME/devel
INSTALL_DIR=$HOME/local

echo "Cloning to ${REPO_DIR}, and installing to ${INSTALL_DIR}..."

# Clone and get to clean slate
mkdir -p ${CLONE_DIR}
git -C ${CLONE_DIR} clone https://github.com/tmux/tmux.git
REPO_DIR=${CLONE_DIR}/tmux
git -C ${REPO_DIR} clean -fxd
git -C ${REPO_DIR} pull origin master --rebase
TMUX_VERSION=$(git -C ${REPO_DIR} describe --abbrev=0 --tags)
git -C ${REPO_DIR} checkout ${TMUX_VERSION}

# Compile and install
CURRENT_DIR=$(pwd)
mkdir -p ${INSTALL_DIR}

cd ${REPO_DIR}
sh autogen.sh
./configure --prefix=${INSTALL_DIR} && make -j${NCPUS} && make install

cd ${CURRENT_DIR}
