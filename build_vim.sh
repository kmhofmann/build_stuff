#!/usr/bin/env bash

if [ "$(uname -s)" == "Darwin" ]; then
  export NCPUS=`sysctl -n hw.ncpu`
  echo "Not tested on MacOS. But why not use Homebrew? Exiting..."
  exit 1
elif [ "$(uname -s)" == "Linux" ]; then
  export NCPUS=`nproc`
fi

# TODO: user-configurable source and install directories
CLONE_DIR=$HOME/devel
INSTALL_DIR=$HOME/local

echo "Cloning to ${REPO_DIR}, and installing to ${INSTALL_DIR}..."

# Prerequisites, according to
# https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
#
# $ sudo apt-get install libncurses5-dev libgnome2-dev libgnomeui-dev \
#    libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
#    libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
#    python3-dev ruby-dev lua5.1 lua5.1-dev libperl-dev git

# Clone and get to clean slate
mkdir -p ${CLONE_DIR}
git -C ${CLONE_DIR} clone https://github.com/vim/vim.git
REPO_DIR=${CLONE_DIR}/vim
git -C ${REPO_DIR} clean -fxd
git -C ${REPO_DIR} pull origin master --rebase
git -C ${REPO_DIR} checkout master

# Compile and install
CURRENT_DIR=$(pwd)
mkdir -p ${INSTALL_DIR}
cd ${REPO_DIR}

./configure \
    --prefix=${INSTALL_DIR} \
    --with-features=huge \
    --enable-multibyte \
    --enable-python3interp=yes \
    --with-python3-config-dir=/usr/lib/python3.5/config \
    --enable-rubyinterp=yes \
    --enable-perlinterp=yes \
    --enable-luainterp=yes \
    --enable-gui=gtk2 \
    --enable-cscope \
    --prefix=${INSTALL_DIR}
make -j${NCPUS} && make install

cd ${CURRENT_DIR}
