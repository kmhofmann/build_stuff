#!/usr/bin/env bash

# TODO: user-configurable source and install directories

if [ "$(uname -s)" == "Darwin" ]; then
  export NCPUS=`sysctl -n hw.ncpu`
elif [ "$(uname -s)" == "Linux" ]; then
  export NCPUS=`nproc`
fi

CURRENT_DIR=$(pwd)
CLONE_DIR=$HOME/devel
REPO_DIR=${CLONE_DIR}/vim

INSTALL_DIR=$HOME/local
echo "Cloning to ${REPO_DIR}, and installing to ${INSTALL_DIR}..."
mkdir -p ${INSTALL_DIR}

git -C ${CLONE_DIR} clone https://github.com/vim/vim.git
git -C ${REPO_DIR} clean -fxd
git -C ${REPO_DIR} pull origin master --rebase
git -C ${REPO_DIR} checkout master
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