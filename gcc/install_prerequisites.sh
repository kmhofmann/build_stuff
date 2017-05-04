#!/bin/bash

if [ "$(uname)" == "Darwin" ]; then
  echo "Not implemented for MacOS."
elif [ "$(uname -s)" == "Linux" ]; then
  echo "Installing prerequisite packages..."
  sudo apt-get install zlib1g-dev gcc-multilib zip #openjdk-8-jdk
fi
