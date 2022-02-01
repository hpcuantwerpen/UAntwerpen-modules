# Directory structure of the repository and software stack

## The modules repository

Installed as 'UAntwerpen-modules' in the software stack directory

Subdirectories

  * [docs](./README.md): The technical documentation for the setup

  * [etc](../etc): Place to store the message-of-the-day file and the tips list.

  * [generic-modules](../generic-modules): Generic implementation of the software stack
    and EasyBuild configuration modules.

      * [CalcUA-init](../generic-modules/CalcUA-init): Initialisation module for the
        software stack, removing some of that stuff from the system images.

      * [calcua](../generic-nodules/calcua): Software stack module for the CalcUA software stacks.

      * [cuslterarch](../generic-modules/clusterarch): Module to select the desired machine
        architecture for the software.

      * [EasyBuild-config](../generic-modules/EasyBuild-config): Generic configuration module for
        EasyBuild

  * [LMOD](../LMOD): Module with the configuration files for LMOD.

  * [scripts](../scripts): Various scripts to set up and maintain the software stack.

  * [scripts-dev](../scripts-dev): Various scripts used during the development of the this repository,
    to test concepts.


## The UAntwerpen-easybuild repository

This is the repository containing our full EasyBuild setup with custom EasyBlocks and
EasyConfigs, the hooks file, configuration files, etc.

