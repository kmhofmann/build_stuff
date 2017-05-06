#!/bin/bash
set -e

if [[ $# -eq 0 ]]; then
  echo "Usage:"
  echo "  checkout_clang TARGET_DIR [TAG]"
  echo ""
  echo "where TAG has to match a valid SVN tag of the main LLVM repository:"
  echo "http://llvm.org/svn/llvm-project/llvm/"
  echo "If TAG is not specified, 'trunk' will be used."
  echo ""
  echo "Examples:"
  echo "  checkout_clang ~/clang400 tags/RELEASE_400/final"
  echo "  checkout_clang ~/clang_trunk"
  exit 1
fi

TARGET_DIR=$(pwd)
if [[ ! -z "$1" ]]; then
  TARGET_DIR=$1
fi

TAG=trunk
if [[ ! -z "$2" ]]; then
  TAG=$2
fi

CURRENT_DIR=$(pwd)
mkdir -p ${TARGET_DIR}
cd ${TARGET_DIR}

svn co http://llvm.org/svn/llvm-project/llvm/$TAG llvm
cd ${TARGET_DIR}/llvm/tools
svn co http://llvm.org/svn/llvm-project/cfe/$TAG clang

# optionally dis-/enable to build lldb
svn co http://llvm.org/svn/llvm-project/lldb/$TAG lldb
svn co http://llvm.org/svn/llvm-project/lld/$TAG lld

cd ${TARGET_DIR}/llvm/tools/clang/tools
svn co http://llvm.org/svn/llvm-project/clang-tools-extra/$TAG extra
cd ${TARGET_DIR}/llvm/projects
svn co http://llvm.org/svn/llvm-project/openmp/$TAG openmp
svn co http://llvm.org/svn/llvm-project/compiler-rt/$TAG compiler-rt
svn co http://llvm.org/svn/llvm-project/libcxx/$TAG libcxx
svn co http://llvm.org/svn/llvm-project/libcxxabi/$TAG libcxxabi
cd ${TARGET_DIR}

# Check libcxx(abi) out again; these will be build with Clang
if [ "$(uname -s)" == "Linux" ]; then
  svn co http://llvm.org/svn/llvm-project/libcxxabi/$TAG libcxxabi
  svn co http://llvm.org/svn/llvm-project/libcxx/$TAG libcxx
fi

cd ${CURRENT_DIR}
