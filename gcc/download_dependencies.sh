#!/usr/bin/env bash
set -e

# Script that downloads the GCC dependencies that are otherwise retrieved
# using the ./contrib/download_prerequisites script in the GCC source tree.
#
# This functionality is usually performed inside build_gcc.sh; only call this
# script in case other versions of the dependencies shall be downloaded, or if
# the dependencies need to be copied over manually.
#
# Example usage in context:
# > ./build_gcc.sh [...] -C
# > ./download_dependencies.sh [...]
# > ./build_gcc.sh [...] -B

# This should be kept up-to-date with the latest (supported) versions.
# - https://gmplib.org/
gmp_version="6.2.0"
# - https://www.mpfr.org/
mpfr_version="4.0.2"
# - http://www.multiprecision.org/mpc/
mpc_version="1.1.0"
# - https://gcc.gnu.org/pub/gcc/infrastructure/
isl_version="0.18"

print_help()
{
  echo "Usage:"
  echo "  download_dependencies -t <TARGET_DIR>"
  echo
  echo "-t: Target directory."
  echo
  echo "-G: GMP Version (default: ${gmp_version})."
  echo "-F: MPFR Version (default: ${mpfr_version})."
  echo "-M: MPC Version (default: ${mpc_version})."
  echo "-I: ISL Version (default: ${isl_version})."
  echo
  echo "Examples:"
  echo "  download_dependencies -t ~/devel/gcc_deps"
}

if [[ $# -eq 0 ]]; then
  print_help
  exit 1
fi

while getopts ":t:G:F:M:I:h" opt; do
  case ${opt} in
    t) target_dir=$OPTARG ;;
    G) gmp_version=$OPTARG ;;
    F) mpfr_version=$OPTARG ;;
    M) mpc_version=$OPTARG ;;
    I) isl_version=$OPTARG ;;
    h) print_help; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument."; ARGERR=1 ;;
    \?) echo "Invalid option -$OPTARG"; ARGERR=1 ;;
  esac
done
[[ -z "$target_dir" ]] && { echo "Missing option -t"; ARGERR=1; }
[[ ! -z "$ARGERR" ]] && { print_help; exit 1; }

echo "target_dir = ${target_dir}"
echo "gmp_version = ${gmp_version}"
echo "mpfr_version = ${mpfr_version}"
echo "mpc_version = ${mpc_version}"
echo "isl_version = ${isl_version}"

mkdir -p ${target_dir}

function retrieve_file {
  url=$1
  filename=${url##*/}

  if [ ! -f "${target_dir}/${filename}" ]; then
    wget -c -P ${target_dir} ${url}
  fi
}

retrieve_file https://gmplib.org/download/gmp/gmp-${gmp_version}.tar.bz2
retrieve_file http://www.mpfr.org/mpfr-${mpfr_version}/mpfr-${mpfr_version}.tar.bz2
retrieve_file ftp://ftp.gnu.org/gnu/mpc/mpc-${mpc_version}.tar.gz
retrieve_file ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-${isl_version}.tar.bz2

echo "Checking existence of required files..."
[[ ! -f "${target_dir}/gmp-${gmp_version}.tar.bz2" ]] && { echo "Missing file."; exit 1; }
[[ ! -f "${target_dir}/isl-${isl_version}.tar.bz2" ]] && { echo "Missing file."; exit 1; }
[[ ! -f "${target_dir}/mpc-${mpc_version}.tar.gz" ]] && { echo "Missing file."; exit 1; }
[[ ! -f "${target_dir}/mpfr-${mpfr_version}.tar.bz2" ]] && { echo "Missing file."; exit 1; }

echo "Extracting files..."
tar xf ${target_dir}/gmp-${gmp_version}.tar.bz2 -C ${target_dir}
tar xf ${target_dir}/isl-${isl_version}.tar.bz2 -C ${target_dir}
tar xf ${target_dir}/mpc-${mpc_version}.tar.gz -C ${target_dir}
tar xf ${target_dir}/mpfr-${mpfr_version}.tar.bz2 -C ${target_dir}

ln -s ./gmp-${gmp_version} ${target_dir}/gmp
ln -s ./isl-${isl_version} ${target_dir}/isl
ln -s ./mpc-${mpc_version} ${target_dir}/mpc
ln -s ./mpfr-${mpfr_version} ${target_dir}/mpfr

echo "Done."
