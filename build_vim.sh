#!/usr/bin/env bash

# Prerequisites, according to
# https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
#
# $ sudo apt-get install libncurses5-dev libgnome2-dev libgnomeui-dev \
#    libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
#    libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
#    python3-dev ruby-dev lua5.1 lua5.1-dev libperl-dev git

software_name="vim"
git_uri="https://github.com/vim/vim.git"

if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "Not tested on MacOS. Homebrew provides an up-to-date version of vim."
  echo "Exiting..."
  exit 1
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

while getopts ":s:t:T:j:Ch" opt; do
  case ${opt} in
    s) clone_dir=$OPTARG ;;
    t) install_dir=$OPTARG ;;
    T) git_tag=$OPTARG; echo "Using git_tag=${git_tag}" ;;
    j) nr_cpus=$OPTARG ;;
    C) opt_clean_install_dir=1 ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; arg_err=1 ;;
    \?) echo "Invalid option -$OPTARG"; arg_err=1 ;;
  esac
done
[[ ! -z "$arg_err" ]] && { print_help; exit 1; }

check_variables
clone_or_update_repo ${git_uri} ${repo_dir} ${git_tag}

# Compile and install
cd ${repo_dir}

./configure \
    --prefix=${install_dir} \
    --with-features=huge \
    --enable-multibyte \
    --enable-python3interp=yes \
    --enable-rubyinterp=yes \
    --enable-perlinterp=yes \
    --enable-luainterp=yes \
    --enable-cscope
    #--enable-gui=gtk2 \
make -j${nr_cpus}

[[ ! -z "${opt_clean_install_dir}" ]] && clean_install_dir ${install_dir}
make install || { echo "Attempting superuser installation"; sudo make install; }
