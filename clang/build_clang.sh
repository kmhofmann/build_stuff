#!/bin/bash

# NOTE: to sucessfully build lldb on Mac OS X, you will have to do this:
# https://llvm.org/svn/llvm-project/lldb/trunk/docs/code-signing.txt

print_help()
{
  echo ""
  echo "Usage:"
  echo "  build_clang.sh -s SRC_DIR [-b BUILD_DIR] [-i INSTALL_DIR) [-t) [-u]"
  echo ""
  echo "-s: Directory in which the source has been checked out."
  echo "-b: Build directory. Defaults to SRC_DIR/build."
  echo "-i: Installation directory. Defaults to SRC_DIR/install."
  echo "-t: Perform Clang regression tests."
  echo "-u: Perform libc++ regression tests."
  echo ""
  echo "CC and CXX determine the compiler to be used."
}

while getopts ":s:b:i:tuh" opt; do
  case ${opt} in
    s) SRC_DIR=$OPTARG ;;
    b) BUILD_DIR=$OPTARG ;;
    i) INSTALL_DIR=$OPTARG ;;
    t) TEST_CLANG=1 ;;
    u) TEST_LIBCXX=1 ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; ARGERR=1 ;;
    \?) echo "Invalid option -$OPTARG"; ARGERR=1 ;;
  esac
done
[[ -z "$SRC_DIR" ]] && { echo "Missing option -s"; ARGERR=1; }
[[ -z "$BUILD_DIR" ]] && { BUILD_DIR=${SRC_DIR}/build; }
[[ -z "$INSTALL_DIR" ]] && { INSTALL_DIR=${SRC_DIR}/install; }
[[ "$ARGERR" ]] && { print_help; exit 1; }

set -e

CURRENT_DIR=$(pwd)

KERNEL_NAME=$(uname -s)
if [[ "$KERNEL_NAME" == "Darwin" ]]; then
  export NCPUS=$(sysctl -n hw.ncpu)
elif [[ "$KERNEL_NAME" == "Linux" ]]; then
  export NCPUS=$(nproc)

  export GCCDIR=$(dirname $(which gcc))/../
  export GCC_CMAKE_OPTION="-DGCC_INSTALL_PREFIX=$GCCDIR"
fi

SWIG_EXE=$(which swig) || true
if [[ -z "${SWIG_EXE}" ]]; then
  echo "ERROR: SWIG was not found on the system. Please install SWIG, except"
  echo "for versions 3.0.9 or 3.0.10, which are known to be incompatible with"
  echo "lldb."
  exit 0
fi
SWIG_VER=$(${SWIG_EXE} -version | grep SWIG | awk '{print $3}')
if [[ "$SWIG_VER" == "3.0.9" ]] ||  [[ "$SWIG_VER" == "3.0.10" ]]; then
  echo "ERROR: Swig versions 3.0.9 and 3.0.10 are incompatible with lldb."
  echo "SWIG ${SWIG_VER} was found in ${SWIG_EXE}."
  echo "Make sure you install a compatible version before compiling lldb."
  exit 0
fi

echo "CC=${CC}"
echo "CXX=${CXX}"
echo "SRC_DIR=${SRC_DIR}"
echo "BUILD_DIR=${BUILD_DIR}"
echo "INSTALL_DIR=${INSTALL_DIR}"

# Build LLVM/Clang
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
  -DSWIG_EXECUTABLE=${SWIG_EXE} \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DLIBCXXABI_ENABLE_ASSERTIONS=OFF \
  -DLIBCXX_ENABLE_ASSERTIONS=OFF \
  ${GCC_CMAKE_OPTION} \
  ${SRC_DIR}/llvm
make -j${NCPUS}
if [[ "${TEST_CLANG}" ]]; then
  make check-clang -j${NCPUS}
fi
make install

cd ${SRC_DIR}

# Build libcxx(abi) with the freshly built Clang
if [[ "$KERNEL_NAME" == "Linux" ]]; then
  # Export relevant environment variables to be able to call Clang
  export PATH=${INSTALL_DIR}/bin:$PATH
  export LD_LIBRARY_PATH=${INSTALL_DIR}/lib:${LD_LIBRARY_PATH}

  # Build libcxxabi
  mkdir -p ${BUILD_DIR}/libcxxabi_build
  cd ${BUILD_DIR}/libcxxabi_build

  CC=${INSTALL_DIR}/bin/clang CXX=${INSTALL_DIR}/bin/clang++ cmake \
    -DLIBCXXABI_LIBCXX_INCLUDES=${SRC_DIR}/libcxx/include \
    ${SRC_DIR}/libcxxabi
    #-DCMAKE_C_COMPILER=${INSTALL_DIR}/bin/clang \
    #-DCMAKE_CXX_COMPILER=${INSTALL_DIR}/bin/clang++ \

  make -j${NCPUS}
  mv lib/* ${INSTALL_DIR}/lib/

  # Build libcxx
  mkdir -p ${BUILD_DIR}/libcxx_build
  cd ${BUILD_DIR}/libcxx_build

  CC=${INSTALL_DIR}/bin/clang CXX=${INSTALL_DIR}/bin/clang++ cmake \
    -G "Unix Makefiles" \
    -DLIBCXX_CXX_ABI=libcxxabi \
    -DLIBCXX_CXX_ABI_INCLUDE_PATHS="${SRC_DIR}/libcxxabi/include" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    ${SRC_DIR}/libcxx

  make -j${NCPUS}
  if [[ "${TEST_LIBCXX}" ]]; then
    make check-libcxx -j${NCPUS}
  fi
  make install
fi

cd ${CURRENT_DIR}
