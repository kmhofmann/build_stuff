#!/usr/bin/env bash

if [[ "$(uname -s)" == "Darwin" ]]; then
  export nr_cpus=$(($(sysctl -n hw.ncpu)/2))
elif [[ "$(uname -s)" == "Linux" ]]; then
  export nr_cpus=$(($(nproc)/2))
fi

print_help()
{
  echo ""
  echo "Usage:"
  echo "  build_cmus.sh -s [SOURCE_DIR] -t [INSTALL_DIR] (-T [TAG])"
  echo ""
  echo "where SOURCE_DIR specifies the directory where the source should be"
  echo "cloned to, and INSTALL_DIR specifies the installation directory."
  echo ""
  echo "Optionally, a repository tag can be specified with -T to build a"
  echo "certain release. If not specified, the latest tag will be checked"
  echo "out; this may include pre-release versions."
  echo ""
  echo "Example:"
  echo "  build_cmus.sh -s ~/devel -t $HOME/local/cmus"
  echo "cmus will then be cloned to and built in ~/devel/cmus, and"
  echo "installed to $HOME/local/cmus."
}

while getopts ":s:t:T:C:j:h" opt; do
  case ${opt} in
    s) clone_dir=$OPTARG ;;
    t) install_dir=$OPTARG ;;
    T) CMUS_VERSION=$OPTARG ;;
    j) nr_cpus=$OPTARG ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; arg_err=1 ;;
    \?) echo "Invalid option -$OPTARG"; arg_err=1 ;;
  esac
done
[[ -z "$clone_dir" ]] && { echo "Missing option -s"; arg_err=1; }
[[ -z "$install_dir" ]] && { echo "Missing option -t"; arg_err=1; }
[[ ! -z "$arg_err" ]] && { print_help; exit 1; }

repo_dir=${clone_dir}/cmus
echo "Cloning to ${repo_dir} and installing to ${install_dir}..."
set -e
set -x

# Clone and get to clean slate
mkdir -p ${clone_dir}
git -C ${clone_dir} clone https://github.com/cmus/cmus.git || true
git -C ${repo_dir} reset HEAD --hard
git -C ${repo_dir} clean -fxd
git -C ${repo_dir} fetch

# Get the tag of the latest released version
#if [[ -z "$CMUS_VERSION" ]]; then
#  CMUS_VERSION=$(git -C ${repo_dir} describe --abbrev=0 --tags)
#fi

if [[ "$CMUS_VERSION" ]]; then
  echo "CMUS_VERSION=${CMUS_VERSION}"
  git -C ${repo_dir} checkout ${CMUS_VERSION}
else
  git -C ${repo_dir} checkout master
fi

# Compile and install
current_dir=$(pwd)

cd ${repo_dir}
./configure prefix=${install_dir}
make -j${nr_cpus}
mkdir -p ${install_dir}
make install || { echo "Attempting superuser installation"; sudo make install; }

cd ${current_dir}

