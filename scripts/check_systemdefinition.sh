#! /bin/bash
#
# Script that prints a lot of information on the clusternode it is running
# on and at the same time can be used to check if the cluster defintion is
# OK.
#
# The script does not take any argument.
#

# That cd will work if the script is called by specifying the path or is simply
# found on PATH. It will not expand symbolic links.
currentdir=$PWD
cd $(dirname $0)
scriptdir=$PWD
cd ..
repodir=$PWD
cd $currentdir

if [[ $# == 1  ]]
then
    systemdefinition_file="$1"
else
    systemdefinition_file="$repodir/etc/SystemDefinition.lua"
fi

#echo -e "Working with $systemdefinition_file."

$scriptdir/ClusterMod_tools/check_systemdefinition.lua $systemdefinition_file
