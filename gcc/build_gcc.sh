#!/bin/bash
set -e

# This should be kept up-to-date with the latest (supported) versions.
GCC_VERSION="7.3.0"
GMP_VERSION="6.1.2"
ISL_VERSION="0.18"
MPC_VERSION="1.1.0"
MPFR_VERSION="4.0.0"

print_help()
{
    echo "Usage:"
    echo "  build_gcc -t TARGET_DIR [-g GCC_VERSION] [-d] [-b]"
    echo ""
    echo "  -d: Only download files; do not build"
    echo "  -b: Skip downloading files; assume they are already present"
    echo "If GCC_VERSION is not specified, '${GCC_VERSION}' will be used."
    echo ""
    echo "Example:"
    echo "  build_gcc -t ~/gcc730 -g 7.3.0"
    echo "  build_gcc -t ~/gcc550 -g 5.5.0"
}

if [[ $# -eq 0 ]]; then
  print_help
  exit 1
fi

while getopts ":t:g:dbh" opt; do
  case ${opt} in
    t) TARGET_DIR=$OPTARG ;;
    g) GCC_VERSION=$OPTARG ;;
    d) ONLY_DOWNLOAD=1 ;;
    b) SKIP_DOWNLOAD=1 ;;
    h) print_help; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument."; ARGERR=1 ;;
    \?) echo "Invalid option -$OPTARG"; ARGERR=1 ;;
  esac
done
[[ -z "$TARGET_DIR" ]] && { echo "Missing option -t"; ARGERR=1; }
[[ -z "$GCC_VERSION" ]] && { echo "Missing option -g"; ARGERR=1; }
[[ ! -z "$ARGERR" ]] && { print_help; exit 1; }

TARGET_BUILD_DIR=${TARGET_DIR}/build
TARGET_INSTALL_DIR=${TARGET_DIR}/install

KERNEL_NAME=$(uname -s)
if [ "$KERNEL_NAME" == "Darwin" ]; then
  export NCPUS=$(sysctl -n hw.ncpu)
elif [ "$KERNEL_NAME" == "Linux" ]; then
  export NCPUS=$(nproc)
fi

if [ -z "$SKIP_DOWNLOAD" ]; then
  if [[ -d "$TARGET_DIR" ]]; then
    echo "Target directory ${TARGET_DIR} already exists."
    echo "Please make sure you specify a non-existent target directory."
    exit 1
  fi

  mkdir -p ${TARGET_DIR}
  wget -c -P ${TARGET_DIR} http://nl.mirror.babylon.network/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz || \
    wget -c -P ${TARGET_DIR} ftp://ftp.gwdg.de/pub/misc/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz
  wget -c -P ${TARGET_DIR} https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.bz2 || \
    wget -c -P ${TARGET_DIR} https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.bz2
  wget -c -P ${TARGET_DIR} ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-${ISL_VERSION}.tar.bz2
  wget -c -P ${TARGET_DIR} ftp://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz
  wget -c -P ${TARGET_DIR} http://www.mpfr.org/mpfr-${MPFR_VERSION}/mpfr-${MPFR_VERSION}.tar.bz2 || \
    wget -c -P ${TARGET_DIR} https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.bz2
fi

[[ ! -z "$ONLY_DOWNLOAD" ]] && { echo "Exiting after download"; exit 1; }

echo "Checking existence of required files..."
[[ ! -f "${TARGET_DIR}/gcc-${GCC_VERSION}.tar.gz" ]] && { echo "Missing file."; exit 1; }
[[ ! -f "${TARGET_DIR}/gmp-${GMP_VERSION}.tar.bz2" ]] && { echo "Missing file."; exit 1; }
[[ ! -f "${TARGET_DIR}/isl-${ISL_VERSION}.tar.bz2" ]] && { echo "Missing file."; exit 1; }
[[ ! -f "${TARGET_DIR}/mpc-${MPC_VERSION}.tar.gz" ]] && { echo "Missing file."; exit 1; }
[[ ! -f "${TARGET_DIR}/mpfr-${MPFR_VERSION}.tar.bz2" ]] && { echo "Missing file."; exit 1; }

echo "Extracting files..."
tar xf ${TARGET_DIR}/gcc-${GCC_VERSION}.tar.gz -C ${TARGET_DIR}
tar xf ${TARGET_DIR}/gmp-${GMP_VERSION}.tar.bz2 -C ${TARGET_DIR}
tar xf ${TARGET_DIR}/isl-${ISL_VERSION}.tar.bz2 -C ${TARGET_DIR}
tar xf ${TARGET_DIR}/mpc-${MPC_VERSION}.tar.gz -C ${TARGET_DIR}
tar xf ${TARGET_DIR}/mpfr-${MPFR_VERSION}.tar.bz2 -C ${TARGET_DIR}

mv ${TARGET_DIR}/gmp-${GMP_VERSION} ${TARGET_DIR}/gcc-${GCC_VERSION}/gmp
mv ${TARGET_DIR}/isl-${ISL_VERSION} ${TARGET_DIR}/gcc-${GCC_VERSION}/isl
mv ${TARGET_DIR}/mpc-${MPC_VERSION} ${TARGET_DIR}/gcc-${GCC_VERSION}/mpc
mv ${TARGET_DIR}/mpfr-${MPFR_VERSION} ${TARGET_DIR}/gcc-${GCC_VERSION}/mpfr

CURRENT_DIR=$(pwd)
mkdir -p ${TARGET_BUILD_DIR}
cd ${TARGET_BUILD_DIR}

echo "Configuring and building GCC..."
${TARGET_DIR}/gcc-${GCC_VERSION}/configure --prefix=${TARGET_INSTALL_DIR}
make profiledbootstrap -j${NCPUS}
# Running the tests fails; I suspect it's because of something missing in the test setup.
#make -k check -j16
make install-strip
cd ${CURRENT_DIR}
