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
  echo "  build_fzy.sh -s [SOURCE_DIR] -t [INSTALL_DIR] (-T [TAG])"
  echo "where SOURCE_DIR specifies the directory where the source should be"
  echo "cloned to, and INSTALL_DIR specifies the installation directory."
  echo ""
  echo "Optionally, a repository tag can be specified with -T to build a"
  echo "certain release (e.g. '1.0'). If not specified, the latest"
  echo "be checked out; this may include pre-release versions."
  echo ""
  echo "Example:"
  echo "  build_fzy.sh -s ~/devel -t $HOME/local/fzy"
  echo "tmux will then be cloned to and built in ~/devel/fzy, and installed"
  echo "to $HOME/local/fzy."
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

REPO_DIR=${CLONE_DIR}/fzy
echo "Cloning to ${REPO_DIR}, and installing to ${INSTALL_DIR}..."
set -e
set -x

# Clone and get to clean slate
mkdir -p ${CLONE_DIR}
git -C ${CLONE_DIR} clone https://github.com/jhawthorn/fzy.git || true
git -C ${REPO_DIR} clean -fxd
git -C ${REPO_DIR} checkout master
git -C ${REPO_DIR} pull --rebase

# Check out the latest released version
if [[ -z "$GIT_TAG" ]]; then
  echo "Determining latest release tag..."
  GIT_TAG=$(git -C ${REPO_DIR} describe --abbrev=0 --tags --match "[0-9]*")
fi
echo "GIT_TAG=${GIT_TAG}"

git -C ${REPO_DIR} checkout ${GIT_TAG}

# Compile and install
CURRENT_DIR=$(pwd)

cd ${REPO_DIR}
export PREFIX=${INSTALL_DIR}
make -j${NCPUS}
make install || { echo "Attempting superuser installation"; sudo make install; }

cd ${CURRENT_DIR}
