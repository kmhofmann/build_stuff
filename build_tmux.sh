#!/usr/bin/env bash

# TODO: user-configurable source and install directories

if [ "$(uname -s)" == "Darwin" ]; then
  export NCPUS=`sysctl -n hw.ncpu`
elif [ "$(uname -s)" == "Linux" ]; then
  export NCPUS=`nproc`
fi

CURRENT_DIR=$(pwd)
CLONE_DIR=$HOME/devel
REPO_DIR=${CLONE_DIR}/tmux

INSTALL_DIR=$HOME/local
echo "Cloning to ${REPO_DIR}, and installing to ${INSTALL_DIR}..."
mkdir -p ${INSTALL_DIR}

git -C ${CLONE_DIR} clone https://github.com/tmux/tmux.git
git -C ${REPO_DIR} clean -fxd
git -C ${REPO_DIR} pull origin master --rebase
TMUX_VERSION=$(git -C ${REPO_DIR} describe --abbrev=0 --tags)
git -C ${REPO_DIR} checkout ${TMUX_VERSION}
cd ${REPO_DIR}
sh autogen.sh
./configure --prefix=${INSTALL_DIR} && make -j${NCPUS} && make installs
cd ${CURRENT_DIR}