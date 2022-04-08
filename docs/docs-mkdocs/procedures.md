# Some procedures

Procedures in this document:

-   Starting a new software stack

-   Upgrading EasyBuild in an existing software stack

-   Adding a new node type to the CalcUA infrastructure


## Starting a new software stack

Code to check:

-   Table `toolchain_map` in `SitePackage_map_toolchain.lua`: Add an entry for the
    new toolchain.

**TODO**


## Upgrading EasyBuild in an existing software stack

Software stacks on the CalcUA infrastructure may have a long life before they are being
superseded with a new one based on newer compilers. Hence it may make sense to upgrade
EasyBuild during the life of the software stack. However, upgrading EasyBuild may break
things and hence should be done with care and proper testing.

**TODO** Outline safe procedures and practices.


## Adding a new node type to the CalcuUA infrastructure

The following files/routines may need changes: **TODO**

-   Tables in `LMOD/SitePackage_arch_hierarchy.lua`
-   Tables in `LMOD/SitePackage_system_info.lua` to be able to detect the hardware.
-   Check if the code for `get_Accelerator_info()` in `LMOD/SitePackage_system_info.lua`
    is still suitable. The `scripts-dev` directory contains the script `test_sysinfo.lua`
    which is perfect for this purpose.
-   System definition in `etc/SystemDefinition.lua` (really more to determine which 
    software stacks are available).

## Upgrading the OS

-   Check the tables for the translation of the OS name as reported by the system to
    supported names in `LMOD/SitePackage_system_info.lua`


