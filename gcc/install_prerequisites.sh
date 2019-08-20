#!/bin/bash
set -e

if [ "$(uname)" == "Darwin" ]; then
  echo "Downloading prerequisites not implemented for MacOS; proceed with build_gcc.sh."
elif [ "$(uname -s)" == "Linux" ]; then
  echo "Installing prerequisite packages..."
  sudo apt-get install build-essential g++ gcc-multilib \
    zip zlib1g-dev dejagnu tcl expect wget \
    libzstd-dev
fi
