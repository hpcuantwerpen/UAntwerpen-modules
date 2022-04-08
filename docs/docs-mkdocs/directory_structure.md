# Directory structure of the repository and software stack

## The modules repository

Installed as 'UAntwerpen-modules' in the software stack directory

Subdirectories

  * [docs](https://github.com/klust/UAntwerpen-modules/tree/main/docs): 
    The technical documentation for the setup

  * [etc](https://github.com/klust/UAntwerpen-modules/tree/main/etc): 
    Place to store the message-of-the-day file and the tips list.

  * [generic-modules](https://github.com/klust/UAntwerpen-modules/tree/main/generic-modules): 
    Generic implementation of the software stack and EasyBuild configuration modules.

      * [CalcUA-init](https://github.com/klust/UAntwerpen-modules/tree/main/generic-modules/CalcUA-init): 
        Initialisation module for the software stack, removing some of that stuff from the system images.

      * [calcua](https://github.com/klust/UAntwerpen-modules/tree/main/generic-modules/calcua): 
        Software stack module for the CalcUA software stacks.

      * [clusterarch](https://github.com/klust/UAntwerpen-modules/tree/main/generic-modules/clusterarch): 
        Module to select the desired machine architecture for the software.

      * [EasyBuild-config](https://github.com/klust/UAntwerpen-modules/tree/main/generic-modules/EasyBuild-config): 
        Generic configuration module for EasyBuild

      * [StyleModifiers](https://github.com/klust/UAntwerpen-modules/tree/main/generic-modules/StyleModifiers):
        modules to change the display style of the module tree. 

  * [LMOD](https://github.com/klust/UAntwerpen-modules/tree/main/LMOD): Module with the configuration files for LMOD.

  * [scripts](https://github.com/klust/UAntwerpen-modules/tree/main/scripts): Various scripts to set up and maintain the software stack.

  * [scripts-dev](https://github.com/klust/UAntwerpen-modules/tree/main/scripts-dev): Various scripts used during the 
    development of the this repository, to test concepts.


## The UAntwerpen-easybuild repository

This is the repository containing our full EasyBuild setup with custom EasyBlocks and
EasyConfigs, the hooks file, configuration files, etc.

