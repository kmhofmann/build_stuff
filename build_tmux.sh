#!/usr/bin/env bash

# sudo apt-get install automake pkg-config libevent-dev libncurses-dev bison

software_name="tmux"

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
    :) echo "Option -$OPTARG requires an argument."; ARGERR=1 ;;
    \?) echo "Invalid option -$OPTARG"; ARGERR=1 ;;
  esac
done
[[ ! -z "$ARGERR" ]] && { print_help; exit 1; }

check_variables
clone_or_update_repo \
  https://github.com/tmux/tmux.git \
  ${repo_dir} \
  ${git_tag}

# Compile and install
cd ${repo_dir}
sh autogen.sh
./configure --prefix=${install_dir}
make -j${nr_cpus}
make install || { echo "Attempting superuser installation"; sudo make install; }

