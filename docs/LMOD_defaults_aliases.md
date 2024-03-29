# LMOD defaults and aliases

## Aliases for the clusterarch modules

There are two ways to define more user-friendly names for the clusterarch `arch`
modules:

1.  Use `module_alias` statements in a modulerc file, e.g.,

    ```lua
    module_alias('cluster/vaughan', 'arch/redhat8-zen2-noaccel')
    ```

    These will then show in a separate section of the `module avail` overview.

2.  Use `module_version` statements in a modulerc file, e.g.,

    ```lua
    module_version('arch/redhat8-zen2-noaccel', 'vaughan')
    ```

    These will be shown as attributes for the corresponding `arch` module in the
    `module avail` overview.

We want these alternative names to be separately defined for each software stack.
The reasoning behind this is that for a special section of the cluster, e.g., a 
section with GPU accelerators, we may not have a separate architecture in one 
version of the software stack while we may have in the other, so we want the synonym
to refer to different `arch` modules dependent on the software stack. 

There are again several ways to realise this that fit into the directory structure

1.  We can define an additional `mgmt/LMOD` subdirectory and store a separate
    modulerc file for each software stack in that directory. That file is then
    added to the `LMOD_MODULERCFILE` PATH-style variable with the 
    list of modulerc files that should be used.

2.  The definitions can be put in a `.modulercz` file in the 
    `modules-infrastructure/arch/calcua/yyyyx/arch` subdirectory.

We have chosen for the **second option**.

The `modulerc` file is generated by the `prepare_ClusterMod.sh` script based on
information contained in the `ClusterMod_ClusterMap` variable of the system 
definition file, and is also re-generated during a repair run, so the file should
not be hand-edited.

