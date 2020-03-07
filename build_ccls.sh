#!/usr/bin/env bash

# Ubuntu 18.04:
# sudo apt install clang clang-7 libclang-7-dev

if [[ "$(uname -s)" == "Darwin" ]]; then
  export nr_cpus=$(($(sysctl -n hw.ncpu)/2))
elif [[ "$(uname -s)" == "Linux" ]]; then
  export nr_cpus=$(($(nproc)/2))
fi

print_help()
{
  echo
  echo "Usage:"
  echo "  build_ccls.sh -s <SOURCE_DIR> -t <INSTALL_DIR> [-T <TAG>] [-p <CLANG_PREFIX_PATH>]"
  echo
  echo "where SOURCE_DIR specifies the directory where the source should be"
  echo "cloned to, and INSTALL_DIR specifies the installation directory."
  echo
  echo "Optionally, a repository tag can be specified with -T to build a"
  echo "certain release. If not specified, the latest commit from master"
  echo "will be checked out and built."
  echo
  echo "A path where libclang is located can be explicitly specified with the"
  echo "-p option. The designated path will be used as CMAKE_PREFIX_PATH and"
  echo "should have the usual subdirectories: bin, include, lib, ..."
  echo
  echo "Example:"
  echo "  build_ccls.sh -s ~/devel -t $HOME/local/cmake"
  echo "ccls will then be cloned to and built in ~/devel/ccls, and"
  echo "installed to $HOME/local/ccls."
}

while getopts ":s:t:T:j:p:h" opt; do
  case ${opt} in
    s) clone_dir=$OPTARG ;;
    t) install_dir=$OPTARG ;;
    T) git_tag=$OPTARG ;;
    j) nr_cpus=$OPTARG ;;
    p) opt_clang_prefix_path=$OPTARG ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; arg_err=1 ;;
    \?) echo "Invalid option -$OPTARG"; arg_err=1 ;;
  esac
done
[[ -z "$clone_dir" ]] && { echo "Missing option -s"; arg_err=1; }
[[ -z "$install_dir" ]] && { echo "Missing option -t"; arg_err=1; }
[[ ! -z "$arg_err" ]] && { print_help; exit 1; }

repo_dir=${clone_dir}/ccls
build_dir=${repo_dir}/build
echo "Cloning to ${repo_dir} and installing to ${install_dir}..."
set -e
set -x

# Clone and get to clean slate
mkdir -p ${clone_dir}
git -C ${clone_dir} clone --recursive https://github.com/MaskRay/ccls.git || true
git -C ${repo_dir} submodule init
git -C ${repo_dir} submodule update
git -C ${repo_dir} reset HEAD --hard
git -C ${repo_dir} clean -fxd
git -C ${repo_dir} checkout master
git -C ${repo_dir} pull --rebase

# Use user-specified tag, if applicable
if [[ ! -z "$git_tag" ]]; then
  echo "git_tag=${git_tag}"
  git -C ${repo_dir} checkout ${git_tag}
fi

# Compile and install
CMK_GENERATOR=""
if [ $(which ninja) ]; then
  CMK_GENERATOR="-G Ninja"
fi

current_dir=$(pwd)
mkdir -p ${build_dir}
cd ${build_dir}

if [[ "$opt_clang_prefix_path" ]]; then
  cmake_clang_prefix_path=${opt_clang_prefix_path}
fi

cmake \
  ${CMK_GENERATOR} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${install_dir} \
  -DCMAKE_PREFIX_PATH=${cmake_clang_prefix_path} \
  ${repo_dir}

cmake --build ${build_dir} -- -j${nr_cpus}
cmake --build ${build_dir} --target install || { echo "Attempting superuser installation"; sudo cmake --build ${build_dir} --target install; }

cd ${current_dir}
