# The SitePackage.lua file and its included routines

  * SitePackage_map_toolchain.lua : Mapping regular toolchain names onto yyy.mm for
    comparisons to find matching versions of some files.

  * SitePackage_arch_hierarchy.lua : Routines to work with the hierarchy of
    architectures and map between long and short names.

Some of the data structures, in particular those that need to be extended with each
new toolchain and really define the setup of the system, are not in the LMOD subdirectory
but instead in the file `etc/SystemDefinition.lua`.


## etc/SystemDefinition.lua

-   `CalcUA_SystemTable`: Defines the whole structure of the software tree, including the manually
    installed software and system-wide EasyBuild managed software. Note that the table will be
    completed automatically with more generic os-cpu-accelerator architecture strings based
    on the other tables in this file.

    **TODO** Explain the structure.

-   `CalcUA_ClusterMap`: Contains for each version of the calcua toolchains, including
    the dymmy system version, a mapping from cluster names to os-architecture strings.

    **TODO** Explain the structure.

-   `CalcUA_toolchain_map`: Associative table, with the yyyy[a|b] toolchains as the keys and
    the matching yyyymm value as the value (note: no dot, not yyyy.mm)

-   `CalcUA_map_arch_hierarchy`: An associative table of associative tables with for each supported
    OS a table that can be used to determine the parent of every CPU/accelerator
    architecture.

    -   First level: The keys are the yyyymm versions of toolchains, the values the matching
        associative table. These toolchain versions are "starting from", so not every toolchain
        needs to be specified.

    -   Second level: Associative table with as keys the CPU/GPU architecture
        string and as value the parent GPU/architecture string, or `nil` if it is
        the top (= most generic) architecture.


## SitePackage_map_toolchain.lua

Data structures:

-   Uses `CalcUA_toolchain_map` from `etc/SystemDefinition.lua`

Routines:

-   `map_toolchain`:  Returns the matching yyyy.mm toolchain for any toolchain. The
    input argument can be either a yyyy.mm toolchain version (in which case the
    routine simply returns that version without the dot) or a yyyy[a|b] version in
    which case the routine uses the `CalcUA_toolchain_map` to compute the matching
    yyyymm version or falls back to a default rule (where a becomes 01 and b becomes
    07).
    
-   `get_versionedfile`: Finds the most recent file with version not younger than a
    given toolchain, with the file matching a particular pattern given as a directory,
    part before the version and part after the version. The version can be in any
    format supported by `map_toolchain`: yyyy[a|b], yyyy.mm, yyyymm, `system`.


## SitePackage_arch_hierarchy.lua

Data structures

-   Uses `CalcUA_map_arch_hierarchy` from `etc/SystemDefinition.lua`.

-   `map_os_long_to_short`: Map long names of the OS to their short equivalent
    (name does not include the version).

-   `map_cpu_long_to_short`: Map the long CPU name to their short equivalent.

-   `map_accel_long_to_short`: Map the accelerator architecture from their long
    name to their short equivalent.

Routines:

-   Discover the architecture hierarchy

    -   `get_long_osarchs`: For a given OS (long name + version) and architecture
        (long name, CPU + optionally accelerator), return a table which also includes
        the parent and potentially grandparent of the architecture for the given OS.

        The order in the table is from the least generic architecture to the most
        generic one.

    -   `get_long_osarchs_reverse`: Same as `get_long_osarchs`, but now with the
        most generic one first and least generic one (the one used as the argument
        of the function) last.

-   Mapping between different formats of names

    -   `map_long_to_short`: Map full long name (OS+version-CPU-accelerator) to the
        equivalent short name. It also works for names that do not include the
        accelerator.

    -   `map_short_to_long`: Map full short name (OS+version-CPU-accelerator) to the
        equivalent long name. It also works for names that do not include the
        accelerator.

-   Extracting parts from the os-cpu-accelerator strings:

    -   `extract_os`  : Extracts the first part of the os-cpu-acceleartor argument

    -   `extract_cpu` : Extracts the second part of the os-cpu-accelerator argument

    -   `extract_accel` : Extracts the third part of the os-cpu-accelerator argument,
        or returns `nil` if there is no accelerator part in the argument.

    -   `extract_arch` : Extracts the second and (optional) third part of the
        os-cpu-accelerator argument, i.e., returns cpu-accelerator or just cpu if there
        is no accelerator part.


-   Computing directories

    -   `get_system_module_dir`: Compute the module directory from the three input arguments:
        long os-and-architecture name, stack name and stack version.

        The directory name returned is relative from the installation root, with the most
        generic one first.

        Note `system` in the name does not denote the `system` stack but the whole
        system installation, versus the user installation.

    -   `get_system_module_dirs`: Compute the module directory hierarchy from the three input
        arguments: long os-and-architecture name, stack name and stack version.

        The directory names returned are relative from the installation root, with the most
        generic one first.

