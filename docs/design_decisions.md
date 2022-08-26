# Design decisions

## Software stack modules

-   The name of the stack, `calcua`, is not hard-coded but specified through a variable
    in the system definition so that a future version may be extended to support more
    sites.

-   The software stack has two levels:

    1.  Version of the software stack: `calcua` module.
    2.  Hardware architecture

    However, when loading a module from the first level we try to automatically 
    determine the most suitable module for the second level.

-   A hardware architecture can have subarchitectures, see the discussion in 
    the ["The generic calcua and clusterarch modules" page](modules_calcua_and_clusterarch.md).

    The final decision is to go for only two levels: a generic one and one
    specialised for the full architecture (including the accelerator) though
    the implementation is done such that this could be changed for a later
    version of the software stack. It will create a lot more files as a lot more
    packages will be installed multiple times, but it reduces complexity and the
    chance for error of installing a package at the wrong level.

-   The latter implies that we will need a double tree of modules

    -   One follows very strictly the Lmod hierarchy rules. Only one directory at any level
        of this tree can be present in the `MODULEPATH`. This tree is called the
        **infrastructure modules**.

    -   The second tree contains the actual software. Multiple subdirectories from
        this tree can be in the `MODULEPATH` at the same time, e.g., the directory
        for modules compiled with generic options and directory with modules 
        optimised for a specific node type.

    To ensure that module swapping works correctly in Lmod (with Lmod trying to find
    equivalent versions when changing the hardware architecture), it is important
    that each software package is installed at one and only one level in the architecture
    hierarchy. So one should install a package either only for the generic architecture,
    or for all relevant specific architectures, but not in a generic way and some specific
    architectures.

-   The module `calcua/system` is a *special version* of the `calcua` module for software
    that fulfills two requirements:

    1.  We want it to be available for any regular version of the `calcua` stack
    2.  It is build using the `SYSTEM` toolchain (or installed in an equivalent way)

    This is basically the tree to install software from binaries or to create modules for
    manually installed software (e.g., MATLAB and MAPLE). The stack is managed through
    EasyBuild though.

    The code of the module tree is largely prepared to have an architecture hierarchy
    there too, but we may not use it initially. The tree could be used to, e.g.,
    accomodate Gaussian and automatically offer the right version rather than have multiple
    versions with versionsuffix for the architecture.

-   3 modules are needed to configure EasyBuild (though they are implemented as one generic
    module):

    -   `EasyBuild-infrastructure` for the few modules that need to be installed in the 
        infrastructure tree (if any as on LUMI where this approach is also used basically
        only the toolchains are installed with EasyBuild, and they only belong in the
        infrastructure tree tp be able to always load the correct target modules as
        needed by the HPE Cray Programming Environment).

    -   `EasyBuild-production` for installing software with EasyBuild in the central software
        stack

    -   `EasyBuild-user` for installing software with EasyBuild in the user's directories.

-   We support a 3-level and a 2-level naming scheme.

    -   At the top level and the bottom level (most generic level) there is no difference 
        between both schemes.

        -   Top level always uses 3-component names: OS-CPU-Accelerator.

        -   Generic level names do not include an accelerator.

    -   In the `ClusterMod_SystemTable` that defines which architectures have software stacks 
        for which stack version, only generic CPU names or CPU-Accelerator pairs are
        supported

        Impact of omitting that restriction and supporting a module and software hierarchy 

        -   Changes to the `get_stack_top` function needed.

        -   Needs changes to `get_osarchs` and `get_osarchs_reverse`.


## Directory structure

Separate module roots for infrastructure modules that follow a strict
Lmod hierarchy and for the easybuild-managed modules that are arranged 
by software stack and architecture.

We also put software and modules build with EasyBuild in two fully
separate trees in the installation root rather than always putting
the software and its modules next to each other as is done in the
default EasyBuild configuration.
We have chosen this option to be able to use short names for software directories
without reducing the readability of the names of the module file directories, and 
as such also to keep the size of shebang lines with full paths under control to not
hit kernel-imposed limits.

### Configuration part of the tree

At the top of the hierarchy, in the installation root, there is an
`etc` subdirectory with currently only the `SoftwareStack.lua` configuration
file which is created automatically by the software stack installation script
and is used to point to a number of important files and (sub)directories:

1.  The LUA system definition file that should be used
2.  The repository with the LMOD configuration and generic modules (see below)
3.  The repository with the whole EasyBuild setup, including custom EasyBlocks and
    custom EasyConfigs.

***Configuration part of the tree***
``` bash
InstallRoot
 └─ etc
```

### (Optional) repository part of the tree

At the top of the hierarchy, in the installation root, we find the GitHub
repositories with the module system and the EasyBuild configuration, the roots
of the infrastructure module system and the EasyBuild module system, the software
packages tree, and the EasyBuild repo of installed software.

Though both repositories are needed for the stack to work, it is possible to have
them elsewhere, which may be a good option for test stacks or for development
where you may want the repositories in a place that works better with your 
remote software development tools.

***(Optional) repository part of the tree***  
``` bash
InstallRoot
 ├─ UAntwerpen-modules #(1)
 └─ UAntwerpen-easybuild #(2)
     └─ easybuild
         ├─ easyconfigs
         ├─ easyblocks
         ├─ Customisations to naming schemes etc
         └─ config #(3)
```

1.  Repository with LMOD configuration and generic modules
2.  EasyBuild setup
3.  Configuration files for some settings not done via environment


### Module part of the tree

-   We distinguish between two types of system-wide installed software that is not using
    EasyBuild toolchains (except `SYSTEM`):

    -   Software installed via EasyBuild (though with some tricks)  That software appears
        in the EasyBuild-managed modules and EasyBuild repo also.

        The software is installed via a dummy version of the calcua software stack
        (`calcua/system`) with its own copy of EasyBuild.  

    -   Software installed without using EasyBuild, with modules that are generated 
        via dummy EasyConfig files in the EasyBuild hierarchy.

-   Infrastructure modules: `modules-infrastructure`

    -  The hierarchy is build using the long names for the architecture string

    -   `init-UAntwerpen-modules`: Outside the hierarchy: Subdirectory for the module(s) that 
        initialises the whole module setup.

        Loading the initialisation module enables loading of the next level, the software
        stack modules.

    -   `stacks` subdirectory contains the modules for the software stack, currently only
        `calcua` modules, but that leaves room for a different software stack, e.g., EESSI, 
        later onn.

        Loading of a `calcua` module enables the next level, loading of an architecture
        module.

    -   `arch` subdirectory contains the architecture modules (or cluster modules).

        2 levels of subdirectories before you reach the architecture modules:

        1.  Name of the stack: `calcua`
  
        2.  Version of the stack
       
        Modules named after the cluster could be easier to recognise for some users. However,
        it may also be tricky to implement. Instead we can also use cluster names as the version
        of the `arch` modules, and this is organised via `.modulerc.lua` files for each software
        stack in the `arch` module subdirectory.

        Loading an architecture module enables the next step in the hierarchy, loading the 
        infrastructure modules and software modules.

    -   `infrastructure` subdirectory then contains the specific infrastructure modules, e.g.,
        the EasyBuild configuration modules.

        4 levels of subdirectories before you reach the infrastructure modules

        1.  Name of the stack: `calcua`

        2.  Version of the stack

        3.  `arch`

        4.  Long name string of the architecture (OS-CPU-Accelerator except for OS-x86_64).


-   EasyBuild-managed modules: `modules-easybuild`

    Here we treat the system-wide installed software which is independent from any calcua software
    stack as a separate software stack without version  Architecture-wise both are treated the same,
    though we expect that most if not all system-wide installed software will be installed in a
    generic architecture subdirectory.

    2 levels before arriving at the actual infrastructure modules:

    1.  Name-version of the software stack, e.g., `calcua-2021b` or `system`

    2.  Architecture string

-   Manually managed modules: `modules-manual`

    A space to put modules for the manually installed software in case we want to hand-code 
    these modules rather then inject them elsewhere via EasyBuild.

    The precise structure will be determined when the need arrises.

-   This leads to the following view on the modules tree:

    ``` bash
    InstallRoot
     ├─ modules-infrastructure #(1)
     │   ├─ init-UAntwerpen-modules #(2)
     │   ├─ stacks #(3)
     │   │   └─ calcua
     │   │       └─ 2021b.lua #(4)
     │   ├─ arch #(5)
     │   │   └─ calcua
     │   │       ├─ 2021b
     │   │       │   └─ arch
     │   │       │       ├─ redhat8-x86_64
     │   │       │       ├─ redhat8-broadwell-noaccel
     │   │       │       └─ redhat8-broadwell-quadro
     │   │       └─ system
     │   │           └─ arch
     │   │               ├─ redhat8-x86_64
     │   │               └─ redhat8-ivybridge-noaccel
     │   └─ infrastructure #(6)
     │       └─ calcua
     │           └─ 2021b
     │               └─ arch
     │                   └─ redhat8-ivybridge-noaccel
     │                       ├─ EasyBuild-production
     │                       ├─ EasyBuild-infrastructure
     │                       └─ EasyBuild-user
     ├─ modules-easybuild #(7)
     │   ├─ calcua-2021b
     │   │   ├─ redhat8_x86_64 #(8)
     │   │   ├─ redhat8-broadwell-noaccel
     │   │   └─ redhat8-broadwell-quadro
     │   └─ system* #(9)
     │       ├─ redhat8-x86_64 #(10)
     │       └─ redhat8-ivybridge-noaccel #(11)
     └─ modules-manual #(12)!
    ```
    
    1.  Lmod hierarchy as the framework of the module system 
    2.  Subdirectory for the startup module
    3.  First level: Software stack modules
    4.  Symbolic link to a generic module!
    5.  Second level: Architecture of the stack
    6.  Third level: Infrastructure modules, e.g., EasyBuild configuration
    7.  Modules generated with EasyBuild
    8.  Directory for potential generic builds if performance does not matter
    9.  Modules outside the regular software stacks
    10. No specific processor versions, e.g., Matlab
    11. Specific processor version, e.g., Gaussian
    12. Manually generated modules - OPTIONAL


### Software directory `SW`

This directory follows the same layout as the one for the EasyBuild-installed software,
with two differences:

1.  At the architecture level, the short architecture string is used to save space

2.  There is yet another pseudo-stack for manually installed software, called `MNL`  

    This directory has no corresponding modules directory in the EasyBuild-managed directory
    as it is not managed at all by EasyBuild.

***Resulting structure of the software directory***  
``` bash
InstallRoot
 └─ SW
     ├─ calcua-2021b
     │   ├─ RH8-x86_64
     │   ├─ RH8-BRW-host
     │   └─ RH8-BRW-NVGP61GL
     ├─ system #(1) 
     │   ├─ RH8-x86_64
     │   └─ RH8-IVB-host
     └─ MNL #(2)
```

1.  Sometimes relatively empty subdirs if EasyBuild only creates a module...
2.  Manually installed software


### Manangement subdirectory

`mgmt` subdirectory for all (nearly) files that are somehow system-generated.

Current subdirectories:

-   `ebfiles_repo`: EasyBuild repository, structured the same way as the `modules-easybuild`
    subdirectory.

-   `ebfiles_repo_infrastructure`: EasyBuild repository, structured the same way as the `modules-infrastructrue/infrastructure`
    subdirectory.

-   `lmod-cache`: Placeholder for Lmod cache files.

    Maybe we should follow the approach of TCL Environment Modules 5 and have a separate cache
    file per module subdirectory, or does this become too much? We can also go for one corresponding to each software stack and cluster architecture combination which would
    result in a single file per ( software stack, architecture) combination.

***Resulting structure of the management directory***  
``` bash
InstallRoot
 └─ mgmt
     ├─ ebfiles_repo
     │   ├─ calcua-2021b
     │   │   ├─ redhat8-x86_64
     │   │   └─ redhat8-broadwell-noaccel
     │   └─ system #(1)
     │       └─ redhat8-x86_64 #(2)
     ├─ ebfiles_repo_infrastructure
     │   ├─ calcua-2021b
     │   │   ├─ redhat8-x86_64
     │   │   └─ redhat8-broadwell-noaccel
     │   └─ system #(1)
     │       └─ redhat8-x86_64 #(2)
     └─ lmod_cache
```

1.  Modules outside the regular software stacks
2.  No specific processor versions, e.g., Matlab


### Other subdirectories

-   `sources` subdirectory to permanently store the sources. This directory is
    further organised in the EasyBuild way. Downloads for manually installed
    software can be added to it by putting it in the EasyBuild structure.

    In the future we may need to add an additional level to distinguish between
    EasyBuild and other build tools that we may use and that have a different
    structure for storing source files.

***Other subdirectories***
``` bash
InstallRoot
 └─ sources
```

