#! /bin/bash
#
# This is a script to enable the CalcuUA software stack in an arbitrary location.
#

# That cd will work if the script is called by specifying the path or is simply
# found on PATH. It will not expand symbolic links.
cd $(dirname $0)
cd ..
repo_modules=${PWD##*/}
cd ..
installroot=$(pwd)
stackroot="$installroot"

if [ $# -eq 1 ]
then
    stackroot="$1"	
fi


systemmodules='modules-infrastructure'

#
# Print the commands that should be executed via eval to initialise
# the CalcUA module system from the location based on the location of this
# script.
#
# - Clear LMOD. We will restart it.
#   This is essential as otherwise restore will reset the MODULEPATH that
#   we build here,
echo "clearLmod ; "
#echo "unset _CALCUA_INIT_FIRST_LOAD ; "

# - Point to the SoftwareStack.lua file that we want to use
echo "export CALCUA_SOFTWARESTACK=$stackroot/etc/SoftwareStack.lua"

# - Set a number of LMOD environment variables
echo "export LMOD_PACKAGE_PATH=$installroot/$repo_modules/LMOD ; "
echo "export LMOD_RC=$installroot/$repo_modules/LMOD/lmodrc.lua ; "
echo "export LMOD_MODULERCFILE=$installroot/$repo_modules/LMOD/modulerc.lua ; "
echo "export LMOD_ADMIN_FILE=$installroot/$repo_modules/LMOD/admin.list ; "

# - set the MODULEPATH
#echo "export MODULEPATH=$installroot/$systemmodules/init-$repo_modules ; "
echo "export MODULEPATH=$installroot/$systemmodules/init ; "

# - Set the initial list of modules
echo "export LMOD_SYSTEM_DEFAULT_MODULES=CalcUA-init ; "

# - Initialize LMOD but
echo "source /usr/share/lmod/lmod/init/profile ; "
echo "module --initial_load --no_redirect restore ; "
