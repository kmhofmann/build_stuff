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
  echo "Not tested on MacOS. Homebrew provides an up-to-date version of Neovim."
  echo "Exiting..."
  exit 1
elif [[ "$(uname -s)" == "Linux" ]]; then
  export NCPUS=`nproc`
fi

print_help()
{
  echo ""
  echo "Usage:"
  echo "  build_neovim.sh -s [SOURCE_DIR] -t [INSTALL_DIR] (-T [GIT_TAG])"
  echo "where SOURCE_DIR specifies the directory where the source should be"
  echo "cloned to, and INSTALL_DIR specifies the installation directory."
  echo "Example:"
  echo "  build_neovim.sh -s ~/devel -t /usr/local"
  echo "Neovim will then be cloned to and built in ~/devel/neovim, and installed"
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
REPO_DIR=${CLONE_DIR}/neovim
echo "Cloning to ${REPO_DIR}, and installing to ${INSTALL_DIR}..."

# Clone and get to clean slate
mkdir -p ${CLONE_DIR}
git -C ${CLONE_DIR} clone https://github.com/neovim/neovim.git || true
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

make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}"
make install || { echo "Attempting superuser installation"; sudo make install; }
pip2 install --user --upgrade neovim
pip3 install --user --upgrade neovim

cd ${CURRENT_DIR}
