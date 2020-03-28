#!/usr/bin/env bash

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
