#!/usr/bin/env bash

# Prerequisites, according to
# https://github.com/JuliaLang/julia/blob/master/doc/build/build.md#required-build-tools-and-external-libraries
#
# $ sudo apt-get install build-essential libatomic1 python gfortran perl wget m4 cmake pkg-config

software_name="julia"

this_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source ${this_script_dir}/_utils/build_helper_functions.sh

init_build_script
get_default__nr_cpus
get_default__install_dir ${software_name}
get_default__git_tag

print_help()
{
  echo
  echo "Usage:"
  echo "  ${this_script_name} [-t <INSTALL_DIR>] [-T <TAG>]"
  echo
  echo "Options:"
  echo "  -t <INSTALL_DIR>  The checkout, build, and installation directory."
  echo "                    (default: ${install_dir})"
  echo "  -T <TAG>          The Git repository tag that will be checked out."
  echo "                    (default: ${git_tag})"
}

while getopts ":s:t:T:j:h" opt; do
  case ${opt} in
    t) install_dir=$OPTARG ;;
    T) git_tag=$OPTARG; echo "Using git_tag=${git_tag}" ;;
    j) nr_cpus=$OPTARG ;;
    h) print_help; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument."; arg_err=1 ;;
    \?) echo "Invalid option -$OPTARG"; arg_err=1 ;;
  esac
done
[[ -z "$install_dir" ]] && { echo "Missing option -t"; arg_err=1; }
[[ ! -z "$arg_err" ]] && { print_help; exit 1; }

echo "Cloning to and installing in ${install_dir}..."
set -e

clone_or_update_repo \
  git://github.com/JuliaLang/julia.git \
  ${install_dir} \
  ${git_tag}

# Compile and install
cd ${install_dir}

echo "MARCH=native" > Make.user
make -j${nr_cpus}
#make testall
