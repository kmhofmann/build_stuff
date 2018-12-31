#!/bin/bash
set -e

echo "Installing prerequisite packages..."
if [ "$(uname -s)" == "Darwin" ]; then
  brew install swig cmake
  # TODO: maybe more on a fresh installation?
elif [ "$(uname -s)" == "Linux" ]; then
  sudo apt-get install build-essential autoconf doxygen swig libedit-dev cmake \
    subversion python3 libpython3-dev libxml2-dev libz3-dev libncurses-dev \
    ninja-build
fi
