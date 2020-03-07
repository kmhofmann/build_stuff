#!/usr/bin/env bash

# sudo apt install libssl-dev

if [[ "$(uname -s)" == "Darwin" ]]; then
  export nr_cpus=$(($(sysctl -n hw.ncpu)/2))
elif [[ "$(uname -s)" == "Linux" ]]; then
  export nr_cpus=$(($(nproc)/2))
fi

print_help()
{
  echo ""
  echo "Usage:"
  echo "  build_cmake.sh -s [SOURCE_DIR] -t [INSTALL_DIR] (-T [TAG])"
  echo ""
  echo "where SOURCE_DIR specifies the directory where the source should be"
  echo "cloned to, and INSTALL_DIR specifies the installation directory."
  echo ""
  echo "Optionally, a repository tag can be specified with -T to build a"
  echo "certain release (e.g. 'v3.11.1'). If not specified, the latest tag will"
  echo "be checked out; this may include pre-release versions."
  echo ""
  echo "Example:"
  echo "  build_cmake.sh -s ~/devel -t $HOME/local/cmake"
  echo "CMake will then be cloned to and built in ~/devel/cmake, and"
  echo "installed to $HOME/local/cmake."
  echo ""
  echo "Check https://gitlab.kitware.com/cmake/cmake/tags for tags."
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

repo_dir=${clone_dir}/cmake
echo "Cloning to ${repo_dir} and installing to ${install_dir}..."
set -e
set -x

# Clone and get to clean slate
mkdir -p ${clone_dir}
git -C ${clone_dir} clone https://gitlab.kitware.com/cmake/cmake.git || true
git -C ${repo_dir} clean -fxd
git -C ${repo_dir} checkout master
git -C ${repo_dir} pull --rebase

# Get the tag of the latest released version
if [[ -z "$git_tag" ]]; then
  echo "Determining latest release tag..."
  git_tag=$(git -C ${repo_dir} describe --abbrev=0 --tags)
fi
echo "git_tag=${git_tag}"

git -C ${repo_dir} checkout ${git_tag}

# Compile and install
current_dir=$(pwd)

cd ${repo_dir}
./bootstrap --prefix=${install_dir} --parallel=${nr_cpus}
make -j${nr_cpus}
mkdir -p ${install_dir}
make install || { echo "Attempting superuser installation"; sudo make install; }

cd ${current_dir}

