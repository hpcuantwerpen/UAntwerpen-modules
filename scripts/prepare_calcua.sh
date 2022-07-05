#! /bin/bash
#
# Script to initialize the CalcUA module system.
#
# The script takes no arguments.
#
# The root of the installation is derived from the place where the script is found.
# The script should be in <installroot>/${repo}/scripts with <installroot> the
# root for the installation.
#

# That cd will work if the script is called by specifying the path or is simply
# found on PATH. It will not expand symbolic links.
cur_dir="$PWD"
cd "$(dirname $0)"
scriptdir=$PWD
cd ..
default_repo_modules_name=${PWD##*/}
cd ..
script_installroot="$(pwd)"
default_repo_easybuild_name="${default_repo_modules_name/modules/easybuild}"
cd "$cur_dir"

#
# Function to print the help information
#
function print_help {

  echo "Help will follow."

}

#
# Process the command line arguments.
#
systemdefinition_given=0   # Set to 1 if a specific system definition file is given through a command line argument.
installroot_given=0        # Set to 1 if an alternative installroot is given
easybuild_given=0          # Directory with EasyBuild modules (default is derived from the directory with the scripts)
repair=0                   # If set to one, an existing installation is repaired or added to, and the script will
                           # look for a etc/SoftwareStack.lua file.
debug=0

while test $# -gt 0 
do

  case $1 in

    -h|--help)
      shift
      print_help
      exit
      ;;

    -d|--debug)
      shift
      debug=1
      ;;

    -r|--repair)
      shift
      repair=1
      ;;

    -i|--installroot)
      shift
      installroot_given=1
      installroot="$1"
      shift
      ;;

    -s|--systemdefinition)
      shift
      systemdefinition_given=1
      systemdefinition="$1"
      shift
      ;;

    -e|--easybuild)
      shift
      easybuild_given=1
      easybuild="$1"
      shift
      ;;

  esac  # case $1

done # while test $# -gt 0

if [ $debug -eq 1 ]
then
  echo "Installroot from which the script is run:                 $script_installroot"
  echo "Default UAntwerpen-modules repo name:                     $default_repo_modules_name"
  echo "Default EasyBuild repo name:                              $default_repo_easybuild_name"
  if [ $repair -eq 0 ]
  then
    echo "Starting a new installation (or overwriting existing settings)"
  else
    echo "Repairing an existing installation"
  fi
  if [ $installroot_given -eq 1 ]
  then
    echo "Requested installroot (through command line flag):        $installroot"
  fi
  if [ $systemdefinition_given -eq 1 ]
  then
    echo "Requested system definition (through command line flag):  $systemdefinition"
  fi
  if [ $easybuild_given -eq 1 ]
  then
    echo "Requested EasyBuild repository (through command line flag): $easybuild"
  fi
fi

if [ $installroot_given -eq 0 ]
then
  installroot="$script_installroot"
fi

if [ $repair -eq 0 ]
then

  # Setting up a new installation.

  link_repo_modules="$script_installroot/$default_repo_modules_name"

  if [ $easybuild_given -eq 0 ]
  then
    link_repo_easybuild="$script_installroot/$default_repo_easybuild_name"
  else
    if [[ $easybuild =~ ^/ ]]
    then
      link_repo_easybuild="$easybuild"
    else
      link_repo_easybuild="$cur_dir/$easybuild"
    fi
  fi

  if [ $systemdefinition_given -eq 0 ]
  then
    link_systemdefinition="$script_installroot/$default_repo_modules_name/etc/SystemDefinition.lua"
  else
    if [[ $systemdefinition =~ ^/  ]]
    then
      link_systemdefinition="$systemdefinition"
    else
      link_systemdefinition="$cur_dir/$systemdefinition"
    fi
  fi

  softwarestack="$installroot/etc/SoftwareStack.lua"

  echo -e "\nSetting up software installation:"
  echo "- Root directory of the software installation: $installroot"
  echo "- System definition file:                      $link_systemdefinition"
  echo "- Module code repo:                            $link_repo_modules"
  echo "- EasyBuild repo:                              $link_repo_easybuild"
  echo "- Configuration will be saved in:              $softwarestack"
  echo ""

  # TODO: Check if $installroot/etc/SoftwareStack.lua already exists. If so, 
  # produce an error message.
  
  mkdir -p "$installroot/etc"
  echo "installroot =      '$installroot'"            > $softwarestack
  echo "systemdefinition = '$link_systemdefinition'" >> $softwarestack
  echo "repo_modules =     '$link_repo_modules'"     >> $softwarestack
  echo "repo_easybuild =   '$link_repo_easybuild'"   >> $softwarestack

else

  # Repairing an existing installation

  if [ $systemdefinition_given -ne 0 ]
  then
    echo -e "\nERROR: -s/--systemdefinition should not be used togehter with -r/--repair"
    exit
  fi

  if [ $easybuild_given -ne 0 ]
  then
    echo -e "\nERROR: -e/--easybuild should not be used togehter with -r/--repair"
    exit
  fi

  softwarestack="$installroot/etc/SoftwareStack.lua"

  # TODO: Check if $softwarestack exists and produce an error message otherwise.
  # TODO: Read the settings to give some feedback.

  echo -e "\nRepairing an existing software installation defined by $softwarestack\n"

fi

$scriptdir/calcua_tools/prepare_calcua.lua "$softwarestack"
