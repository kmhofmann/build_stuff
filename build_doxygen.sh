#!/usr/bin/env bash

# Dependencies (Ubuntu 19.10):
# sudo apt install graphviz clang-9 libclang-9-dev

software_name="doxygen"
git_uri="https://github.com/doxygen/doxygen.git"

this_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source ${this_script_dir}/_utils/build_helper_functions.sh

init_build_script
get_default__nr_cpus
get_default__clone_dir
get_default__repo_dir ${software_name}
get_default__install_dir ${software_name}
get_default__git_tag

print_help_additional_options() {
  :
}

print_help_additional_options_description() {
  :
}

while getopts ":s:t:T:j:Ch" opt; do
  case ${opt} in
    s) clone_dir=$OPTARG ;;
    t) install_dir=$OPTARG ;;
    T) git_tag=$OPTARG ;;
    j) nr_cpus=$OPTARG ;;
    C) opt_clean_install_dir=1 ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; arg_err=1 ;;
    \?) echo "Invalid option -$OPTARG"; arg_err=1 ;;
  esac
done
[[ -z "$clone_dir" ]] && { echo "Missing option -s"; arg_err=1; }
[[ -z "$install_dir" ]] && { echo "Missing option -t"; arg_err=1; }
[[ ! -z "$arg_err" ]] && { print_help; exit 1; }

check_variables
clone_or_update_repo ${git_uri} ${repo_dir} ${git_tag}

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
  -Duse_libclang=ON \
  ${repo_dir}

cmake --build ${build_dir} -- -j${nr_cpus}

[[ ! -z "${opt_clean_install_dir}" ]] && clean_install_dir ${install_dir}
cmake --build ${build_dir} --target install || { echo "Attempting superuser installation"; sudo cmake --build ${build_dir} --target install; }
