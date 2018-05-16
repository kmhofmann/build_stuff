#!/bin/bash

print_help()
{
  echo "Usage:"
  echo "  checkout_clang -s SRC_DIR [-t TAG] [-B] [-P] [-L] [-D] [-T] [-O] [-R] [-X]"
  echo ""
  echo "SRC_DIR designates the directory where the source code will be checked"
  echo "out to (and where Clang will be built)."
  echo ""
  echo "When given, TAG has to match a valid SVN tag of the main LLVM repository:"
  echo "http://llvm.org/svn/llvm-project/llvm/"
  echo "If TAG is not specified via the -t option, 'trunk' will be used as TAG."
  echo ""
  echo "-B: optionally bundles the source code into a .tar.gz file."
  echo "-P: do not check out Polly"
  echo "-L: do not check out lldb"
  echo "-D: do not check out lld"
  echo "-T: do not check out clang-tools"
  echo "-O: do not check out OpenMP"
  echo "-R: do not check out Compiler-RT"
  echo "-X: do not check out libcxx/libcxxabi (out of tree)"
  echo ""
  echo "Examples:"
  echo "  checkout_clang -s ~/clang600 -t tags/RELEASE_600/final"
  echo "  checkout_clang -s ~/clang_trunk"
  exit 1
}

TAG=trunk
while getopts ":s:t:BPLDTORXh" opt; do
  case ${opt} in
    s) SRC_DIR=$OPTARG ;;
    t) TAG=$OPTARG ;;
    B) BUNDLE=1 ;;
    P) NCO_POLLY=1 ;;
    L) NCO_LLDB=1 ;;
    D) NCO_LLD=1 ;;
    T) NCO_CLANG_TOOLS=1 ;;
    O) NCO_OPENMP=1 ;;
    R) NCO_COMPILERRT=1 ;;
    X) NCO_LIBCXX=1 ;;
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
if [[ ! "${NCO_POLLY}" ]]; then
  svn co http://llvm.org/svn/llvm-project/polly/$TAG polly
fi
if [[ ! "${NCO_LLD}" ]]; then
  svn co http://llvm.org/svn/llvm-project/lld/$TAG lld
fi
if [[ ! "${NCO_LLDB}" ]]; then
  svn co http://llvm.org/svn/llvm-project/lldb/$TAG lldb
fi

if [[ ! "${NCO_LLDB}" ]]; then
  cd ${SRC_DIR}/llvm/tools/clang/tools
  svn co http://llvm.org/svn/llvm-project/clang-tools-extra/$TAG extra
fi

cd ${SRC_DIR}/llvm/projects
if [[ ! "${NCO_OPENMP}" ]]; then
  svn co http://llvm.org/svn/llvm-project/openmp/$TAG openmp
fi
if [[ ! "${NCO_COMPILERRT}" ]]; then
  svn co http://llvm.org/svn/llvm-project/compiler-rt/$TAG compiler-rt
fi
svn co http://llvm.org/svn/llvm-project/libcxx/$TAG libcxx
svn co http://llvm.org/svn/llvm-project/libcxxabi/$TAG libcxxabi

cd ${SRC_DIR}

# Check libcxx(abi) out again; these will be built with Clang
if [[ "$(uname -s)" == "Linux" ]]; then
  if [[ ! "${NCO_LIBCXX}" ]]; then
    svn co http://llvm.org/svn/llvm-project/libcxxabi/$TAG libcxxabi
    svn co http://llvm.org/svn/llvm-project/libcxx/$TAG libcxx
  fi
fi

if [[ "$BUNDLE" ]]; then
  cd ${SRC_DIR}
  tar czf src.tar.gz llvm libcxx*
fi

cd ${CURRENT_DIR}
