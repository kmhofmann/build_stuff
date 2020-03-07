#!/usr/bin/env bash

if [[ "$(uname -s)" == "Darwin" ]]; then
  export nr_cpus=`sysctl -n hw.ncpu`
elif [[ "$(uname -s)" == "Linux" ]]; then
  export nr_cpus=`nproc`
fi

print_help()
{
  echo ""
  echo "Usage:"
  echo "  build_fzy.sh -s [SOURCE_DIR] -t [INSTALL_DIR] (-T [TAG])"
  echo "where SOURCE_DIR specifies the directory where the source should be"
  echo "cloned to, and INSTALL_DIR specifies the installation directory."
  echo ""
  echo "Optionally, a repository tag can be specified with -T to build a"
  echo "certain release (e.g. '1.0'). If not specified, the latest"
  echo "be checked out; this may include pre-release versions."
  echo ""
  echo "Example:"
  echo "  build_fzy.sh -s ~/devel -t $HOME/local/fzy"
  echo "tmux will then be cloned to and built in ~/devel/fzy, and installed"
  echo "to $HOME/local/fzy."
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

repo_dir=${clone_dir}/fzy
echo "Cloning to ${repo_dir}, and installing to ${install_dir}..."
set -e
set -x

# Clone and get to clean slate
mkdir -p ${clone_dir}
git -C ${clone_dir} clone https://github.com/jhawthorn/fzy.git || true
git -C ${repo_dir} clean -fxd
git -C ${repo_dir} checkout master
git -C ${repo_dir} pull --rebase

# Check out the latest released version
if [[ -z "$git_tag" ]]; then
  echo "Determining latest release tag..."
  git_tag=$(git -C ${repo_dir} describe --abbrev=0 --tags --match "[0-9]*")
fi
echo "git_tag=${git_tag}"

git -C ${repo_dir} checkout ${git_tag}

# Compile and install
current_dir=$(pwd)

cd ${repo_dir}
export PREFIX=${install_dir}
make -j${nr_cpus}
make install || { echo "Attempting superuser installation"; sudo make install; }

cd ${current_dir}

