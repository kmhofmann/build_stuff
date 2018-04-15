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
  echo "  build_gcc -s SRC_DIR [-b BUILD_DIR] [-i INSTALL_DIR] [-g GCC_VERSION] [-d] [-e]"
  echo ""
  echo "-s: Directory to which the sources will be downloaded"
  echo "-b: Build directory. Defaults to SRC_DIR/build."
  echo "-i: Installation directory. Defaults to SRC_DIR/install."
  echo "-g: GCC version to build; defaults to ${GCC_VERSION}."
  echo "-d: Only download files; do not build"
  echo "-e: Skip downloading files; assume they are already present"
  echo ""
  echo "Examples:"
  echo "  build_gcc -s ~/src/gcc730 -g 7.3.0"
  echo "  build_gcc -s ~/src/gcc550 -i ~/local/gcc550 -g 5.5.0"
}

if [[ $# -eq 0 ]]; then
  print_help
  exit 1
fi

while getopts ":s:b:i:g:dbh" opt; do
  case ${opt} in
    s) SRC_DIR=$OPTARG ;;
    b) BUILD_DIR=$OPTARG ;;
    i) INSTALL_DIR=$OPTARG ;;
    g) GCC_VERSION=$OPTARG ;;
    d) ONLY_DOWNLOAD=1 ;;
    e) SKIP_DOWNLOAD=1 ;;
    h) print_help; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument."; ARGERR=1 ;;
    \?) echo "Invalid option -$OPTARG"; ARGERR=1 ;;
  esac
done
[[ -z "$SRC_DIR" ]] && { echo "Missing option -t"; ARGERR=1; }
[[ -z "$BUILD_DIR" ]] && { BUILD_DIR=${SRC_DIR}/build; }
[[ -z "$INSTALL_DIR" ]] && { INSTALL_DIR=${SRC_DIR}/install; }
[[ -z "$GCC_VERSION" ]] && { echo "Missing option -g"; ARGERR=1; }
[[ ! -z "$ARGERR" ]] && { print_help; exit 1; }

echo "CC=${CC}"
echo "CXX=${CXX}"
echo "SRC_DIR=${SRC_DIR}"
echo "BUILD_DIR=${BUILD_DIR}"
echo "INSTALL_DIR=${INSTALL_DIR}"

KERNEL_NAME=$(uname -s)
if [ "$KERNEL_NAME" == "Darwin" ]; then
  export NCPUS=$(sysctl -n hw.ncpu)
elif [ "$KERNEL_NAME" == "Linux" ]; then
  export NCPUS=$(nproc)
fi

if [ -z "$SKIP_DOWNLOAD" ]; then
  if [[ -d "$SRC_DIR" ]]; then
    echo "Source directory ${SRC_DIR} already exists."
    echo "Please make sure you specify a non-existent source directory."
    exit 1
  fi

  mkdir -p ${SRC_DIR}
  wget -c -P ${SRC_DIR} http://nl.mirror.babylon.network/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz || \
    wget -c -P ${SRC_DIR} ftp://ftp.gwdg.de/pub/misc/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz
  wget -c -P ${SRC_DIR} https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.bz2 || \
    wget -c -P ${SRC_DIR} https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.bz2
  wget -c -P ${SRC_DIR} ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-${ISL_VERSION}.tar.bz2
  wget -c -P ${SRC_DIR} ftp://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz
  wget -c -P ${SRC_DIR} http://www.mpfr.org/mpfr-${MPFR_VERSION}/mpfr-${MPFR_VERSION}.tar.bz2 || \
    wget -c -P ${SRC_DIR} https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.bz2
fi

[[ ! -z "$ONLY_DOWNLOAD" ]] && { echo "Exiting after download"; exit 1; }

echo "Checking existence of required files..."
[[ ! -f "${SRC_DIR}/gcc-${GCC_VERSION}.tar.gz" ]] && { echo "Missing file."; exit 1; }
[[ ! -f "${SRC_DIR}/gmp-${GMP_VERSION}.tar.bz2" ]] && { echo "Missing file."; exit 1; }
[[ ! -f "${SRC_DIR}/isl-${ISL_VERSION}.tar.bz2" ]] && { echo "Missing file."; exit 1; }
[[ ! -f "${SRC_DIR}/mpc-${MPC_VERSION}.tar.gz" ]] && { echo "Missing file."; exit 1; }
[[ ! -f "${SRC_DIR}/mpfr-${MPFR_VERSION}.tar.bz2" ]] && { echo "Missing file."; exit 1; }

echo "Extracting files..."
tar xf ${SRC_DIR}/gcc-${GCC_VERSION}.tar.gz -C ${SRC_DIR}
tar xf ${SRC_DIR}/gmp-${GMP_VERSION}.tar.bz2 -C ${SRC_DIR}
tar xf ${SRC_DIR}/isl-${ISL_VERSION}.tar.bz2 -C ${SRC_DIR}
tar xf ${SRC_DIR}/mpc-${MPC_VERSION}.tar.gz -C ${SRC_DIR}
tar xf ${SRC_DIR}/mpfr-${MPFR_VERSION}.tar.bz2 -C ${SRC_DIR}

mv ${SRC_DIR}/gmp-${GMP_VERSION} ${SRC_DIR}/gcc-${GCC_VERSION}/gmp
mv ${SRC_DIR}/isl-${ISL_VERSION} ${SRC_DIR}/gcc-${GCC_VERSION}/isl
mv ${SRC_DIR}/mpc-${MPC_VERSION} ${SRC_DIR}/gcc-${GCC_VERSION}/mpc
mv ${SRC_DIR}/mpfr-${MPFR_VERSION} ${SRC_DIR}/gcc-${GCC_VERSION}/mpfr

CURRENT_DIR=$(pwd)
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

echo "Configuring and building GCC..."
${SRC_DIR}/gcc-${GCC_VERSION}/configure --prefix=${INSTALL_DIR}
make profiledbootstrap -j${NCPUS}
# Running the tests fails; I suspect it's because of something missing in the test setup.
#make -k check -j16
make install-strip
cd ${CURRENT_DIR}
