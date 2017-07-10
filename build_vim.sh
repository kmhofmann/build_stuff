#!/usr/bin/env bash

# Prerequisites, according to
# https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
#
# $ sudo apt-get install libncurses5-dev libgnome2-dev libgnomeui-dev \
#    libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
#    libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
#    python3-dev ruby-dev lua5.1 lua5.1-dev libperl-dev git

if [[ "$(uname -s)" == "Darwin" ]]; then
  export NCPUS=`sysctl -n hw.ncpu`
  echo "Not tested on MacOS. Homebrew provides an up-to-date version of vim."
  echo "Exiting..."
  exit 1
elif [[ "$(uname -s)" == "Linux" ]]; then
  export NCPUS=`nproc`
fi

print_help()
{
  echo ""
  echo "Usage:"
  echo "  build_vim.sh -s [SOURCE_DIR] -t [INSTALL_DIR] (-T [GIT_TAG])"
  echo "where SOURCE_DIR specifies the directory where the source should be"
  echo "cloned to, and INSTALL_DIR specifies the installation directory."
  echo "Example:"
  echo "  build_vim.sh -s ~/devel -t /usr/local"
  echo "vim will then be cloned to and built in ~/devel/vim, and installed"
  echo "to /usr/local."
}

while getopts ":s:t:T:h" opt; do
  case ${opt} in
    s) CLONE_DIR=$OPTARG ;;
    t) INSTALL_DIR=$OPTARG ;;
    T) GIT_TAG=$OPTARG; echo "Using GIT_TAG=${GIT_TAG}" ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; ARGERR=1 ;;
    \?) echo "Invalid option -$OPTARG"; ARGERR=1 ;;
  esac
done
[[ -z "$CLONE_DIR" ]] && { echo "Missing option -s"; ARGERR=1; }
[[ -z "$INSTALL_DIR" ]] && { echo "Missing option -t"; ARGERR=1; }
[[ ! -z "$ARGERR" ]] && { print_help; exit 1; }

set -e
REPO_DIR=${CLONE_DIR}/vim
echo "Cloning to ${REPO_DIR}, and installing to ${INSTALL_DIR}..."

# Clone and get to clean slate
mkdir -p ${CLONE_DIR}
git -C ${CLONE_DIR} clone https://github.com/vim/vim.git || true
git -C ${REPO_DIR} clean -fxd
git -C ${REPO_DIR} checkout master
git -C ${REPO_DIR} pull --rebase
if [ ! -z "$GIT_TAG" ]; then
  git -C ${REPO_DIR} checkout ${GIT_TAG}
fi

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
    --enable-cscope
make -j${NCPUS}
make install || { echo "Attempting superuser installation"; sudo make install; }

cd ${CURRENT_DIR}
