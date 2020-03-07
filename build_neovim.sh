#!/usr/bin/env bash

# Prerequisites, according to
# https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
#
# $ sudo apt-get install libncurses5-dev libgnome2-dev libgnomeui-dev \
#    libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
#    libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
#    python3-dev ruby-dev lua5.1 lua5.1-dev libperl-dev git

software_name="neovim"

if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "Not tested on MacOS. Homebrew provides an up-to-date version of Neovim."
  echo "Exiting..."
fi

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

while getopts ":s:t:T:j:h" opt; do
  case ${opt} in
    s) clone_dir=$OPTARG ;;
    t) install_dir=$OPTARG ;;
    T) git_tag=$OPTARG; echo "Using git_tag=${git_tag}" ;;
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
  https://github.com/neovim/neovim.git \
  ${repo_dir} \
  ${git_tag}

# Compile and install
mkdir -p ${install_dir}
cd ${repo_dir}

make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${install_dir}"
make install || { echo "Attempting superuser installation"; sudo make install; }

