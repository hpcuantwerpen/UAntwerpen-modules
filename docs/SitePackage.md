# The SitePackage.lua file and its included routines

  * `SitePackage_map_toolchain.lua` : Mapping regular toolchain names onto yyy.mm for
    comparisons to find matching versions of some files.

  * `SitePackage_arch_hierarchy.lua` : Routines to work with the hierarchy of
    architectures and map between long and short names.

  * `SitePackage_system_info.lua`: Routines to gather information about the system.

  * `SitePackage_helper.lua`: Other routines and data structures.

Some of the data structures, in particular those that need to be extended with each
new toolchain and really define the setup of the system, are not in the LMOD subdirectory
but instead in the file `etc/SystemDefinition.lua`.


## Naming conventions

-   Full 3-component architecture: `osarch` (where possible)
-   Full 2-component architecture without OS: `arch` (where possible)
-   Supported OS as name + version: `os` 
-   2-component architecture (CPU + accelerator): `modarch`

Note that we discussed a 2-level scheme where we always use the shortest name possible
(hence avoiding `-noaccel`) but this is not implemented as we feel it may create confusion
and as it also complicates the implementation.


## etc/SystemDefinition.lua

**TODO: Some clean-up. Some of these tables could be generated automatically in `SitePackage_helper.lua`?**

### `ClusterMod_NodeTypes`

ClusterMod_NodeTypes is simply n array of nodes in the system, specified using
the long os-CPU-accelerator names.

As this is a description of the current hardware in the cluster, it is not
for a specific version of the software stack. The table is used to produce
output for debug purposes of this configuration file, e.g., to list which
software stacks for which architectures will be available on which node 
types.

Note that one should distinguish between the generic processor types and 
the real processor types. No node type in the table below should have a 
generic processor type in its name as that would cause problems with 
the 3-level software architecture schemes (and make coding more difficult even for the
2-level software architecture scheme).

Example: At the time of writing, the CalcUA cluster description would have been:
```lua
ClusterMod_NodeTypes = {
    'redhat7-ivybridge-noaccel',
    'redhat7-broadwell-noaccel',
    'redhat8-broadwell-noaccel',
    'redhat8-broadwell-pascal',
    'redhat8-broadwell-P5000',
    'redhat8-skylake-noaccel',
    'redhat8-skylake-aurora1',
    'redhat8-zen2-noaccel',
    'redhat8-zen2-ampere',
    'redhat8-zen2-arcturus',
}
```

### `ClusterMod_SystemTable`

`ClusterMod_SystemTable` defines the whole structure of the software tree, including the manually
installed software and system-wide EasyBuild managed software. Note that the table will be
completed automatically with more generic os-cpu-accelerator architecture strings based
on the other tables in this file.

All names used should be for the 3L scheme. However, the middle level should not be used 
for versions that will use a 2L_long naming scheme.

```lua
ClusterMod_SystemTable = {
    ['system'] = {
        ['redhat7'] = {
            'x86_64',
        },
        ['redhat8'] = {
            'x86_64',
        },
    },
    ['manual'] = {
        ['redhat7'] = {
            'x86_64',
        },
        ['redhat8'] = {
            'x86_64',
        },
    },
    ['2020a'] = {
        ['redhat7'] = {
            'ivybridge-noaccel',
            'broadwell-noaccel',
        },
        ['redhat8'] = {
            'zen2-noaccel',
            'skylake-noaccel',
        }
    },
    ['2021b'] = {
        ['redhat7'] = {
            'ivybridge-noaccel',
        },
        ['redhat8'] = {
            'broadwell-noaccel',
            'zen2-noaccel',
            'skylake-noaccel',
        }
    },
}
```
The structure is a table of tables.

-   The keys on the first level are the versions of the software stacks, with two special version:
    `system` and `manual`.
-   The keys on the second level are the long OS versions (name+version as used in the 
    architecture identifiers)
-   The values are then the CPU architecture + accelerator for each software stack + OS combo.
    Only the most specific architecture needs to be given, the others are derived automatically
    from other tables.


### `ClusterMod_SystemProperies`

`ClusterMod_SystemProperies` adds additional information for each partition that is not contained
in `ClusterMod_SystemTable`. It is a table of tables, the first index is the name of the calcua
stack or `manual` for the pseudo-stack of manually installed software. The table for each
software stack has the following entries:

-   `EasyBuild`: Default version of EasyBuild for this stack. Should not be defined for the
    manual stack.

-   `hierarchy`: Type of architecture hierarchy used for this software stack. Currently only 
    the first option is implemented:

    1.  `2L`: two levels, the least generic level always includes an accelerator field

    2.  `3L`: 3 levels in the architecture hierarchy.


### `ClusterMod_ClusterMap`

`ClusterMod_ClusterMap` contains for each version of the calcua toolchains, including
the dummy system version, a mapping from cluster names to os-architecture strings.
Each should be the topmost supported architecture for a particular node type.


```lua
ClusterMod_ClusterMap = {
    ['system'] = {
        ['hopper'] =      'redhat7-x86_64',
        ['leibniz'] =     'redhat8-x86_64',
        ['leibniz-skl'] = 'redhat8-x86_64',
        ['vaughan'] =     'redhat8-x86_64',
    },
    ['2020a'] = {
        ['hopper'] =      'redhat7-ivybridge-noaccel',
        ['leibniz'] =     'redhat7-broadwell-noaccel',
        ['leibniz-skl'] = 'redhat8-skylake-noaccel',
        ['vaughan'] =     'redhat8-zen2-noaccel',
    },
    ['2021b'] = {
        ['hopper'] =      'redhat7-ivybridge-noaccel',
        ['leibniz'] =     'redhat8-broadwell-noaccel',
        ['leibniz-skl'] = 'redhat8-skylake-noaccel',
        ['vaughan'] =     'redhat8-zen2-noaccel',
    },
}
```

`ClusterMod_ClusterMap` is an associative table-of-tables. 

-   On the first level, the keys are the various versions of the software stack visible to
    users (and can include `system`)
-   On the second level, the keys are the names of the clusters that we want to map on a 
    particular architecture.
-   The values are then the architecture strings, in the formats specified in 
    `ClusterMod_SystemProperties`.


### `ClusterMod_toolchain_map`

`ClusterMod_toolchain_map` is an associative table, with the yyyy[a|b] toolchains as the keys and
the matching yyyymm value as the value (note: no dot, not yyyy.mm)

Example:
```lua
ClusterMod_toolchain_map = {
    ['system'] = '200000',
    ['manual'] = '200000',
    ['2020a']  = '202001',
    ['2020b']  = '202007',
    ['2021a']  = '202101',
    ['2021b']  = '202107',
    ['2022a']  = '202201',
}
```


### `ClusterMod_map_arch_hierarchy`

`ClusterMod_map_arch_hierarchy` is an associative table of associative tables with for each supported
OS a table that can be used to determine the parent of every CPU/accelerator
architecture.

-   First level: The keys are the yyyymm versions of toolchains, the values the matching
    associative table. These toolchain versions are "starting from", so not every toolchain
    needs to be specified.

-   Second level: Associative table with as keys the CPU/GPU architecture
    string and as value the parent GPU/architecture string, or `nil` if it is
    the top (= most generic) architecture.

Example:
```lua
ClusterMod_map_arch_hierarchy = {
    -- We start with a 2-level map
    ['200000'] = {
        ['zen2-noaccel']      = 'x86_64',
        ['zen2-ampere']       = 'x86_64',
        ['zen2-arcturus']     = 'x86_64',
        ['broadwell-noaccel'] = 'x86_64',
        ['broadwell-P5000']   = 'x86_64',
        ['broadwell-pascal']  = 'x86_64',
        ['skylake-noaccel']   = 'x86_64',
        ['skylake-aurora1']   = 'x86_64',
        ['ivybridge-noaccel'] = 'x86_64',
        ['x86_64']            = nil,
    }
}
```

TODO: Can we get rid of the above data structure?


### `ClusterMod_def_cpu`

`ClusterMod_def_cpu` is an associative table of associative tables defining
the  CPU architectures and whether they are generic or not.

-   First level: The keys are the yyyymm versions of toolchains, the values the matching
    associative table. These toolchain versions are "starting from", so not every toolchain
    needs to be specified.

-   Second level: Associative table with as keys the CPU type (long names) and as value
    `true` for generic CPU architectures and false otherwise.

The map is versioned, but do expect problems with finding the
right version of the system stack for a regular stack if all of a
sudden a regular CPU would become generic or vice-versa, so in 
practice it is very likely only one version will ever be needed
as it can be safely extended with new types.

Example:
```lua
ClusterMod_def_cpu = {
    ['zen4']      = false,
    ['zen3']      = false,
    ['zen2']      = false,
    ['skylake']   = false,
    ['broadwell'] = false,
    ['ivybridge'] = false,
    ['x86_64']    = true,
}
```
 
### `ClusterMod_map_cpu_to_gen`

`ClusterMod_map_cpu_to_gen` is an associative table of associative tables with for each supported
OS a table that can be used to determine the generic architecture for every CPU.

-   First level: The keys are the yyyymm versions of toolchains, the values the matching
    associative table. These toolchain versions are "starting from", so not every toolchain
    needs to be specified.

-   Second level: Associative table with as keys the CPU names and as the value
    the generic CPU type for this CPU, or nil if it is already a generic one.

Example:
```lua
ClusterMod_map_cpu_to_gen = {
    ['200000'] = {
        ['zen3']      = 'x86_64',
        ['zen2']      = 'x86_64',
        ['skylake']   = 'x86_64',
        ['broadwell'] = 'x86_64',
        ['ivybridge'] = 'x86_64',
        ['x86_64']    = nil,
    }
}
```


### `ClusterMod_reduce_cpu`

`ClusterMod_reduce_cpu` is an associative table of associative tables with for each supported
OS a table that can be used to determine a compatible but less capable version of the CPU,
until we end at the generic architectures. If the key is a generic architecture, the value
also has to be a generic architecture, or 'nil' if the tree/chain of architectures ends 
there.

-   First level: The keys are the yyyymm versions of toolchains, the values the matching
    associative table. These toolchain versions are "starting from", so not every toolchain
    needs to be specified.

-   Second level: Associative table with as keys the CPU names and as the value
    the next compatible but less capable architecture, i.e., all software for the
    CPU as value should also run on the CPU as key but not always the other way
    around.

For each stack in ClusterMod_SystemTable, these reduction rules have to be compatible
with the matching ones in ClusterMod_reduce_top_arch. I.e., if somehow
CPU1-Accel1 in ClusterMod_reduce_top_arch reduces to CPU2-Accel2 then it must 
also be possible to reduce CPU1 to CPU2 (in one or more steps) using the
rules specified in the `ClusterMod_reduce_top_arch` table below.

Example:
```lua
ClusterMod_reduce_cpu = {
    ['200000'] = {
        ['zen3']      = 'zen2',
        ['zen2']      = 'broadwell',
        ['broadwell'] = 'ivybridge',
        ['ivybridge'] = 'x86_64',
        ['x86_64']    = nil,
    },
}
```


### `ClusterMod_reduce_top_arch`

`ClusterMod_reduce_top_arch` is an associative table of associative tables with for each supported
OS a table that can be used to walk a chain of compatible but less specific architectures when 
looking for an architecture that is supported for a particular version of a software stack.

As we forsee that this may change in incompatible ways in the future, there is a level that indexes
with a yyyymm starting version of the software stacks.

-   First level: The keys are the yyyymm versions of software stacks, the values the matching
    associative table. These toolchain versions are "starting from", so not every toolchain
    needs to be specified.

-   Second level: Associative table with as keys the parten CPU/GPU architecture
    string and as value the child-GPU/architecture string or sub-architecture, 
    or `nil` if it is the top (= most generic) architecture.


Example:
```lua
ClusterMod_reduce_top_arch = {
    ['200000'] = {
        ['zen2-ampere']       = 'zen2-noaccel',
        ['zen2-arcturus']     = 'zen2-noaccel',
        ['zen2-noaccel']      = 'broadwell-noaccel',
        ['skylake-aurora1']   = 'skylake-noaccel',
        ['skylake-noaccel']   = 'broadwell-noaccel',
        ['broadwell-noaccel'] = 'ivybridge-noaccel',
        ['broadwell-P5000']   = 'broadwell-noaccel',
        ['broadwell-pascal']  = 'broadwell-noaccel',
        ['ivybridge-noaccel'] = 'x86_64',
        ['x86_64']            = nil,
    },
}
```


## SitePackage_map_toolchain.lua

### Data structures

-   Uses `ClusterMod_toolchain_map` from `etc/SystemDefinition.lua`

### Routines

-   `map_toolchain`:  Returns the matching yyyymm toolchain for any toolchain. The
    input argument can be either a yyyy.mm toolchain version (in which case the
    routine simply returns that version without the dot) or a yyyy[a|b] version in
    which case the routine uses the `ClusterMod_toolchain_map` to compute the matching
    yyyymm version or falls back to a default rule (where a becomes 01 and b becomes
    07).
    
-   `get_versionedfile`: Finds the most recent file (in terms of version encoded in the
    name of the file) with version not older than a
    given toolchain, with the file matching a particular pattern given as a directory,
    part before the version and part after the version. The version can be in any
    format supported by `map_toolchain`: yyyy[a|b], yyyy.mm, yyyymm, `system`.


## SitePackage_arch_hierarchy.lua

### Data structures

#### From other files

-   Uses `ClusterMod_map_arch_hierarchy` from `etc/SystemDefinition.lua`.


#### `map_os_long_to_short`

`map_os_long_to_short` maps long names of the OS to their short equivalent
(name does not include the version).

Example:
```lua
map_os_long_to_short = {
    ['redhat'] = 'RH',
}
```

#### `map_cpu_long_to_short`

`map_cpu_long_to_short` maps the long CPU name to their short equivalent.

Example:
``` lua
map_cpu_long_to_short = {
    ['x86_64']    = 'x86_64',
    ['zen3']      = 'zen3',
    ['zen2']      = 'zen2',
    ['ivybridge'] = 'IVB',
    ['broadwell'] = 'BRW',
    ['skylake']   = 'SKLX',
}
```

#### `map_accel_long_to_short`

`map_accel_long_to_short` maps the accelerator architecture from their long
name to their short equivalent.

Example:
```lua
map_accel_long_to_short = {
    ['noaccel']  = 'host',
    ['P5000']    = 'NVGP61GL',
    ['pascal']   = 'NVCC60',
    ['ampere']   = 'NVCC80',
    ['arcturus'] = 'GFX908',
    ['aurora1']  = 'NEC1',
}
```


### Routines

#### Discover the architecture hierarchy

-   `get_long_osarchs`: For a given OS (long name + version) and architecture
    (long name, CPU + optionally accelerator), return a table which also includes
    the parent and potentially grandparent of the architecture for the given OS.

    The order in the table is from the least generic architecture to the most
    generic one.

-   `get_long_osarchs_reverse`: Same as `get_long_osarchs`, but now with the
    most generic one first and least generic one (the one used as the argument
    of the function) last.

#### Mapping between different formats of names

-   `map_long_to_short`: Map full long name (OS+version-CPU-accelerator) to the
    equivalent short name. It also works for names that do not include the
    accelerator.

-   `map_short_to_long`: Map full short name (OS+version-CPU-accelerator) to the
    equivalent long name. It also works for names that do not include the
    accelerator.

#### Extracting parts from the os-cpu-accelerator strings:

-   `extract_os`  : Extracts the first part of the os-cpu-acceleartor argument

-   `extract_cpu` : Extracts the second part of the os-cpu-accelerator argument

-   `extract_accel` : Extracts the third part of the os-cpu-accelerator argument,
    or returns `nil` if there is no accelerator part in the argument.

-   `extract_arch` : Extracts the second and (optional) third part of the
    os-cpu-accelerator argument, i.e., returns cpu-accelerator or just cpu if there
    is no accelerator part.

-   `extract_cpu_from_arch`: Extracts the first part of the cpu-accelerator argument

-   `extract_accel_from_arch`: Extracts the second part of the cpu-accelerator argument


#### Computing matching architectures in software stacks

-   `get_stack_osarch_current( stack_version )`

    **Input argument:**

    -   `stack_version`: Version of the calcua stack, can be `system`.

    **Return value:** 

    -   The architecture of the current node with long names and in a
        format compatible with the indicated software stack (so taking into 
        account the hierarchy types 2L or 3L).

-   `get_stack_generic( clusterarch, stack_version )`: Compute the most generic
    architecture for the given version of the CalcUA stack on the given clusterarch
    architecture. The clusterarch argument has to be in the long format compatible
    with the CalcUA stack version.

-   `get_stack_generic_current( stack_version )`: Compute the most generic
    architecture for the given version of the CalcUA stack on the current
    architecture.

-   `get_stack_top( long_osarch, stack_version )`:

    **Input arguments:**

    -   `long_osarch`: os and architecture with long names and in a format 
        compatible with the indicated version of the software stack (so respecting
        the hierarchy types 2L or 3L).

    -   `stack_version`: Version of the calcua stack, can be system.

    **Return value:**
    
    -   The most specific os-architecture for the current node in the indicated
        version of the CalcUA software stacks.


-   `get_stack_matchingarch( long_osarch, reduce_stack_version, stack_version )`:

    **Input arguments:**

    -   `long_osarch`: os and architecture with long names and in a format 
        compatible with the indicated version of the software stack (so respecting
        the hierarchy types 2L or 3L).

    -   `reduce_stack_version`: Stack version to use for the reduction rules of
        both os-CPU-accel and os-CPU names.

    -   `stack_version`: Version of the calcua stack, can be system for which the
        best matching architecture should be returned. If `stack_version` is a 
        3L hierarchy, this can be a middle level one if `long_osarch` is also a 
        middle level name (which implies that `reduce_stack_version` is also a
        3L hierarchy)

    **Return value:**
    
    -   The most specific os-architecture for the current node in the indicated
        version of the CalcUA software stacks.

    The precise rules for the matching are very tricky. The thing that makes this
    routine very tricky is that it will also be used in middle level arch modules 
    for 3L stacks, and that there also one must be able to find a good module in 
    the `system` stack which may be 2L or 3L.

    Cases:
    -   `long_osarch` is of type OS-generic CPU. As we currently have no rules 
        to reduce generic CPUs to an even less capable generic one, we produce
        `nil` if `long_osarch` is not supported by `stack_version` and return
        `long_osarch` otherwise.
    -   `long_osarch` is of type OS-CPU, i.e., a middle level architecture for a 
        3L hierarchy. This implies that `reduce_stack_version` must be a 3L stack.

        There are now 2 options:
        -   `stack_version` is also a 3L hierarchy: We use the reduction rules for 
            CPUs for `reduce_stack_version` to find a middle level or bottom/generic
            level supported by `stack_version`. 
        -   `stack_version` is a 2L hierarchy: We use the mapping to generic CPU 
            defined by `ClusterMod_map_cpu_to_gen` for `reduce_stackversion` to find
            the matching generic CPU and then continue using the CPU chaining
            rules defined by 

    -   `long_osarch` is of type os-generic CPU: We follow the CPU reduction path
        for `reduce_stack_version` to see if we can find a match in the generic
        architectures supported by `stack_version`.


#### Computing directories

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


#### Miscellaneous functions

-   `get_stack_subarchs( long_osarch, stack_version )`: Compute a list containing
    the given long_osarch and its subarchs in
    the hierarchy of the naming scheme for the stack. So the list can
    be at most 3 elements long. The most generic one is at the front of
    the list.

    This is a helper function to `get_system_module_dirs`.

-   `populate_cache_subarchs( stack_version )`: Populate a part of the cache variable
    `ClusterMod_cache_subarchs` initialized in `SitePackage_helper.lua` with the other 
    helper variables that are used throughout.

    For each stack version, the cache variable will return `true` for each valid 
    architecture string in the software architecture hierarchy for that stack
    version.


## SitePackage_system_info.lua

### Data structures

This file needs several data structures to map properties detected on the system to 
the actual OS, CPU and accelerator names used in the module system.

Note that in the current implementation we maintain mappings to both the long and the
short names, and this has to be consistent with the various `map_*` tables in
`SitePackage_arch_hierarchy.lua`. 

#### Mappings to long names

-   `cpustring_to_longtarget` is the mapping from the CPU string that can be found in
    `/proc/cpuinfo` to the names that are used in the module system. Several CPU strings
    can map to the same target.

    Example:
    ```lua
    local cpustring_to_longtarget = {
        AuthenticAMD_23_49 = 'zen2',
        GenuineIntel_6_62  = 'ivybridge',
        GenuineIntel_6_79  = 'broadwell',
        GenuineIntel_6_85  = 'skylake',
    }
    ```

-   `osname_to_longos` is the mapping from the OS names are reported in `/etc/os-release`
    in the `NAME` field to the names used in the module system. Multiple values can map onto
    the same OS in the stack, e.g., all Red Hat compatible OSes map to a single name.

    Example:
    ```lua
    local osname_to_longos = {
        CentOS_Linux = 'redhat',
        Rocky_Linux  = 'redhat',
    }
    ```

-   `accelerator_to_longacc` is a more tricky table. It is used in the mapping from data
    read from the output of `lspci` to accelerator names, but the keys are not currently the
    values read with `lspci`. These values are hard coded in the routine that does detect
    the accelerator.

    Example:
    ```lua
    local accelerator_to_longacc = {
        AMD_MI100    = 'arcturus',
        NVIDIA_GA100 = 'ampere',
        NVIDIA_GP100 = 'pascal',
        NVIDIA_GP104 = 'P5000',
        NEC_aurora1  = 'aurora1',
    }
    ```


#### Mappings to short names

The structure of each of these associative tables is completely equivalent to their long
names equivalent, but using the short names as the value. 

In principle they could be computed from the long names variants utilising the mapping 
tables from long to short names as defined in `SitePackage_arch_hierarchy.lua`.

-   `cpustring_to_shorttarget`
-   `osname_to_shortos`
-   `accelerator_to_shoracc`


#### Other data structures

-   `os_version_type`: Indicates if for the OS we should use the major version only or 
    a major.minor version to distinguish architectures for the software stack.

    The need grew out of a difference between CentOS which only reports the major version
    in `/etc/os-release` in the `VERSION_ID` field and Rocky Linux which reports a major.minor
    version, while we still use only the major version in the software stack.

    Example
    ```lua
    local os_version_type = {
        CentOS_Linux = 'major',
        Rocky_Linux  = 'major',
    }
    ```


### Routines


#### `get_hostname()`

Request the name of the host. The routine calls `/bin/hostname`.

#### `get_cpu_info()`

Returns the CPU string derived from the data in `/proc/cpuinfo`, by combining 
information from the `vendor_id`, `family` and `model` lines (separated by an
underscore).


#### `get_os_info()`

returns 2 values: name and version of the OS. The name is extracted
from the `NAME` line of `/etc/os-release`, the version from the `VERSION_ID` line
but it may be converted from major.minor to major format if told so by the 
`os_version_type` table.


#### `get_accelerator_info` 

Extracts the accelerator type, returning `nil` if no accelerator
is found. The names returned are the long accelerator names used in the data structures.

Current return value:

-   AMD_MI100    (vaughan AMD Instinct nodes)
-   NVIDIA_GP100 (leibniz Pascal nodes)
-   NVIDIA_GP104 (leibniz visualization node)
-   NVIDIA_GA100 (vaughan Ampere node)
-   NEC_aurora1  (leibniz Aurora node)


#### `get_cluster_longosarch()`

`get_clusterarch_longosarch` returns the cluster architecture in the os-cpu-accelerator
format with long names, e.g., `redhat8-zen2-noaccel` or `redhat8-skylake-aurora1`.
This is the format that in our naming conventions would be denoted as
`long_osarch`.


#### `get_clusterarch()`

**This function may not be needed in the final implementation and may be eliminated
in favor of `get_cluster_longosarch()`.**

`get_clusterarch` returns the cluster architecture in four possible formats for the 
module system. It is then to the module system to select which one of the four it needs
for which purpose (and that depends on the `hierarchy` field in `ClusterMod_SystemProperties`
in `/etc/SysteDefinition.lua`). The four formats are two with long names and two with
short names, each time with three components or with only two components if there is no
accelerator.

Return values:

1.  Short minimal name, i.e., no `-host` is added for nodes without
    accelerator.
2.  Long minimal name, i.e., no `-noaccel` is added for nodes without
    accelerator.
3.  Short maximal name, with `-host` added for nodes without accelerator.
    This is the format that in our naming conventions would be denoted as
    `short_osarch`.
4.  Long maximal name, with `-noaccel` added for nodes without accelerator
   
e.g., `RH8-zen2, redhat8-zen2, RH8-zen2-host, redhat8-zen2-noaccel` or
`RH8-SKLX-NEC1, redhat8-skylake-aurora1, RH8-SKLX-NEC1, redhat8-skylake-aurora1`.
This is the format that in our naming conventions would be denoted as
`long_osarch`.


#### `get_fullos()`

Returns the long OS name including the version (so the first component
of the formats with long names of `get_clusterarch`)

Example return value: `redhat8` on systems with CentOS 8.x or Rocky Linux 8.x.


## SitePackage_helper.lua

This file defines data structures derived from other data structures mentioned earlier
on this page, which implies that the order of `dofile` commands is important as the 
initialisation code is executed when the file is included.


### Data structures

#### `ClusterMod_sorted_archmap_keys`

This data structure is a sorted list of the level 1 keys used in the 
[`ClusterMod_map_arch_hierarchy`](#ClusterMod_map_arch_hierarchy) data structure.
Its main purpose is to speed up a search routine in this file, to avoid always 
recomputing that data.

TODO: GET RID OF THIS STRUCTURE


#### `ClusterMod_sorted_cputogen_keys`

This data structure is a sorted list of the level 1 keys used in the 
[`ClusterMod_map_cpu_to_gen`](#ClusterMod_map_cpu_to_gen) data structure.
Its main purpose is to speed up a search routine in this file, to avoid always 
recomputing that data.


#### `ClusterMod_sorted_toparchreduction_keys`

This data structure is a sorted list of the level 1 keys used in the 
[`ClusterMod_reduce_top_arch`](#ClusterMod_reduce_top_arch) data structure.
Its main purpose is to speed up a search routine in this file, to avoid always 
recomputing that data.


### Routines

-   `get_matching_archmap_key( version )`: For a given numeric (i.e., yyyymm) version, returns
    the largest key in `ClusterMod_map_arch_hierarchy` not larger than the given version.

-   `get_matching_defcpu_key( version )`: For a given numeric (i.e., yyyymm) version, returns
    the largest key in `ClusterMod_map_def_cpu` not larger than the given version.

-   `get_matching_cputogen_key( version )`: For a given numeric (i.e., yyyymm) version, returns
    the largest key in `ClusterMod_map_cpu_to_gen` not larger than the given version.

-   `get_matching_reducecpu_key( version )`: For a given numeric (i.e., yyyymm) version, returns
    the largest key in `ClusterMod_reduce_cpu` not larger than the given version.

-   `get_matching_toparchreduction_key( version )`: For a given numeric (i.e., yyyymm) version, returns
    the largest key in `ClusterMod_reduce_top_arch` not larger than the given version.

-   `is_Stack_SystemTable`: Check if a given stack version corresponds to a key in
    `ClusterMod_SystemTable`. We have to do this through a function that is then exported
    to the sandbox as module files do not have access to the data itself.

    The main purpose of this function is simply to give more precise error messages
    in case the data structures aren't updated properly after installing a new toolchain.
    This problem should not occur as the routines to prepare the stack would fail themselves,
    but you'll never know.

-   `mkDir`: Create a directory, using the Lua `lfs` package. It really has the effect
    effect of `mkdir -p`, so it can create multiple levels from the given directory if
    needed.

-   'get_user_prefix_EasyBuild': Compute the directory for the EasyBuild user installation,
    or nil if that is explicitly turned off by setting `EBU_USER_PREFIX` to an empty string.
