#!/usr/bin/env bash

# Ubuntu dependencies (see https://docs.opencv.org/master/d7/d9f/tutorial_linux_install.html):
# [compiler] sudo apt-get install build-essential
# [required] sudo apt-get install cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
# [optional] sudo apt-get install python-dev python-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev

software_name="opencv"
git_uri="https://github.com/opencv/opencv.git"
git_uri_contrib="https://github.com/opencv/opencv_contrib.git"

this_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source ${this_script_dir}/_utils/build_helper_functions.sh

init_build_script
get_default__nr_cpus
get_default__clone_dir
get_default__install_dir ${software_name}
get_default__git_tag
cuda_arch_bin="5.2 6.1"

print_help_additional_options() {
  echo "          [-C <CUDA_ARCH_BIN>]"
}

print_help_additional_options_description() {
  echo "  -A <CUDA_ARCH_BIN>  CMake variable determining the CUDA core architecture."
  echo "                      Defaults to "${cuda_arch_bin}"."
}

while getopts ":s:t:T:A:j:Ch" opt; do
  case ${opt} in
    s) clone_dir=$OPTARG ;;
    t) install_dir=$OPTARG ;;
    T) git_tag=$OPTARG ;;
    A) cuda_arch_bin=$OPTARG ;;
    j) nr_cpus=$OPTARG ;;
    C) opt_clean_install_dir=1 ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; arg_err=1 ;;
    \?) echo "Invalid option -$OPTARG"; arg_err=1 ;;
  esac
done
[[ ! -z "$arg_err" ]] && { print_help; exit 1; }

repo_dir=${clone_dir}/opencv
contrib_dir=${clone_dir}/opencv_contrib

check_variables
clone_or_update_repo ${git_uri} ${repo_dir} ${git_tag}
clone_or_update_repo ${git_uri_contrib} ${contrib_dir} ${git_tag}

echo "cuda_arch_bin=${cuda_arch_bin}"

# Compile and install
cmake_generator=""
if [ $(which ninja) ]; then
  cmake_generator="-G Ninja"
fi

build_dir=${repo_dir}/build
mkdir -p ${build_dir}
cd ${build_dir}

cmake \
  ${cmake_generator} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${install_dir} \
  -Dcuda_arch_bin=${cuda_arch_bin} \
  -DOPENCV_EXTRA_MODULES_PATH=${contrib_dir}/modules \
   ..

cmake --build ${build_dir} -- -j${nr_cpus}

[[ ! -z "${opt_clean_install_dir}" ]] && clean_install_dir ${install_dir}
cmake --build ${build_dir} --target install || { echo "Attempting superuser installation"; sudo cmake --build ${build_dir} --target install; }

