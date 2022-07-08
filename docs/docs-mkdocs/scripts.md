# Scripts

## enable_CalcUA.sh

The `enable_CalcUA.sh` script prints the shell commands needed to enable the CalcUA
stacks in a format suitable to be used with the `eval` bash shell function.

Without arguments it assumes that the software stack is located two levels towards the
root of the file system hierarchy from the location of the script. Alternatively it
is possible to give the root of the software stack as an argument to the script.


## check_clusternode.sh

The `check_clusternode.sh` script prints information about the node it is running on and 
can also be used to check if the node is properly supported by the CalcUA stacks,
or if certain settings need to be adjusted.

Without command line arguments it will check the default file in `UAntwerpen-modules/etc/SystemDefinition.lua`,
but it si also possible to point the script to a different system definition file on the command line.

## prepare_calcua.sh

This script is used to set up or extend the whole structure of the software stack.
It should be run whenever new software stack versions are started or new nodes are added
to the cluster. It tries to not be destructive to whatever files are already there, but
will of course replace them when needed.

The script will create the `etc/SoftwareStack.lua` file in the indicated install directory
unless it is run in repair mode. This script is very essential in the whole module system:
it helps many other components to find the location of other files.

The script has several command line arguments:

- `-h` or `--help`: Print help information and exit.

- `-i`or `--installroot`: Points to the directory where the software stack should be
  installed. The default value is derived from the location of the script (i.e., two
  directories towards the root in the hierarchy).

- `-e` or `--easybuild`: The absolute or relative path (with respect to the current
  directory) of the repository with all custom EasyBuild files.

  The default is `UAntwerpen-easybuild` located two directories towards the root of
  the directory in which the `prepare_calcua.sh` script is located.

-  `-s` or `--systemdefinition`: The system definition file, with an absolute path or
   path relative to the current directory.

   The default is `etc/SystemDefinition.lua` located in the parent directory of the
   directory where the `prepare_calcua.sh` script is found.
  
- '-r` or `--repair`: Runs the script in repair mode.

  One can still indicate the installation directory and the script will then search in that
  directory to locate eth `etc/SoftwareStack.lua` file. However, the `-e`/`--easybuild`
  and `-s`/`--systemdefinition` flags should not be used as that data comes from the
  `etc/SoftwareStack.lua` file.


- `-d` or `--debug`: Mostly useful during development, prints additional debug information.


## prepare_calcua_stack.sh

NOT NEEDED ANYMORE?

## update_easybuild.sh

TODO: First fix where we will install EasyBuild...

