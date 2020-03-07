#!/usr/bin/env bash

software_name="cmus"

this_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source ${this_script_dir}/_utils/build_helper_functions.sh

init_build_script
get_default__nr_cpus
get_default__clone_dir
get_default__repo_dir ${software_name}
get_default__install_dir ${software_name}
git_tag="__LATEST__"

print_help_additional_options() {
  :
}

print_help_additional_options_description() {
  :
}

while getopts ":s:t:T:j:h" opt; do
  case ${opt} in
    s) clone_dir=$OPTARG ;;
    t) install_dir=$OPTARG ;;
    T) git_tag=$OPTARG ;;
    j) nr_cpus=$OPTARG ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; arg_err=1 ;;
    \?) echo "Invalid option -$OPTARG"; arg_err=1 ;;
  esac
done
[[ -z "$clone_dir" ]] && { echo "Missing option -s"; arg_err=1; }
[[ -z "$install_dir" ]] && { echo "Missing option -t"; arg_err=1; }
[[ ! -z "$arg_err" ]] && { print_help; exit 1; }

check_variables
clone_or_update_repo \
  https://github.com/cmus/cmus.git \
  ${repo_dir} \
  ${git_tag}

# Compile and install
cd ${repo_dir}
./configure prefix=${install_dir}
make -j${nr_cpus}
mkdir -p ${install_dir}
make install || { echo "Attempting superuser installation"; sudo make install; }

