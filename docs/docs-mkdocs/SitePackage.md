# The SitePackage.lua file and its included routines

  * SitePackage_map_toolchain.lua : Mapping regular toolchain names onto yyy.mm for
    comparisons to find matching versions of some files.

  * SitePackage_arch_hierarchy.lua : Routines to work with the hierarchy of
    architectures and map between long and short names.

Some of the data structures, in particular those that need to be extended with each
new toolchain and really define the setup of the system, are not in the LMOD subdirectory
but instead in the file `etc/SystemDefinition.lua`.


## etc/SystemDefinition.lua

### `CalcUA_SystemTable`

`CalcUA_SystemTable` defines the whole structure of the software tree, including the manually
installed software and system-wide EasyBuild managed software. Note that the table will be
completed automatically with more generic os-cpu-accelerator architecture strings based
on the other tables in this file.

```lua
CalcUA_SystemTable = {
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


### `CalcUA_SystemProperies`

`CalcUA_SystemProperies` adds additional information for each partition that is not contained
in `CalcUA_SystemTable`. It is a table of tables, the first index is the name of the calcua
stack or `manual` for the pseudo-stack of manually installed software. The table for each
software stack has the following entries:

-   `EasyBuild`: Default version of EasyBuild for this stack. Should not be defined for the
    manual stack.

-   `hierarchy`: Type of architecture hierarchy used for this software stack. Currently only 
    the first option is implemented:

    1.  `2L_long`: two levels, the least generic level always includes an accelerator field

    2.  `2L_short`: two levels, but the least generic level does not include an accelerator
        field if there is no accelerator

    3. `3L`: 3 levels in the architecture hierarchy.


### `CalcUA_ClusterMap`

`CalcUA_ClusterMap` contains for each version of the calcua toolchains, including
the dymmy system version, a mapping from cluster names to os-architecture strings.

```lua
CalcUA_ClusterMap = {
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

`CalcUA_ClusterMap` is an associative table-of-tables. 

-   On the first level, the keys are the various versions of the software stack visible to
    users (and can include `system`)
-   On the second level, the keys are the names of the clusters that we want to map on a 
    particular architecture.
-   The values are then the architecture strings, in the formats specified in 
    `CalcUA_SystemProperties`.


### `CalcUA_toolchain_map`

`CalcUA_toolchain_map` is an associative table, with the yyyy[a|b] toolchains as the keys and
the matching yyyymm value as the value (note: no dot, not yyyy.mm)

Example:
```lua
CalcUA_toolchain_map = {
    ['system'] = '200000',
    ['manual'] = '200000',
    ['2020a']  = '202001',
    ['2020b']  = '202007',
    ['2021a']  = '202101',
    ['2021b']  = '202107',
    ['2022a']  = '202201',
}
```

### `CalcUA_map_arch_hierarchy`

`CalcUA_map_arch_hierarchy` is an associative table of associative tables with for each supported
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
CalcUA_map_arch_hierarchy = {
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

## SitePackage_map_toolchain.lua

### Data structures

-   Uses `CalcUA_toolchain_map` from `etc/SystemDefinition.lua`

### Routines

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

### Data structures

-   Uses `CalcUA_map_arch_hierarchy` from `etc/SystemDefinition.lua`.


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

-   `accelerator_to_shortacc` is a more tricky table. It is used in the mapping from data
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

-   `get_hostname`: Request the name of the host. The routine calls `/bin/hostname`.

-   `get_cpu_info`: Returns the CPU string read from `/proc/cpuinfo`, by combining 
    information from the `vendor_id`, `family` and `model` lines (separated by an
    underscore).

-   `get_os_info` returns 2 values: name and version of the OS. The name is extracted
    from the `NAME` line of `/etc/os-release`, the version from the `VERSION_ID` line
    but it may be converted from major.minor to major format if told so by the 
    `os_version_type` table.

-   `get_accelerator_info` extracts the accelerator type, returning `nil` if no accelerator
    is found. The names returned are the long accelerator names used in the data structures.

-   `get_clusterarch` returns the cluster architecture in four possible formats for the 
    module system. It is then to the module system to select which one of the four it needs
    for which purpose (and that depends on the `hierarchy` field in `CalcUA_SystemProperties`
    in `/etc/SysteDefinition.lua`). The four formats are two with long names and two with
    short names, each time with three components or with only two components if there is no
    accelerator.

-   `get_fullos`: Returns the long OS name including the version (so the first component
    of the formats with long names of `get_clusterarch`)

    Example return value: `redhat8` on systems with CentOS 8.x or Rocky Linux 8.x.


## SitePackage_helper.lua

This file defines data structures derived from other data structures mentioned earlier
on this page, which implies that the order of `dofile` commands is important as the 
initialisation code is executed when the file is included.


### Data structures

#### `CalcUA_sorted_archmap_keys`

This data structure is a sorted list of the level 1 keys used in the 
[`CalcUA_map_arch_hierarchy`](#calcua_map_arch_hierarchy) data structure.
Its main purpose is to speed up a search routine in this file, to avoid always 
recomputing that data.

### Routines

-   `get_matching_archmap_key`: For a given numeric (i.e., yyyymm) version, returns
    the largest key in `CalcUA_map_arch_hierarchy` not larger than the given version.

-   `mkDir`: Create a directory, using the Lua `lfs` package. It really has the effect
    effect of `mkdir -p`, so it can create multiple levels from the given directory if
    needed.
