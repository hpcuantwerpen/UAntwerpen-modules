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
reposubdir=${PWD##*/}
cd ..
installroot=$(pwd)

ebsubdir='UAntwerpen-easybuild'

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
numeric_version=$(lua -e "dofile( '$installroot/$reposubdir/LMOD/SitePackage_map_toolchain.lua' ) print( map_toolchain( '$stack_version' ) )")
echo -e "  * Using equivalent version $numeric_version for finding version-dependent files.\n"


#
# Check: Does the EasyConfig exist?
#
EBconfig_file="$installroot/$ebsubdir/easybuild/easyconfigs/e/EasyBuild/EasyBuild-$EBversion.eb"

if [ ! -f "$EBconfig_file" ]
then
	# Here document, but avoid using <<- as indentation breaks when tabs would
	# get replaced with spaces.
    cat <<EOF 1>&2
Failed to find the EasyConfig file EasyBuild-$EBversion.eb for the requested
version of EasyBuild. The file should be in
$installroot/$ebsubdir/easybuild/easyconfigs/e/EasyBuild
before running this script.
EOF
    exit 1
fi


###############################################################################
#
# Constants
#
clusterarch = ( '


###############################################################################
#
# Create the module structure for the software stack.
#
# Note that for now we link to the generic modules in modules/generic and not
# directly into the repository. We may want to change that in the production
# version, though we should then have a way of coping with different structures
# should we ever want to change the structure of the directory tree.
#

#
# Some functions and variables for this section
#

#
# create_link
#
# Links a file but first tests if the target already exists to avoid error messages.
#
# Input arguments:
#   + First input argument: The target of the link
#   + Second and mandatory argument: The name of the link
#
create_link () {

    test -s "$2" || ln -s "$1" "$2"

}

#
# match_module_version
#
# Looks for the best match in a directory of yyyy.mm.lua files.
# The best match is the most recent of those module files (seen as yy/mm)
# that is not newer than the argument to match, which is a valid LUMI
# software stack version.
#
# Input arguments:
#   * First argument: Numeric equivalent of the CalcUA software stack version to match.
#     Valid formats are:
#       + yyyy.mm , the regular format
#       + yyyy.mm-dev for development software stacks
#   * Second argument: The directory to look for the yyyy.mm.lua module files
#
# The function prints the matching yy.mm.lua module to stdout
#
function match_module_version () {

    match_with=$1
    match_dir=$2

    pushd $match_dir >& /dev/null
    # List the versions of the modules and convert to 4-digit codes (yy.mm.lua -> yymm).
    # They should also be sorted correctly because of the way ls -1 works.
    # readarray is probably overkill as we now for sure that entries will have no spaces.
    # Note that we put 000000 at the front of the list as a sentinel as we will search backwards
    # in the list.
    sentinel_list=( 000000 $(/bin/ls -1 *.lua | egrep '^[[:digit:]]{4}\.[[:digit:]]{2}\.lua$' | sed -e 's/\([0-9]\{4\}\)\.\([0-9]\{2\}\)\.lua/\1\2/') )
    popd >& /dev/null

    #>&2 echo "List with sentinel sentinel_list: ${sentinel_list[@]} (${#sentinel_list[@]} elements)"

    # Extract yy and mm from match_with and transform to yymm, a 4-digit number
    match_number=$(echo $match_with | sed -e 's/\([0-9]\{4\}\).*\([0-9]\{2\}\).*/\1\2/')

    # Look for the largest number in sentinel_list that is smaller than or equal to match_number
    # This is the version of the module that we want to match with.
    counter=$(( ${#sentinel_list[@]} - 1 ))
    while [ ${sentinel_list[$counter]} -gt $match_number ]
    do
    	counter=$(( $counter - 1 ))
    done

    # Transform the result back to yyyy.mm.lua, but print an error message when counter would be 0
    if [ $counter -eq 0 ]
    then
    	>&2 echo "Couldn't find a matching module; all modules are newer than the requested match.\n"
    	echo '0000.00.lua'
    	return 1
    else
        echo "$(echo ${sentinel_list[$counter]} | sed -e 's/\([0-9]\{4\}\)\([0-9]\{2\}\)/\1.\2.lua/')"
        return 0
    fi

}


