#!/bin/bash

print_help()
{
  echo "Usage:"
  echo "  checkout_clang -s [SRC_DIR] (-t [TAG]) -B"
  echo ""
  echo "SRC_DIR designates the directory where the source code will be checked"
  echo "out to (and where Clang will be built)."
  echo ""
  echo "When given, TAG has to match a valid SVN tag of the main LLVM repository:"
  echo "http://llvm.org/svn/llvm-project/llvm/"
  echo "If TAG is not specified via the -t option, 'trunk' will be used as TAG."
  echo ""
  echo "-B: optionally bundles the source code into a .tar.gz file."
  echo ""
  echo "Examples:"
  echo "  checkout_clang -s ~/clang600 -t tags/RELEASE_600/final"
  echo "  checkout_clang -s ~/clang_trunk"
  exit 1
}

TAG=trunk
while getopts ":s:t:Bh" opt; do
  case ${opt} in
    s) SRC_DIR=$OPTARG ;;
    t) TAG=$OPTARG ;;
    B) BUNDLE=1 ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; ARGERR=1 ;;
    \?) echo "Invalid option -$OPTARG"; ARGERR=1 ;;
  esac
done
[[ -z "$SRC_DIR" ]] && { echo "Missing option -s"; ARGERR=1; }
[[ -z "$TAG" ]] && { echo "Missing option -t"; ARGERR=1; }
[[ "$ARGERR" ]] && { print_help; exit 1; }

set -e

CURRENT_DIR=$(pwd)
mkdir -p ${SRC_DIR}
cd ${SRC_DIR}

svn co http://llvm.org/svn/llvm-project/llvm/$TAG llvm

cd ${SRC_DIR}/llvm/tools
svn co http://llvm.org/svn/llvm-project/cfe/$TAG clang
svn co http://llvm.org/svn/llvm-project/lld/$TAG lld
svn co http://llvm.org/svn/llvm-project/polly/$TAG polly
# optionally dis-/enable to build lldb
svn co http://llvm.org/svn/llvm-project/lldb/$TAG lldb

cd ${SRC_DIR}/llvm/tools/clang/tools
svn co http://llvm.org/svn/llvm-project/clang-tools-extra/$TAG extra

cd ${SRC_DIR}/llvm/projects
svn co http://llvm.org/svn/llvm-project/openmp/$TAG openmp
svn co http://llvm.org/svn/llvm-project/compiler-rt/$TAG compiler-rt
svn co http://llvm.org/svn/llvm-project/libcxx/$TAG libcxx
svn co http://llvm.org/svn/llvm-project/libcxxabi/$TAG libcxxabi
cd ${SRC_DIR}

# Check libcxx(abi) out again; these will be built with Clang
if [[ "$(uname -s)" == "Linux" ]]; then
  svn co http://llvm.org/svn/llvm-project/libcxxabi/$TAG libcxxabi
  svn co http://llvm.org/svn/llvm-project/libcxx/$TAG libcxx
fi

if [[ "$BUNDLE" ]]; then
  cd ${SRC_DIR}
  tar czf src.tar.gz llvm libcxx*
fi

cd ${CURRENT_DIR}
