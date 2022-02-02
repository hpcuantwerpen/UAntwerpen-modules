#! /bin/bash
#
# Script to initialize a new software stack.
#
# The script takes the following arguments:
#  * Version of the software stack
#  * Version of EasyBuild to use
#  * Work directory for temporary files
#
# The root of the installation is derived from the place where the script is found.
# The script should be in <installroot>/<repo>/scripts with <installroot> the
# root for the installation and <repo> the name of the repository (which is
# hard-coded in some files so cannot be changed completely at will).
#

###############################################################################
#
# Checks of the arguments
#

if [ "$#" -ne 3 ]
then
	# Here document, but avoid using <<- as indentation breaks when tabs would
	# get replaced with spaces.
    cat <<EOF 1>&2
This script expects 3 and only 3 command line arguments:
   * The version of the software stack, e.g., 2021b or 2020.01
   * The version of EasyBuild to install in the software stack
   * A work directory for temporary files
EOF
    exit 1
fi

# That cd will work if the script is called by specifying the path or is simply
# found on PATH. It will not expand symbolic links.
cd $(dirname $0)
cd ..
repo=${PWD##*/}
cd ..
installroot=$(pwd)

stack_version="$1"
EBversion="$2"
workdir="$3"
CPEversion=${stack_version%.dev}

cat <<EOF
  * Initialising software stack calcua/$stack_version
  * Using EasyBuild $EBversion
  * Root of the installation: $installroot
  * Using the work directory $workdir
EOF

# Get the numeric equivalent of the version to be used to locate files that exist in multiple versions.
# The code is shared with code used by SitePackage.lua to ensure consistent processing.
numeric_version=$(lua -e "dofile( '$repodir/LMOD/SitePackage_map_toolchain.lua' ) print( map_toolchain( '$stack_version' ) )")


