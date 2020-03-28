#!/usr/bin/env bash

check_python_version() {
  # Just check for the major version (2 or 3)
  local python_major_version=$(python --version 2>&1 | cut -c8)

  if [[ -z "${python_major_version}" ]]; then
    echo "WARNING: Python not found. The CMake generation step will likely fail."
  fi

  if [[ "${python_major_version}" -eq "2" ]]; then
    echo "--------------------------------------------------------------------------------"
    echo "WARNING: `python --version` returns version 2."
    echo "LLVM debuginfo-tests require Python 3 to be the default."
    echo "Please execute this script from the Python 3 virtual environment."
    echo "--------------------------------------------------------------------------------"
    for ((i=5; i>0; --i)); do
      echo -ne "\rContinuing in ${i}..."
      sleep 1
    done
  fi
}

check_swig_version() {
  swig_exe=$(which swig) || true
  if [[ -z "${swig_exe}" ]]; then
    echo "ERROR: SWIG was not found on the system. Please install SWIG, except"
    echo "for versions 3.0.9 or 3.0.10, which are known to be incompatible with"
    echo "lldb."
    exit 0
  fi

  swig_ver=$(${swig_exe} -version | grep SWIG | awk '{print $3}')
  if [[ "${swig_ver}" == "3.0.9" ]] ||  [[ "${swig_ver}" == "3.0.10" ]]; then
    echo "ERROR: Swig versions 3.0.9 and 3.0.10 are incompatible with lldb."
    echo "SWIG ${swig_ver} was found in ${swig_exe}."
    echo "Make sure you install a compatible version before compiling lldb."
    exit 0
  fi
}
