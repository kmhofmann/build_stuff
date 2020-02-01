#!/usr/bin/env bash
set -e

example_version='9.2.0'
example_tag='releases/gcc-'${example_version}

kernel_name=$(uname -s)
if [ "$kernel_name" == "Darwin" ]; then
  num_cpus=$(($(sysctl -n hw.ncpu)/1))
elif [ "$kernel_name" == "Linux" ]; then
  num_cpus=$(nproc)
fi

print_help()
{
  echo "Usage:"
  echo "  build_gcc -s <SRC_DIR> -t <INSTALL_DIR> [-T <TAG>] [-l <LANGS>] [-n] [-R]"
  echo
  echo "-s: Directory to which the source should be cloned to"
  echo "    (excluding name of the repository directory; e.g. \$HOME/devel)."
  echo "-t: Installation (target) directory."
  echo
  echo "-T: Git tag to check out (e.g. \"${example_tag}\"); otherwise uses 'master'."
  echo "-l: List languages to compile (e.g. \"c,c++,lto\"); default builds all."
  echo "-n: No profiled bootstrapping process (faster build, but potentially slower)."
  echo "-R: Run tests."
  echo
  echo "-C: Only check out repository, then exit."
  echo "-B: Skip checking out sources and downloading prerequisites; only build and install."
  echo
  echo "Example:"
  echo "  build_gcc -s ~/devel -t ~/local/gcc-${example_version} -T ${example_tag}"
}

if [[ $# -eq 0 ]]; then
  print_help
  exit 1
fi

while getopts ":s:t:b:T:l:nRCBh" opt; do
  case ${opt} in
    s) clone_dir=$OPTARG ;;
    t) install_dir=$OPTARG ;;
    T) git_tag=$OPTARG ;;
    l) enable_languages_str=$OPTARG ;;
    n) no_bootstrap=1 ;;
    R) run_tests=1 ;;
    C) only_checkout_repo=1 ;;
    B) only_build_install=1 ;;
    h) print_help; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument."; ARGERR=1 ;;
    \?) echo "Invalid option -$OPTARG"; ARGERR=1 ;;
  esac
done
[[ -z "$clone_dir" ]] && { echo "Missing option -s"; ARGERR=1; }
[[ -z "$install_dir" ]] && { echo "Missing option -t"; ARGERR=1; }
[[ ! -z "$ARGERR" ]] && { print_help; exit 1; }

MAKE_TARGET="profiledbootstrap"
if [ ! -z "${no_bootstrap}" ]; then
  DISABLE_BOOTSTRAP="--disable-bootstrap"
  MAKE_TARGET=""
fi

if [ ! -z "${enable_languages_str}" ]; then
  ENABLE_LANGUAGES="--enable-languages=${enable_languages_str}"
fi

repo_dir=${clone_dir}/gcc

echo "CC=${CC}"
echo "CXX=${CXX}"
echo "clone_dir=${clone_dir}"
echo "repo_dir=${repo_dir}"
echo "install_dir=${install_dir}"

function checkout_repo {
  # Clone and get to clean slate
  mkdir -p ${clone_dir}
  git -C ${clone_dir} clone git://gcc.gnu.org/git/gcc.git \
    || git -C ${clone_dir} clone https://gcc.gnu.org/git/gcc.git \
    || true
  git -C ${repo_dir} reset HEAD --hard
  git -C ${repo_dir} clean -fxd
  git -C ${repo_dir} checkout master
  git -C ${repo_dir} pull --rebase

  # Use user-specified tag, if applicable
  if [[ ! -z "${git_tag}" ]]; then
    echo "git_tag=${git_tag}"
    git -C ${repo_dir} checkout ${git_tag}
  fi
}

function get_prerequisites {
  cd ${repo_dir}

  echo "Downloading dependencies..."
  ./contrib/download_prerequisites
}

function configure_build_install {
  cd ${repo_dir}

  echo "Configuring and building GCC..."
  ./configure --prefix=${install_dir} ${DISABLE_BOOTSTRAP} ${ENABLE_LANGUAGES}
  make ${MAKE_TARGET} -j${num_cpus}

  if [ ! -z "${run_tests}" ]; then
    # Running the tests fails; I suspect it's because of something missing in the test setup.
    make -k check -j${num_cpus}
  fi

  echo "Installing GCC..."
  #make install-strip
  make install
}

current_dir=$(pwd)

if [ ! "${only_build_install}" ]; then
  checkout_repo

  if [ "${only_checkout_repo}" ]; then
    echo "Checked out repository; exiting now."
    exit 0
  fi

  get_prerequisites
fi

configure_build_install

cd ${current_dir}
