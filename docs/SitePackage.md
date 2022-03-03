# The SitePAckage.lua file and its included routines

  * SitePackage_map_toolchain.lua : Mapping regular toolchain names onto yyy.mm for
    comparisons to find matching versions of some files.

  * SitePackage_arch_hierarchy.lua : Routines to work with the hierarchy of
    architectures and map between long and short names.



## SitePackage_map_toolchain.lua

Data structures:

  * `toolchain_map`: Associative table, with the yyyy[a|b] toolchains as the keys and
    the matching yyy.mm value as the value.

Routines:

  * `map_toolchain`:  Returns the matching yyyy.mm toolchain for any toolchain. The
    input argument can be either a yyyy.mm toolchain version (in which case the
    routine simply returns that version) or a yyyy[a|b] version in which case the
    routine uses the `toolchain_map` to compute the matching yyyy.mm version.


## SitePackage_arch_hierarchy.lua

Data structures

  * `map_os_arch`: An associative table of associative tables with for each supported
    OS a table that can be used to determine the parent of every CPU/accelerator
    architecture.

      * First level: The keys are the long names of the OS, the values the matching
        associative table.

      * Second level: Associative table with as keys the CPU/GPU architecture
        string and as value the parent GPU/architecture string, or `nil` if it is
        the top (= most generic) architecture.

  * `map_os_long_to_short`: Map long names of the OS to their short equivalent
    (name does not include the version).

  * `map_cpu_long_to_short`: Map the long CPU name to their short equivalent.

  * `map_accel_long_to_short`: Map the accelerator architecture from their long
    name to their short equivalent.

Routines:

  * Discover the architecture hierarchy

      * `get_long_osarchs`: For a given OS (long name + version) and architecture
        (long name, CPU + optionally accelerator), return a table which also includes
        the parent and potentially grandparent of the architecture for the given OS.

        The order in the table is from the least generic architecture to the most
        generic one.

      * `get_long_osarchs_reverse`: Same as `get_long_osarchs`, but now with the
        most generic one first and least generic one (the one used as the argument
        of the function) last.

  * Mapping between different formats of names

      * `map_long_to_short`: Map full long name (OS+version-CPU-accelerator) to the
        equivalent short name. It also works for names that do not include the
        accelerator.

      * `map_short_to_long`: Map full short name (OS+version-CPU-accelerator) to the
        equivalent long name. It also works for names that do not include the
        accelerator.

  * Computing directories

      * `get_system_module_dir`: Compute the module directory from the three input arguments:
        long os-and-architecture name, stack name and stack version.

        The directory name returned is relative from the installation root.
