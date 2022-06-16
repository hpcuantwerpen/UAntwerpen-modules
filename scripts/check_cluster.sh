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
cd $(dirname $0)
scriptdir=$PWD

$scriptdir/calcua_tools/check_cluster.lua
