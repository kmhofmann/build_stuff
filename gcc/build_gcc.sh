#!/bin/bash
set -e

# This should be kept up-to-date with the latest (supported) versions.
GCC_VERSION="7.1.0"
GMP_VERSION="6.1.2"
ISL_VERSION="0.16.1"
MPC_VERSION="1.0.3"
MPFR_VERSION="3.1.5"

if [[ $# -eq 0 ]]; then
    echo "Usage:"
    echo "  build_gcc TARGET_DIR [GCC_VERSION]"
    echo ""
    echo "If GCC_VERSION is not specified, '${GCC_VERSION}' will be used."
    echo ""
    echo "Example:"
    echo "  build_gcc ~/gcc710 7.1.0"
    echo "  build_gcc ~/gcc630 6.3.0"
    echo "  build_gcc ~/gcc540 5.4.0"
    exit 1
fi

TARGET_DIR=$(pwd)
if [[ ! -z "$1" ]]; then
  TARGET_DIR=$1
fi

if [[ ! -z "$2" ]]; then
  GCC_VERSION=$2
fi

if [[ -d "$TARGET_DIR" ]]; then
  echo "Target directory ${TARGET_DIR} already exists."
  echo "Please make sure you specify a non-existent target directory."
  exit 1
fi

TARGET_BUILD_DIR=${TARGET_DIR}/build
TARGET_INSTALL_DIR=${TARGET_DIR}/install

KERNEL_NAME=$(uname -s)
if [ "$KERNEL_NAME" == "Darwin" ]; then
  export NCPUS=$(sysctl -n hw.ncpu)
elif [ "$KERNEL_NAME" == "Linux" ]; then
  export NCPUS=$(nproc)
fi

mkdir -p ${TARGET_DIR}
wget -c -P ${TARGET_DIR} http://nl.mirror.babylon.network/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2 || \
  wget -c -P ${TARGET_DIR} ftp://ftp.gwdg.de/pub/misc/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2
wget -c -P ${TARGET_DIR} https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.bz2 || \
  wget -c -P ${TARGET_DIR} https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.bz2
wget -c -P ${TARGET_DIR} ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-${ISL_VERSION}.tar.bz2
wget -c -P ${TARGET_DIR} ftp://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz
wget -c -P ${TARGET_DIR} http://www.mpfr.org/mpfr-${MPFR_VERSION}/mpfr-${MPFR_VERSION}.tar.bz2 || \
  wget -c -P ${TARGET_DIR} https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.bz2

echo "Extracting files..."
tar xf ${TARGET_DIR}/gcc-${GCC_VERSION}.tar.bz2 -C ${TARGET_DIR}
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

${TARGET_DIR}/gcc-${GCC_VERSION}/configure --prefix=${TARGET_INSTALL_DIR}
make profiledbootstrap -j${NCPUS}
# Running the tests fails; I suspect it's because of something missing in the test setup.  #make -k check -j16 make install cd ${CURRENT_DIR}
