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
  echo "  build_cquery.sh -s [SOURCE_DIR] -t [INSTALL_DIR]"
  echo ""
  echo "where SOURCE_DIR specifies the directory where the source should be"
  echo "cloned to, and INSTALL_DIR specifies the installation directory."
  echo ""
  echo "Example:"
  echo "  build_cquery.sh -s ~/devel -t $HOME/local/cmake"
  echo "cquery will then be cloned to and built in ~/devel/cquery, and"
  echo "installed to $HOME/local/cquery."
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
REPO_DIR=${CLONE_DIR}/cquery
echo "Cloning to ${REPO_DIR} and installing to ${INSTALL_DIR}..."

# Clone and get to clean slate
mkdir -p ${CLONE_DIR}
git -C ${CLONE_DIR} clone --recursive https://github.com/cquery-project/cquery.git || true
git -C ${REPO_DIR} submodule init
git -C ${REPO_DIR} submodule update
git -C ${REPO_DIR} reset HEAD --hard
git -C ${REPO_DIR} clean -fxd
git -C ${REPO_DIR} fetch
git -C ${REPO_DIR} checkout master
git -C ${REPO_DIR} pull

# Compile and install
CURRENT_DIR=$(pwd)

mkdir -p ${REPO_DIR}/build
cd ${REPO_DIR}/build
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  ..
make -j${NCPUS}
mkdir -p ${INSTALL_DIR}
make install || { echo "Attempting superuser installation"; sudo make install; }

cd ${CURRENT_DIR}
