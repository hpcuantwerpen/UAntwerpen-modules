# Design decisions

-   Separate module roots for infrastructure modules that follow a strict
    Lmod hierarchy and for the easybuild-managed modules that are arranged 
    by software stack and architecture.

-   At the top of the hierarchy, in the installation root, we find the GitHub
    repositories with the module system and the EasyBuild configuration, the roots
    of the infrastructure module system and the EasyBuild module system, the software
    packages tree, and the EasyBuild repo of installed software.

    We have chosen this option to be able to use short names for software directories
    without reducing the readability of the names of the module file directories, and 
    as such also to keep the size of shebang lines with full pahts under control to not
    hit kernel-imposed limits.

-   We distinguish between two types of system-wide installed software:

    -   Software installed via EasyBuild (though with some tricks). That software appears
        in the EasyBuild-managed modules and EasyBuild repo also.

    -   Software installed without using EasyBuild, with modules that are generated 
        via dummy EasyConfig files in the EasyBuild hierarchy.

## Full layout

**To be corrected!!!**

/apps

`+ `/antwerpen

`. +-`/CalcUA

`. . |-`/**UAntwerpen-modules**: Repository with LMOD configuration and
generic modules

`. . |-`/**UAntwerpen-easybuild:** EasyBuild setup

`. . | +-`/*easybuild*

`. . | . |-`/easyconfigs

`. . | . |-`/easyblocks

`. . | . |…`Customisations to naming schemes etc.

`. . | . +-`/config: Configuration files for some settings not done via
environment

`. . |-`/**modules-infrastructure**: Lmod hierarchy as the framework of the module system

`. . | |-`/*stacks*: First level: Software stack modules

`. . | | |-`/calcua

`. . | | . |-`/2021b.lua: Symbolic link to a generic module!

`. . | |-`/*arch*: Second level: Architecture of the stack

`. . | | |-`/calcua

`. . | | . |-`/2021b

`. . | | . . |-`/cluster

`. . | | . . | |-`/hopper.lua: Symbolic link to a generic module!

`. . | | . . | |-`/leibniz.lua

`. . | | . . | |-`/leibniz-skl.lua

`. . | | . . | |-`/vaughan.lua

`. . | | . . | +-`/generic.lua

`. . | | . . +-`/arch

`. . | | . . . |-`redhat8-x86_64

`. . | | . . . |-`redhat8-broadwell-noaccel

`. . | | . . . +-`redhat8-broadwell-quadro

`. . | |-`/*infrastructure*: Third level: Infrastructure modules, e.g., EasyBuild configuration

`. . | . |-`/CalcUA

`. . | . . |-`/2021b

`. . | . . . |-`/arch

`. . | . . . . |-`/redhat8-ivybridge-noaccel

`. . | . . . . . |-`/EasyBuild-production

`. . | . . . . . |-`/EasyBuild-infrastructure

`. . | . . . . . |-`/EasyBuild-user

`. . |-`/**modules-easybuild**: Modules generated with EasyBuild

`. . | |-`/*CalcUA-2021b*

`. . | | |-`redhat8_x86_64 : Directory for potential generic builds if
performance does not matter

`. . | | |-`redhat8-broadwell-noaccel

`. . | | +-`redhat8-broadwell-quadro

`. . | +-`/*system*: Modules outside the regular software stacks

`. . | . |-`redhat8 : No specific processor versions, e.g., Matlab

`. . | . +-`redhat8-ivybridge : Specific processor version, e.g.,
Gaussian

`. . |-`/**modules-MNL**: Manualy generated modules - OPTIONAL

`. . +-`/**SW**

`. . . |-`*CalcUA-2021b*

`. . . | |-`RH8-x86_64

`. . . | |-`RH8-BRW-host

`. . . | +-`RH8-BRW-NVGP61GL

`. . . |-`/*system*: Sometimes relatively empty subdirs if EasyBuild only
creates a module.

`. . . | |-`RH8

`. . . | +-`RH8-IVB

`. . . +-`/*MNL*: Manually installed software. 

`. . . . +-`RH8-x86_86
