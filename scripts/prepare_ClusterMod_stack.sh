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

if [ "$#" -ne 1 ]
then
	# Here document, but avoid using <<- as indentation breaks when tabs would
	# get replaced with spaces.
    cat <<EOF 1>&2
This script expects 1 and only 1 command line argument:
   * The version of the software stack, e.g., 2021b or 2020.01
EOF
    exit 1
fi

# That cd will work if the script is called by specifying the path or is simply
# found on PATH. It will not expand symbolic links.
cd $(dirname $0)
scriptdir=$PWD
cd ..
reposubdir=${PWD##*/}
cd ..
installroot=$PWD

ebsubdir='UAntwerpen-easybuild'

stack_version="$1"
stack_name=$($scriptdir/ClusterMod_tools/helper_get_stackname.lua)

cat <<EOF

  * Initialising software stack $stack_name/$stack_version
  * Root of the installation: $installroot
EOF

# Get the numeric equivalent of the version to be used to locate files that exist in multiple versions.
# The code is shared with code used by SitePackage.lua to ensure consistent processing.
numeric_version=$($installdir/$reposupdir/scripts/ClusterMod_tools/helper_map_toolchain.lua $stack_version)
echo -e "  * Using equivalent version $numeric_version for finding version-dependent files.\n"


###############################################################################
#
# Create the module structure for the software stack.
#
# Note that for now we link to the generic modules in modules/generic and not
# directly into the repository. We may want to change that in the production
# version, though we should then have a way of coping with different structures
# should we ever want to change the structure of the directory tree.
#

echo -e "\n## Initialising the directory structure...\n"

$scriptdir/ClusterMod_tools/prepare_ClusterMod_stack.lua "$stack_version"

