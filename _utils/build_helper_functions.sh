#!/usr/bin/env bash

init_build_script()
{
  current_dir=$(pwd)
  trap '{ cd ${current_dir}; }' INT TERM EXIT
  this_script_name=$(basename "$0")
}

print_help()
{
  echo
  echo "Usage:"
  echo "  ${this_script_name} [-s <SOURCE_DIR>] [-t <INSTALL_DIR>] [-T <TAG>] [-C]"
  print_help_additional_options
  echo
  echo "Options:"
  echo "  -s <SOURCE_DIR>   The base directory where the source will be"
  echo "                    cloned to. (default: ${clone_dir})."
  echo "  -t <INSTALL_DIR>  The installation directory."
  echo "                    (default: ${install_dir})"
  echo "  -T <TAG>          The Git repository tag that will be checked out."
  echo "                    (default: ${git_tag})"
  echo "  -C                Clean installation directory before installation"
  echo "                    step (POTENTIALLY DANGEROUS)."
  print_help_additional_options_description
}

get_default__nr_cpus()
{
  if [[ "$(uname -s)" == "Darwin" ]]; then
    nr_cpus=$(sysctl -n hw.ncpu)
  elif [[ "$(uname -s)" == "Linux" ]]; then
    nr_cpus=$(nproc)
  fi
}

get_default__clone_dir()
{
  clone_dir="/tmp/build_stuff"
}

get_default__repo_dir()
{
  [[ $# -ne 1 ]] && echo "ERROR: Illegal number of function arguments." && exit 1
  local name=$1

  [[ -z ${clone_dir} ]] && echo "ERROR: variable 'clone_dir' is empty." && exit 1

  repo_dir=${clone_dir}/${name}
}

get_default__install_dir()
{
  [[ $# -ne 1 ]] && echo "ERROR: Illegal number of function arguments." && exit 1
  local name=$1

  install_dir="$HOME/local/${name}"
}

get_default__git_tag()
{
  git_tag="master"
}

check_variables()
{
  [[ -z ${repo_dir} ]] && echo "ERROR: variable 'repo_dir' is empty." && exit 1
  [[ -z ${install_dir} ]] && echo "ERROR: variable 'install_dir' is empty." && exit 1
  [[ -z ${git_tag} ]] && echo "ERROR: variable 'git_tag' is empty." && exit 1
  echo "Cloning to ${repo_dir} and installing to ${install_dir}..."
  echo "Variables:"
  echo "- repo_dir = ${repo_dir}"
  echo "- install_dir = ${install_dir}"
  echo "- git_tag = ${git_tag}"
  echo
  # Sneak this in...
  set -e
}

clone_or_update_repo()
{
  [[ $# -ne 3 ]] && echo "ERROR: Illegal number of function arguments." && exit 1

  local repo_url=$1
  local repo_dir=$2
  local git_tag=$3

  #echo "repo_dir = ${repo_dir}, git_tag = ${git_tag}"

  if [[ ! -d "${repo_dir}/.git" ]]; then
    git clone --recursive ${repo_url} ${repo_dir}
  fi

  git -C ${repo_dir} fetch origin

  if [[ "${git_tag}" == "__LATEST__" ]]; then
    echo "Determining latest Git release tag..."
    git_tag=$(git -C ${repo_dir} describe --abbrev=0 --tags)
  fi

  git -C ${repo_dir} clean -fxd
  git -C ${repo_dir} checkout ${git_tag}
  git -C ${repo_dir} rebase FETCH_HEAD
  git -C ${repo_dir} submodule init
  git -C ${repo_dir} submodule update
}

#cleanup_repo_dir()
#{
#  local repo_dir=$1
#  if [[ "${repo_dir}" =~ "/tmp" ]]; then
#    echo "***** rm -rf ${repo_dir}"
#  fi
#}

clean_install_dir()
{
  [[ $# -ne 1 ]] && echo "ERROR: Illegal number of function arguments." && exit 1
  local install_dir=$1

  if [[ -d "${install_dir}" ]]; then
    echo "Deleting installation directory ${install_dir}..."
    rm -r ${install_dir}
  fi
}

