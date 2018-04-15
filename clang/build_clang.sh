#!/bin/bash
set -e

# NOTE: to sucessfully build lldb on Mac OS X, you will have to do this:
# https://llvm.org/svn/llvm-project/lldb/trunk/docs/code-signing.txt

if [[ $# -eq 0 ]]; then
    echo "Usage:"
    echo "  build_clang TARGET_DIR"
    echo "Example:"
    echo "  build_clang ~/clang500"
    exit 1
fi

TARGET_DIR=$(pwd)
if [[ ! -z "$1" ]]; then
  TARGET_DIR=$1
fi

CURRENT_DIR=$(pwd)
TARGET_INSTALL_DIR=$TARGET_DIR/install
TARGET_BUILD_DIR=$TARGET_DIR/build

KERNEL_NAME=$(uname -s)
if [[ "$KERNEL_NAME" == "Darwin" ]]; then
  export NCPUS=$(sysctl -n hw.ncpu)
  export CC=$(which clang)
  export CXX=$(which clang++)
elif [[ "$KERNEL_NAME" == "Linux" ]]; then
  export NCPUS=$(nproc)
  export GCCDIR=$(dirname $(which gcc))/../
  #export CC=$GCCDIR/bin/gcc
  #export CXX=$GCCDIR/bin/g++
  export CC=$(which clang)
  export CXX=$(which clang++)
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
if [ "$SWIG_VER" == "3.0.9" ] ||  [ "$SWIG_VER" == "3.0.10" ]; then
  echo "ERROR: Swig versions 3.0.9 and 3.0.10 are incompatible with lldb."
  echo "SWIG ${SWIG_VER} was found in ${SWIG_EXE}."
  echo "Make sure you install a compatible version before compiling lldb."
  exit 0
fi

echo "Using CC=${CC}, CXX=${CXX}."

# Build LLVM/Clang
mkdir -p ${TARGET_BUILD_DIR}
cd ${TARGET_BUILD_DIR}
cmake \
  -DCMAKE_C_COMPILER=$CC \
  -DCMAKE_CXX_COMPILER=$CXX \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${TARGET_INSTALL_DIR} \
  -DSWIG_EXECUTABLE=${SWIG_EXE} \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DLIBCXXABI_ENABLE_ASSERTIONS=OFF \
  -DLIBCXX_ENABLE_ASSERTIONS=OFF \
  ${GCC_CMAKE_OPTION} \
  ../llvm
make -j${NCPUS}
#make check-libcxx -j${NCPUS}
make install

cd ${TARGET_DIR}

# Build libcxx(abi) with the freshly built Clang
if [[ "$KERNEL_NAME" == "Linux" ]]; then
  # Export relevant environment variables to be able to call Clang
  export PATH=${TARGET_INSTALL_DIR}/bin:$PATH
  export LD_LIBRARY_PATH=${TARGET_INSTALL_DIR}/lib:${LD_LIBRARY_PATH}

  # Compile libcxxabi
  mkdir -p ${TARGET_DIR}/libcxxabi/build
  cd ${TARGET_DIR}/libcxxabi/build
  cmake \
    -DLIBCXXABI_LIBCXX_INCLUDES=../../libcxx/include \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    ..
  make -j${NCPUS}
  mv lib/* ${TARGET_INSTALL_DIR}/lib/

  # Compile libcxx
  mkdir -p ${TARGET_DIR}/libcxx/build
  cd ${TARGET_DIR}/libcxx/build
  CC=clang CXX=clang++ cmake \
    -G "Unix Makefiles" \
    -DLIBCXX_CXX_ABI=libcxxabi \
    -DLIBCXX_CXX_ABI_INCLUDE_PATHS="../../libcxxabi/include" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${TARGET_INSTALL_DIR} \
    ..
  make -j${NCPUS}
  make check-libcxx -j${NCPUS}
  make install
fi

cd ${CURRENT_DIR}
