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
cd ..
repo_modules=${PWD##*/}
cd ..
installroot="$(pwd)"
repo_easybuild="${repo_modules/modules/easybuild}"

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
mkdir -p "$installroot/sources"
mkdir -p "$installroot/$systemmodules"
mkdir -p "$installroot/$systemmodules/stacks"
mkdir -p "$installroot/$systemmodules/arch"
mkdir -p "$installroot/$systemmodules/infrastructure"
mkdir -p "$installroot/$systemmodules/init-$repo_modules"

#
# Link the style modules
#
# We simply link the directory.
#
create_link "$installroot/$repo_modules/generic-modules/StyleModifiers" "$installroot/$systemmodules/StyleModifiers"

#
# Install the CalcUA-init module
#
mkdir -p "$installroot/$systemmodules/init-$repo_modules/CalcUA-init"
for file in $(find $installroot/$repo_modules/generic-modules/CalcUA-init -name "*.lua")
do
	create_link $file $installroot/$systemmodules/init-$repo_modules/CalcUA-init/${file##*/}
done

