#!/bin/bash

# NOTE: to sucessfully build lldb on Mac OS X, you will have to do this:
# https://llvm.org/svn/llvm-project/lldb/trunk/docs/code-signing.txt

if [[ "$(uname -s)" == "Linux" ]]; then
  export GCCDIR=$(dirname $(which gcc))/../
  export GCC_CMAKE_OPTION="-DGCC_INSTALL_PREFIX=$GCCDIR"
fi

print_help()
{
  echo ""
  echo "Usage:"
  echo "  build_clang.sh -s <SRC_DIR> -t <INSTALL_DIR> [-T <TAG>] [-p <PROJECTS>] [-R] [-U]"
  echo ""
  echo "-s: Directory to which the source should be cloned to"
  echo "    (excluding name of the repository directory; e.g. \$HOME/devel)."
  echo "-t: Installation directory (e.g. '\$HOME/local')."
  echo "-T: Git tag to check out (e.g. 'llvmorg-8.0.0')."
  echo "-p: Projects to build, i.e. the string passed to LLVM_ENABLE_PROJECTS."
  echo "    Defaults to 'all'."
  echo "-R: Perform Clang regression tests."
  echo "-U: Perform libc++ regression tests."
  echo ""
  echo "CC and CXX determine the compiler to be used."
}

while getopts ":s:b:t:T:p:RUoh" opt; do
  case ${opt} in
    s) CLONE_DIR=$OPTARG ;;
    t) INSTALL_DIR=$OPTARG ;;
    T) GIT_TAG=$OPTARG ;;
    p) PROJECTS_TO_BUILD=$OPTARG ;;
    R) TEST_CLANG=1 ;;
    U) TEST_LIBCXX=1 ;;
    o) DISABLE_LIBOMPTARGET=1 ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; ARGERR=1 ;;
    \?) echo "Invalid option -$OPTARG"; ARGERR=1 ;;
  esac
done
[[ -z "$CLONE_DIR" ]] && { echo "Missing option -s"; ARGERR=1; }
[[ -z "$INSTALL_DIR" ]] && { echo "Missing option -t"; ARGERR=1; }
[[ -z "$PROJECTS_TO_BUILD" ]] && { PROJECTS_TO_BUILD="all"; }
[[ "$ARGERR" ]] && { print_help; exit 1; }

REPO_DIR=${CLONE_DIR}/llvm-project
echo "Cloning to ${REPO_DIR} and installing to ${INSTALL_DIR}..."
set -e

CURRENT_DIR=$(pwd)

# Clone and get to clean slate
mkdir -p ${CLONE_DIR}
git -C ${CLONE_DIR} clone https://github.com/llvm/llvm-project.git || true
git -C ${REPO_DIR} reset HEAD --hard
git -C ${REPO_DIR} clean -fxd
git -C ${REPO_DIR} checkout master
git -C ${REPO_DIR} pull --rebase

# Use user-specified tag, if applicable
if [[ ! -z "$GIT_TAG" ]]; then
  echo "GIT_TAG=${GIT_TAG}"
  git -C ${REPO_DIR} checkout ${GIT_TAG}
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
echo "REPO_DIR=${REPO_DIR}"
echo "INSTALL_DIR=${INSTALL_DIR}"
echo "PROJECTS_TO_BUILD=${PROJECTS_TO_BUILD}"
echo "GCCDIR=${GCCDIR}"

if [[ "${DISABLE_LIBOMPTARGET}" ]]; then
  CM_OPTION_DISABLE_LIBOMPTARGET="-DOPENMP_ENABLE_LIBOMPTARGET=OFF"
fi

CMK_GENERATOR=""
if [ $(which ninja) ]; then
  CMK_GENERATOR="-G Ninja"
fi

# Build LLVM project.

BUILD_DIR=${REPO_DIR}/build
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

cmake \
  ${CMK_GENERATOR} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
  -DSWIG_EXECUTABLE=${SWIG_EXE} \
  -DLLVM_ENABLE_PROJECTS=${PROJECTS_TO_BUILD} \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DLIBCXXABI_ENABLE_ASSERTIONS=OFF \
  -DLIBCXX_ENABLE_ASSERTIONS=OFF \
  -DLIBUNWIND_ENABLE_ASSERTIONS=OFF \
  ${GCC_CMAKE_OPTION} \
  ${REPO_DIR}/llvm

cmake --build . -j
cmake --build . --target install/strip

# Export relevant environment variables to be able to call Clang.

export PATH=${INSTALL_DIR}/bin:$PATH
export LD_LIBRARY_PATH=${INSTALL_DIR}/lib:${LD_LIBRARY_PATH}

# Build libcxxabi using just built Clang.

BUILD_DIR_LIBCXXABI=${REPO_DIR}/build-libcxxabi
mkdir -p ${BUILD_DIR_LIBCXXABI}
cd ${BUILD_DIR_LIBCXXABI}

CC=${INSTALL_DIR}/bin/clang \
  CXX=${INSTALL_DIR}/bin/clang++ \
  cmake \
    ${CMK_GENERATOR} \
    -DCMAKE_BUILD_TYPE=Release \
    -DLIBCXXABI_LIBCXX_PATH=${REPO_DIR}/libcxx \
    ${REPO_DIR}/libcxxabi

cmake --build . -j
mv lib/* ${INSTALL_DIR}/lib/

# Build libcxx using just built Clang.

BUILD_DIR_LIBCXX=${REPO_DIR}/build-libcxx
mkdir -p ${BUILD_DIR_LIBCXX}
cd ${BUILD_DIR_LIBCXX}

CC=${INSTALL_DIR}/bin/clang \
  CXX=${INSTALL_DIR}/bin/clang++ \
  cmake \
    ${CMK_GENERATOR} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DLLVM_PATH=${REPO_DIR}/llvm \
    -DLIBCXX_CXX_ABI=libcxxabi \
    -DLIBCXX_CXX_ABI_INCLUDE_PATHS=${REPO_DIR}/libcxxabi/include \
    ${REPO_DIR}/libcxx

cmake --build . -j
cmake --build . --target install

# Run tests, if desired

set +e

if [[ "${TEST_CLANG}" ]]; then
  cd ${BUILD_DIR}
  cmake --build . --target clang-test
fi

if [[ "${TEST_LIBCXX}" ]]; then
  cd ${BUILD_DIR_LIBCXX}
  cmake --build . --target check-libcxx
fi

# Done.

cd ${CURRENT_DIR}
