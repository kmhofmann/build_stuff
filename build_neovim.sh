#!/usr/bin/env bash

# Prerequisites, according to
# https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
#
# $ sudo apt-get install libncurses5-dev libgnome2-dev libgnomeui-dev \
#    libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
#    libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
#    python3-dev ruby-dev lua5.1 lua5.1-dev libperl-dev git

if [[ "$(uname -s)" == "Darwin" ]]; then
  export nr_cpus=`sysctl -n hw.ncpu`
  echo "Not tested on MacOS. Homebrew provides an up-to-date version of Neovim."
  echo "Exiting..."
  exit 1
elif [[ "$(uname -s)" == "Linux" ]]; then
  export nr_cpus=`nproc`
fi

print_help()
{
  echo ""
  echo "Usage:"
  echo "  build_neovim.sh -s [SOURCE_DIR] -t [INSTALL_DIR] (-T [git_tag])"
  echo "where SOURCE_DIR specifies the directory where the source should be"
  echo "cloned to, and INSTALL_DIR specifies the installation directory."
  echo "Example:"
  echo "  build_neovim.sh -s ~/devel -t $HOME/local/neovim"
  echo "Neovim will then be cloned to and built in ~/devel/neovim, and installed"
  echo "to $HOME/local/neovim."
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

repo_dir=${clone_dir}/neovim
echo "Cloning to ${repo_dir}, and installing to ${install_dir}..."
set -e
set -x

# Clone and get to clean slate
mkdir -p ${clone_dir}
git -C ${clone_dir} clone https://github.com/neovim/neovim.git || true
git -C ${repo_dir} clean -fxd
git -C ${repo_dir} checkout master
git -C ${repo_dir} pull --rebase
if [ ! -z "$git_tag" ]; then
  git -C ${repo_dir} checkout ${git_tag}
fi

# Compile and install
current_dir=$(pwd)
mkdir -p ${install_dir}
cd ${repo_dir}

make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${install_dir}"
make install || { echo "Attempting superuser installation"; sudo make install; }

cd ${current_dir}
