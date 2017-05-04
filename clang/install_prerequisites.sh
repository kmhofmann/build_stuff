#!/bin/bash

echo "Installing prerequisite packages..."
if [ "$(uname -s)" == "Darwin" ]; then
  brew install swig
elif [ "$(uname -s)" == "Linux" ]; then
  sudo apt-get install autoconf doxygen swig libedit-dev
fi
