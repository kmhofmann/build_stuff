#!/usr/bin/env bash

# NOTE: to sucessfully build lldb on Mac OS X, you will have to do this:
# https://llvm.org/svn/llvm-project/lldb/trunk/docs/code-signing.txt

software_name="llvm-project"
git_uri="https://github.com/llvm/llvm-project.git"

this_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source ${this_script_dir}/../_utils/build_helper_functions.sh
source ${this_script_dir}/../_utils/llvm_helper_functions.sh

init_build_script
get_default__nr_cpus
get_default__clone_dir
get_default__repo_dir ${software_name}
get_default__install_dir ${software_name}
get_default__git_tag

if [[ "$(uname -s)" == "Linux" ]]; then
  export gccdir=$(dirname $(which gcc))/../
  export gcc_cmake_option="-DGCC_INSTALL_PREFIX=${gccdir}"
fi

print_help_additional_options() {
  echo "          [-p <PROJECTS_TO_BUILD>] [-x <PROJECT_TO_EXCLUDE>]"
  echo "          [-C <CMAKE_STRING>] [-R] [-U] [-P]"
}

print_help_additional_options_description() {
  echo
  echo "  -p <PROJECTS_TO_BUILD>  Projects to build; i.e. the string passed to"
  echo "                          LLVM_ENABLE_PROJECTS. Defaults to 'all'."
  echo "  -x <PROJECT_TO_EXCLUDE> Project(s) to exclude, if -p is not passed."
  echo "                          Can be passed multiple times."
  echo "  -C <CMAKE_STRING>       String to pass to the CMake command line."
  echo
  echo "  -R                Perform Clang regression tests."
  echo "  -U                Perform libc++ regression tests."
  echo
  echo "  -P                List possible projects after checking out the"
  echo "                    repository and then exit."
  echo
  echo "CC and CXX determine the compiler to be used."
}

while getopts ":s:b:t:T:p:x:C:RUPh" opt; do
  case ${opt} in
    s) clone_dir=$OPTARG ;;
    t) install_dir=$OPTARG ;;
    T) git_tag=$OPTARG ;;
    j) nr_cpus=$OPTARG ;;

    p) projects_to_build=$OPTARG ;;
    x) projects_to_exclude+=("$OPTARG") ;;
    C) script_cmake_extra_arguments=$OPTARG ;;
    R) test_clang=1 ;;
    U) test_libcxx=1 ;;
    P) list_possible_projects=1 ;;

    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; arg_err=1 ;;
    \?) echo "Invalid option -$OPTARG"; arg_err=1 ;;
  esac
done
[[ "$projects_to_exclude" ]] && [[ "$projects_to_build" ]] && { echo "-p and -x cannot be used together"; arg_err=1; }
[[ -z "$projects_to_build" ]] && { projects_to_build="all"; }
[[ "$arg_err" ]] && { print_help; exit 1; }

check_variables
echo "- CC = ${CC}"
echo "- CXX = ${CXX}"
echo "- gccdir = ${gccdir}"
echo

repo_dir=${clone_dir}/${software_name}
check_python_version
check_swig_version
clone_or_update_repo ${git_uri} ${repo_dir} ${git_tag}

# Try to get list of projects from CMake file
projects_list_all=$(grep "^set(LLVM_ALL_PROJECTS" ${repo_dir}/llvm/CMakeLists.txt | cut -d\" -f2)

if [[ "${list_possible_projects}" ]]; then
  echo "-----"
  echo "Projects that will be passed to LLVM_ENABLE_PROJECTS with the default 'all':"
  echo "${projects_list_all}"
  exit 0
fi

if [[ "${projects_to_exclude}" ]]; then
  projects_to_build=${projects_list_all}
  for projx in ${projects_to_exclude[@]}; do
    projects_to_build=${projects_to_build//$projx;}
  done
fi

echo
echo "- projects_to_build = ${projects_to_build}"

cmake_generator=""
if [ $(which ninja) ]; then
  cmake_generator="-G Ninja"
fi

# Build LLVM project.

build_dir=${repo_dir}/build
mkdir -p ${build_dir}
cd ${build_dir}

set -x
cmake \
  ${cmake_generator} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${install_dir} \
  -DSWIG_EXECUTABLE=${swig_exe} \
  -DLLVM_ENABLE_PROJECTS=${projects_to_build} \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DLIBCXXABI_ENABLE_ASSERTIONS=OFF \
  -DLIBCXX_ENABLE_ASSERTIONS=OFF \
  -DLIBUNWIND_ENABLE_ASSERTIONS=OFF \
  ${script_cmake_extra_arguments} \
  ${gcc_cmake_option} \
  ${repo_dir}/llvm
set +x

cmake --build . --parallel ${nr_cpus}
[[ ! -z "${opt_clean_install_dir}" ]] && clean_install_dir ${install_dir}
cmake --build . --target install/strip

# Export relevant environment variables to be able to call Clang.

export PATH=${install_dir}/bin:$PATH
export LD_LIBRARY_PATH=${install_dir}/lib:${LD_LIBRARY_PATH}

# Build libcxxabi using just built Clang.

build_dir_libcxxabi=${repo_dir}/build-libcxxabi
mkdir -p ${build_dir_libcxxabi}
cd ${build_dir_libcxxabi}

CC=${install_dir}/bin/clang \
  CXX=${install_dir}/bin/clang++ \
  cmake \
    ${cmake_generator} \
    -DCMAKE_BUILD_TYPE=Release \
    -DLIBCXXABI_LIBCXX_PATH=${repo_dir}/libcxx \
    ${repo_dir}/libcxxabi

cmake --build . --parallel ${nr_cpus}
mv lib/* ${install_dir}/lib/

# Build libcxx using just built Clang.

build_dir_libcxx=${repo_dir}/build-libcxx
mkdir -p ${build_dir_libcxx}
cd ${build_dir_libcxx}

CC=${install_dir}/bin/clang \
  CXX=${install_dir}/bin/clang++ \
  cmake \
    ${cmake_generator} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${install_dir} \
    -DLLVM_PATH=${repo_dir}/llvm \
    -DLIBCXX_CXX_ABI=libcxxabi \
    -DLIBCXX_CXX_ABI_INCLUDE_PATHS=${repo_dir}/libcxxabi/include \
    ${repo_dir}/libcxx

cmake --build . --parallel ${nr_cpus}
cmake --build . --target install

# Run tests, if desired

set +e

if [[ "${test_clang}" ]]; then
  cd ${build_dir}
  cmake --build . --parallel ${nr_cpus} --target clang-test
fi

if [[ "${test_libcxx}" ]]; then
  cd ${build_dir_libcxx}
  cmake --build . --parallel ${nr_cpus} --target check-libcxx
fi
