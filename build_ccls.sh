#!/usr/bin/env bash

# Ubuntu 18.04:
# sudo apt install clang clang-7 libclang-7-dev

software_name="ccls"

this_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source ${this_script_dir}/_utils/build_helper_functions.sh

init_build_script
get_default__nr_cpus
get_default__clone_dir
get_default__repo_dir ${software_name}
get_default__install_dir ${software_name}
get_default__git_tag

print_help_additional_options() {
  echo "          [-p <CLANG_PREFIX_PATH>]"
}

print_help_additional_options_description() {
  echo "  -p <CLANG_PREFIX_PATH>  Path where libclang is located. This path"
  echo "                          will be used as CMAKE_PREFIX_PATH and should"
  echo "                          the usual subdirectories: bin, include, lib, ..."
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
[[ ! -z "$arg_err" ]] && { print_help; exit 1; }

check_variables
clone_or_update_repo https://github.com/MaskRay/ccls.git ${repo_dir} ${git_tag}

# Compile and install
cmk_generator=""
if [ $(which ninja) ]; then
  cmk_generator="-G Ninja"
fi

build_dir=${repo_dir}/build
mkdir -p ${build_dir}
cd ${build_dir}

if [[ "$opt_clang_prefix_path" ]]; then
  cmake_clang_prefix_path=${opt_clang_prefix_path}
fi

cmake \
  ${cmk_generator} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${install_dir} \
  -DCMAKE_PREFIX_PATH=${cmake_clang_prefix_path} \
  ${repo_dir}

cmake --build ${build_dir} -- -j${nr_cpus}
cmake --build ${build_dir} --target install || { echo "Attempting superuser installation"; sudo cmake --build ${build_dir} --target install; }

