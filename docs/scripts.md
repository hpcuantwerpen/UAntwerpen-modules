# Scripts

## enable_ClusterMod.sh

The `enable_ClusterMod.sh` script prints the shell commands needed to enable the CalcUA
stacks in a format suitable to be used with the `eval` bash shell function.

Without arguments it assumes that the software stack is located two levels towards the
root of the file system hierarchy from the location of the script. Alternatively it
is possible to give the root of the software stack as an argument to the script.

Besides setting a number of `LMOD_` environment variables to configure Lmod, it also sets
the `CLUSTERMOD_SOFTWARESTACK` environment variable which points to the configuration file
(itself a Lua script) of the software stack. Note that we need this variable to find 
the system definition file which then tells the name of the cluster which is why we 
cannot use the name of the cluster in the name of the environment variable.


## check_systemdefinition.sh

This script runs a whole set of tests again the system definition file to check for inconsistencies
or possible mistakes. 

Without command line arguments it will check the default file `etc/SystemDefinition.lua` in the parent
directory of the directory containing the `check_systemdefinition.sh` script,
but it is also possible to point the script to a different system definition file on the command line.

It is certainly not a guarantee that there are no inconsistencies in the file, though it 
is an extensive set of tests.


## check_clusternode.sh

The `check_clusternode.sh` script prints information about the node it is running on and 
can also be used to check if the node is properly supported by a given system definition.

Just as `check_systemdefinintion.sh`, without 
command line arguments it will check the default file `etc/SystemDefinition.lua` in the parent
directory of the directory containing the `check_clusternode.sh` script,
but it is also possible to point the script to a different system definition file on the command line.


## prepare_ClusterMod.sh

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
  the directory in which the `prepare_ClusterMod.sh` script is located.

-  `-s` or `--systemdefinition`: The system definition file, with an absolute path or
   path relative to the current directory.

   The default is `etc/SystemDefinition.lua` located in the parent directory of the
   directory where the `prepare_ClusterMod.sh` script is found.
  
- `-r` or `--repair`: Runs the script in repair mode.

  One can still indicate the installation directory and the script will then search in that
  directory to locate eth `etc/SoftwareStack.lua` file. However, the `-e`/`--easybuild`
  and `-s`/`--systemdefinition` flags should not be used as that data comes from the
  `etc/SoftwareStack.lua` file.


- `-d` or `--debug`: Mostly useful during development, prints additional debug information.


## update_easybuild.sh

This script checks if all the necessary versions of EasyBuild are installed.

When given without arguments, it tries to locate the `SoftwareStack.lua` file
relative to its own location. However, the root of the installation (which then
contains `etc/SoftwareStack.lua`) can be given as a command line argument.

The versions of EasyBuild that should be installed are derived from the
`ClusterMod_SystemProperties` in the system definition file refered to by the
`SoftwareStack.lua` file. Note that the necessary EasyConfig files should be 
present, or the script will produce an error message.

