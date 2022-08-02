#! /bin/bash
#
# Script that ensures that all stacks have access to the right version of
# EasyBuild.
#
# The script takes no arguments, all info is read from /etc/SystemDefinition.lua
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

# That cd will work if the script is called by specifying the path or is simply
# found on PATH. It will not expand symbolic links.
cd $(dirname $0)
scriptdir=$PWD
cd ..
reposubdir=${PWD##*/}
cd ..
installroot=$PWD

ebsubdir='UAntwerpen-easybuild'

###############################################################################
#
# Some useful functions
#

function die () {

    echo "$*" 1>&2
    exit 1

}


#
# make_dir
#
# Make a directory using mkdir -p and die with a message if this fails.
#
make_dir () {

	mkdir -p "$1" || die "Failed to create the directory $1."

}


###############################################################################
#
# Preparatory work
#

# Make sure there is a place to store the EasyBuild sources as we will bootstrap
# each version.

make_dir "$installroot/sources"
make_dir "$installroot/sources/e"
make_dir "$installroot/sources/e/EasyBuild"
EBtardir="$installroot/sources/e/EasyBuild"

# Get the name of the software stack
stack_name=$($scriptdir/ClusterMod_tools/helper_get_stackname.lua)


# Initialise LMOD just to be sure as we may be running this to install in an
# alternative stack.
eval $($scriptdir/enable_ClusterMod.sh)

module load $stack_name/system
module load arch/$($scriptdir/ClusterMod_tools/helper_get_generic_current.lua 'system')

###############################################################################
#
# Actual installations
#

for EBversion in $($scriptdir/ClusterMod_tools/helper_get_easybuild_versions.lua)
do

    echo "\n## Considering EasyBuild $EBversion"

    #
    # Check if there is an EasyConfig file
    #
    EBconfig_file="$installroot/$ebsubdir/easybuild/easyconfigs/e/EasyBuild/EasyBuild-$EBversion.eb"

    if [ ! -f "$EBconfig_file" ]
    then
	    # Here document, but avoid using <<- as indentation breaks when tabs would
	    # get replaced with spaces.
        echo "Failed to find the EasyConfig file EasyBuild-$EBversion.eb." 1>&2
        echo "That file should be in $installroot/$ebsubdir/easybuild/easyconfigs/e/EasyBuild." 1>&2

        continue
    fi

    #
    # Check if there is already a module present
    #

    module avail EasyBuild/$EBversion |& grep -q "EasyBuild/$EBversion"
    if [[ $? != 0 ]]
    then
	    
        #
        # EasyBuild/$EBversion not found, so installing it...
        #
        echo -e "\n## Easybuild/$EBversion module not found, starting the bootstrapping process...\n"

        #
        # -   First download the sources (if not present already)
        #
        echo -e "\n## Downloading EasyBuild $EBversion...\n"

        EBF_file="easybuild-framework-${EBversion}.tar.gz"
        EBF_url="https://pypi.python.org/packages/source/e/easybuild-framework"
        [[ -f $EBF_file ]] || curl -L -O $EBF_url/$EBF_file

        EBB_file="easybuild-easyblocks-${EBversion}.tar.gz"
        EBB_url="https://pypi.python.org/packages/source/e/easybuild-easyblocks"
        [[ -f $EBB_file ]] || curl -L -O $EBB_url/$EBB_file

        EBC_file="easybuild-easyconfigs-${EBversion}.tar.gz"
        EBC_url="https://pypi.python.org/packages/source/e/easybuild-easyconfigs"
        [[ -f $EBC_file ]] || curl -L -O $EBC_url/$EBC_file

        #
        # -   Now load the EasyBuild-production module.
        #     This module shoudl be written in a way that it does not fail if it cannot
        #     find an EasyBuild module. We'll use EASYBUILD_BUILDPATH.
        #
        module load EasyBuild-unlock EasyBuild-production
        workdir="$EASYBUILD_BUILDPATH/tmp"

        #
        # -   Do a temporary install of the framework and EasyBlocks.
        #     The EasyConfig files are not needed. 
        # 
        echo "\n## Doing a temporary install of EasyBuild $EBversion...\n"

        make_dir $workdir
        pushd $workdir

        tar -xf $EB_tardir/$EBF_file
        tar -xf $EB_tardir/$EBB_file

        make_dir $workdir/easybuild

        pushd easybuild-framework-$EBversion
        python3 setup.py install --prefix=$workdir/easybuild
        cd ../easybuild-easyblocks-$EBversion
        python3 setup.py install --prefix=$workdir/easybuild
        popd
    
        #
        # - Clean up files that are not needed anymore
        #
        rm -rf easybuild-framework-$EBversion
        rm -rf easybuild-easyblocks-$EBversion

        #
        # - Activate that install
        #
        export EB_PYTHON='python3'
        export PYTHONPATH=$(find $workdir/easybuild -name site-packages)

        #
        # - Install EasyBuild in the common directory of the $EBstack software stack
        #
        # Need to use the full module name as the module is hidden in the default view!
        echo -e "\n## Now properly installing Easybuild/$EBversion...\n"
        #module load EasyBuild-unlock
        #module load EasyBuild-production
        #$workdir/easybuild/bin/eb --show-config || die "Something wrong with the work copy of EasyBuild, eb --show-config fails."
        #$workdir/easybuild/bin/eb $installroot/$repo/easybuild/easyconfigs/e/EasyBuild/EasyBuild-${EBversion}.eb \
        #  || die "EasyBuild failed to install EasyBuild-${EBversion}.eb."

        #
        # - Clean up
        #
        rm -rf easybuild

        popd

done

