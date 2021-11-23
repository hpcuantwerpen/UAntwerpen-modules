#! /bin/bash
#
# Script to initialize the LUMI module system.
#
# The script takes no arguments.
#
# The root of the installation is derived from the place where the script is found.
# The script should be in <installroot>/${repo}/scripts with <installroot> the
# root for the installation.
#

# That cd will work if the script is called by specifying the path or is simply
# found on PATH. It will not expand symbolic links.
cd "$(dirname $0)"
cd ../..
installroot="$(pwd)"

#
# Some constants
#
stackname='calcua'
systemmodules='modules-infrastructure'

#
# Functions used in this script
#

create_link () {

#  echo "Linking from: $1"
#  echo "Linking to: $2"
#  test -s "$2" && echo "File $2 found."
#  test -s "$2" || echo "File $2 not found."
  test -s "$2" || ln -s "$1" "$2"

}

#
# Create some of the directory structure
# We use more commands than strictly necessary, which can give more precise
# error messages.
#
mkdir -p "$installroot/$systemmodules"
mkdir -p "$installroot/$systemmodules/stacks"
mkdir -p "$installroot/$systemmodules/arch"
mkdir -p "$installroot/$systemmodules/infrastructure"



