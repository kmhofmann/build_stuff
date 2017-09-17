#!/bin/bash
set -e

echo "Installing prerequisite packages..."
if [ "$(uname -s)" == "Darwin" ]; then
  brew install swig cmake
  # TODO: maybe more on a fresh installation?
elif [ "$(uname -s)" == "Linux" ]; then
  sudo apt-get install build-essential autoconf doxygen swig libedit-dev cmake
fi

SWIG_VER=$(swig -version | grep SWIG | awk '{print $3}')
if [ "$SWIG_VER" == "3.0.9" ] ||  [ "$SWIG_VER" == "3.0.10" ]; then
  echo ""
  echo "WARNING: Swig versions 3.0.9 and 3.0.10 are incompatible with lldb."
  echo "Make sure you install a compatible version before compiling lldb."
fi
