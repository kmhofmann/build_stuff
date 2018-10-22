#!/bin/bash

# NOTE: to sucessfully build lldb on Mac OS X, you will have to do this:
# https://llvm.org/svn/llvm-project/lldb/trunk/docs/code-signing.txt

print_help()
{
  echo ""
  echo "Usage:"
  echo "  build_clang.sh -s SRC_DIR [-b BUILD_DIR] [-i INSTALL_DIR] [-a ABI_TYPE] [-t) [-u]"
  echo ""
  echo "-s: Directory in which the source has been checked out."
  echo "-b: Build directory. Defaults to SRC_DIR/build."
  echo "-i: Installation directory. Defaults to SRC_DIR/install."
  echo "-a: ABI type for Linux. Either 'libstdc++' or 'libcxxabi'. Defaults to 'libcxxabi'."
  echo "-t: Perform Clang regression tests."
  echo "-u: Perform libc++ regression tests."
  echo ""
  echo "CC and CXX determine the compiler to be used."
}

while getopts ":s:b:i:a:tuh" opt; do
  case ${opt} in
    s) SRC_DIR=$OPTARG ;;
    b) BUILD_DIR=$OPTARG ;;
    i) INSTALL_DIR=$OPTARG ;;
    a) ABI_TYPE=$OPTARG ;;
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
[[ -z "$ABI_TYPE" ]] && { ABI_TYPE="libcxxabi"; }
[[ "$ARGERR" ]] && { print_help; exit 1; }

if [[ ! "${ABI_TYPE}" == "libstdc++" ]] && [[ ! "${ABI_TYPE}" == "libcxxabi" ]]; then
  echo "Illegal ABI_TYPE ${ABI_TYPE}."
  exit 0
fi

set -e

CURRENT_DIR=$(pwd)

KERNEL_NAME=$(uname -s)
if [[ "$KERNEL_NAME" == "Darwin" ]]; then
  export NCPUS=$(($(sysctl -n hw.ncpu)/2))
elif [[ "$KERNEL_NAME" == "Linux" ]]; then
  export NCPUS=$(($(nproc)/2))

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
echo "ABI_TYPE=${ABI_TYPE}"

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

  if [[ "${ABI_TYPE}" == "libcxxabi" ]]; then
    ABI_INCL="${SRC_DIR}/libcxxabi/include"
  else
    ABI_INCL=$(echo | g++ -Wp,-v -x c++ - -fsyntax-only 2>&1 | grep "^ " | head -n 2 | tr '\n' ';' | tr -d '[:space:]')
  fi

  if [[ "$ABI_TYPE" == "libcxxabi" ]]; then
    # Build libcxxabi
    mkdir -p ${BUILD_DIR}/libcxxabi_build
    cd ${BUILD_DIR}/libcxxabi_build

    CC=${INSTALL_DIR}/bin/clang CXX=${INSTALL_DIR}/bin/clang++ cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DLIBCXXABI_LIBCXX_INCLUDES=${SRC_DIR}/libcxx/include \
      ${SRC_DIR}/libcxxabi

    make -j${NCPUS}
    mv lib/* ${INSTALL_DIR}/lib/
  fi

  # Build libcxx
  mkdir -p ${BUILD_DIR}/libcxx_build
  cd ${BUILD_DIR}/libcxx_build

  CC=${INSTALL_DIR}/bin/clang CXX=${INSTALL_DIR}/bin/clang++ cmake \
    -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DLLVM_PATH=${SRC_DIR}/llvm \
    -DLIBCXX_CXX_ABI=${ABI_TYPE} \
    -DLIBCXX_CXX_ABI_INCLUDE_PATHS="${ABI_INCL}" \
    ${SRC_DIR}/libcxx

  make -j${NCPUS}
  if [[ "${TEST_LIBCXX}" ]]; then
    make check-libcxx -j${NCPUS}
  fi
  make install
fi

cd ${CURRENT_DIR}
