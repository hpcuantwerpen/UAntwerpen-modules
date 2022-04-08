# The generic calcua and clusterarch modules

The calcua and clusterarch modules work together to load a version of the
software stack for the right architecture. Moreover they ensure that the
EasyBuild-config module can recover all the information it needs to install
software in the right directories.

The calcua module is loaded first. This module sets the version of the software
stack. The version of the software stack is of the form year followed by the letter
a or b.

**TODO**: Think about support for yyyy.mm also as this is used during the development
of new toolchains in EasyBuild itself, and also for EESSI.

The calcua modules will automatically load the best fitting clusterarch module
for the node on which the module is loaded. However, it is always possible to
overwrite that option later on.

Instances of the generic clusterarch module come in two shapes:
-   cluster/<name> or cluster/<name>-<OS> or cluster/<name>-<target> or
    cluster/<name>-<OS>-<target> or any other special designator: This is because
    users will typically be more familiar with the name of the cluster than with
    the CPU architecture. The mapping to CPU architecture is coded internally.
-   arch/<target> or arch/<OS>-<target>: This is a direct mapping
    to the underlying directory structure.
The <target> and <OS> fields correspond to what would be used in Spack,
with the exception that we use skylake instead of skylake_avx512.


## The calcua generic module

What the module does:

-   Declare itself a sticky module from the family `CalcUA_SoftwareStack`.
-   Determine its name and version from the module name and version
-   Determine the architecture of the node on which it is executing taking
    into account the architectures supported byt the current version of
    the calcua stack.
    -   Determine the architecture of the node
    -   Then look for the best match for the software stack that is being
        loaded.
-   Enable loading of the architecture modules supported by the specific
    version of the software stack.
-   Load the most suitable clusterarch module


## The clusterarch generic module

In the current implementation we only support architecture strings as the version of the module.
Instead we use a `.modulerc.lua` file in the the `arch` module subdirectory for each software
stack to define synonyms based on the cluster names. This file is prepared as one of the steps
in the `prepare_calcua_stack.lua` script.

What the module does:

-   Declare itself a sticky module from the family `CalcUA_clusterarch`.
-   TO BE IMPLEMENTED!
-   Determine suitable architecture strings:
    -   Highest-level architecture string for the current version of the software stack is
        determined from the version of the module.
    -   When we are not loading for the `system` version of the software stack, we also need
        to determine the highest level version of that stack that should be loaded.
-   Check if a user software stack is also available.
-   Determine the list of directories of EasyBuild-generated module files to load. Keep in mind
    that later on we will have to synchronise that with a list of directories in the EasyBuild
    installation repository. All user modules take a higher priority than any 
    EasyBuild-generated module.
-   Determine the infrastructure module directory to load.
-   
    There are no user versions of infrastructure modules.
-   FUTURE EXTENSION: Determine the manually generated modules directory/is to load.
    
    We may provide a placeholder for user-build manual modules also
-   Generate `prepend_path` statements in reverse order  
    -   So first for the system modules, in the order
        -   Manual (when implemented)
        -   Infrastructure
        -   `system` dummy stack from generic to specific
        -   Stack version from generic to specific
    -   Then for the user modules
        -   Manual (when implemented)
        -   `system` dummy stack from generic to specific
        -   Stack version from generic to specific



## Naming the cluster architecture (clusterarch)


### Preliminary notes

The lists below are very complete lists, and certainly at the moment we do
no have a separate software stack for them and some clusterarchs will be mapped
on others (e.g., no specific stacks on the GPU nodes) but this may be revised
over time.

Depending on where they are used, there are long and short names.

Each name consists of three components:

1.  Operating system + version
2.  CPU architecture
3.  (Optional) the accelerator, where we also have a term for no accelerator.
   
The thre components are spearated by dashes.

Note for the long names:

-   The CPU target is based on the target that spack would report (or for that
    reason the archspec tool), except that we use skylake instead of
    skylake_avx512 and don't distinguish with Cascade Lake as that is just
    a different stepping fo the same CPU family and model.
-   The OS name is also based on what spack would report

In doing so, we hopefully ensure that the stack is future-proof and will
use similar naming as what would be used in Spack or in EESSI, as that also
follows these conventions for CPU targets. For the accelerators we've chosen
user-friendly names rather than their technical names.

Note for the short names:

-   For the AMD processors we simply refer to the zen name as that is
    already a very short name.
-   For the Intel processors we use established abbreviations: IVB for
    Ivy Bridge, BRW for Broadwell and SKLX for Skylake (in fact, the more
    often used abbreviation for Skylake with AVX512 is SKL-X but we want
    to avoid dashes in the name).
-   For the AMD GPUs we refer to their internal GFX code which is often
    used in architecture strings for compilers with OpenMP offload.
-   For NVIDIA GPUs we refer to their Compute Capability as that is
    a parameter that needs to be set when compiling. Furthermore we add "GL"
    to the string if it is a GPU for OpenGL visualisation. Hence:
    -   The Ampere A100 becomes NVCC80 as it has compute capability 8.0.
    -   The Tesla P100 becomes NVCC60 as it has compute capability 6.0.
    -   The Quadro P5000 which is based on the GP104 chip becomes
        NVCC61GL as it has compute capability 6.1 and is also meant for
        visualisation with OpenGL.


### OS names

Currently supported for the OS component of the name:

| long    | short | What?                   |
|:--------|:------|:------------------------|
| redhat7 | RH7   | Red Hat 7-compatible OS |
| redhat8 | RH8   | Red Hat 8-compatible OS |

These names are defined in `SitePAckage_arch_hierarchy.lua`.

### CPU names

Currently supported for the CPU component of the name:

| long      | short  | What?                                     |
|:----------|:-------|:------------------------------------------|
| ivybridge | IVB    | Intel Ivy Bridge generation (E5-XXXX v2)  |
| broadwell | BRW    | Intel Broadwell generation (E5-XXXX v4)   |
| skylake   | SKLX   | Intel Skylake and Cascadelake server CPUs |
| zen2      | zen2   | AMD Zen2 generation                       |
| x86_64    | x86_64 | Generic x86 64-bit CPU                    |

These names are defined in `SitePAckage_arch_hierarchy.lua`.


### Accelerator names

Here the short name isn't always shorter, but tells more about the
architecture. at least for the GPU accelerators.

| long     | short    | What?                           |
|:---------|:---------|:--------------------------------|
| noaccel  | host     | No accelerator in the node      |
| ampere   | NVCC80   | NVIDIA A100                     |
| pascal   | NVCC60   | NVIDIA P100                     |
| P5000    | NVGP61GL | NVIDIA P5000 visualisation node |
| arcturus | GFX908   | AMD MI100                       |
| aurora1  | NEC1     | NEC Aurora 1st gen vector board |

These names are defined in `SitePAckage_arch_hierarchy.lua`.


### Cluster architecture strings

These combinations that are supported for each software stack version are defined in
`etc/SystemDefinition.lua`.

| long                      | short            |
|:--------------------------|:-----------------|
| redhat8-x86_64            | RH8-x86_64       |
| redhat8-zen2              | RH8-zen2         |
| redhat8-zen2-noaccel      | RH8-zen2-host    |
| redhat8-zen2-ampere       | RH8-zen2-NVCC80  |
| redhat8-zen2-arcturus     | RH8-zen2-GFX908  |
| redhat8-broadwell         | RH8-BRW          |
| redhat8-broadwell-noaccel | RH8-BRW-host     |
| redhat8-broadwell-P5000   | RH8-BRW-NVGP61GL |
| redhat8-broadwell-pascal  | RH8-BRW-NVCC60   |
| redhat8-ivybridge         | RH8-IVB          |
| redhat8-skylake           | RH8-SKLX         |
| redhat8-skylake-noaccel   | RH8-SKLX-host    |
| redhat8-skylake-aurora1   | RH8-SKLX-NEC1    |


### Possible names for arch modules based on the cluster name

-   arch/hopper = arch/redhat8-ivybridge

-   arch/leibniz = arch/redhat8-broadwell or arch/redhat8-broadwell-noaccel (depending
    on choices discussed further down)

-   arch/leibniz-viz = arch/redhat8-broadwell-P5000

-   arch/leibniz-nvidia = arch/redhat8-broadwell-pascal

-   arch/vaughan = arch/redhat8-zen2 or arch/cents8-rome-noaccel

-   arch/vaughn-amd = arch/redhat8-zen2-arcturus

-   arch/vaughan-nvidia = arch/redhat8-zen2-ampere

-   arch/biomina = arch/redhat8-skylake or arch/redhat8-skylake-noaccel depending
    on choices discussed further down

-   arch/aurora = arch/redhat8-skylake-aurora1

There is a mapping per software stack version defined in
`etc/SystemDefinition.lua`.


## Determining the architecture string

There are three options to determine the architecture string:

1.  Based on the name of the node
2.  Based on VSC_ environment variables
3.  Determine by reading some OS files and pseudo-files

### Based on names

It is difficult to get hostname and domain in one. `hostname -f` does not have the
desired effect on vaughan. One workaround is to use

```bash
host $(hostname -i) | awk '{print $NF }'
```

Results:

| Node type                  | `host $(hostname -i) \| awk '{print $NF }'` |
|:---------------------------|:--------------------------------------------|
| login node vaughan         | lnX.vaughan.antwerpen.vsc                   |
| compute node vaughan       | rXcYYcnZ.vaughan.antwerpen.vsc              |
| NVIDIA node vaughan        | nvam1.vaughan.antwerpen.vsc                 |
| MI100 node vaughan         | amdarcX.vaughan.antwerpen.vsc               |
| login node leibniz         | lnX.leibniz.antwerpen.vsc                   |
| visualisation node leibniz | vizX.leibniz.antwerpen.vsc                  |
| compute node leibniz       | rXcYYcnZ.leibniz.antwerpen.vsc              |
| compute node hopper        | rXcYYcnZ.hopper.antwerpen.vsc               |
| Pascal node leibniz        | paX.leibniz.antwerpen.vsc                   |
| Aurora node leibniz        | aurora.leibniz.antwerpen.vsc                |
| Biomina node leibniz       | r0c03cZ.leibniz.antwerpen.vsc               |

TODO: Is this still valid after the upgrade? No!


### Based on VSC_ variables

-   Variables:

    -   VSC_ARCH_LOCAL: Currently ivybridge, broadwell or rome.

        -   The BioMina node also returns VSC_ARCH_LOCAL=broadwell...

        -   What about the aurora node?

    -   VSC_OS_LOCAL: centos7 or redhat8

-   It is not possible to detect the accelerator type


### Reading information in /proc etc.

-   Get the CPU type:

    ```bash
    cat /proc/cpuinfo | grep -m 1 "model name"  | cut -d : -f 2
    ```

    The only problem with this one is that it will still have a leading space but that
    is easily dealt with in the subsequent pattern matching to find the CPU family.

-   Instead of extracting the "model name" line one could also extract the "vendor_id",
    "cpu family" and "model" lines.

    E.g.,

    -   AMD Rome: CPU family 23, model 49.
    -   Intel Ivy Bridge: CPU family 6, model 62
    -   Intel Broadwell: CPU family 6, model 79
    -   Intel Skylake: CPU family 6, model 85
    -   Intel Cascade Lake: Actually also CPU family 6, model 85, just a different
        stepping: 7 versus 4 for our Skylake CPUs

-   Accelerators can be detected by looking in the output of the lspci command

-   The OS can be detected from the variables that can be set through /etc/os-release,
    and in particular the NAME and VERSION_ID lines.


| Node type                  | vendor_id    | cpu family | model | lspci   |
|:---------------------------|:-------------|:-----------|:------|:--------|
| login node vaughan         | AuthenticAMD | 23         | 49    | /       |
| compute node vaughan       | AuthenticAMD | 23         | 49    | /       |
| NVIDIA node vaughan        | AuthenticAMD | 23         | 49    | /       |
| MI100 node vaughan         | AuthenticAMD | 23         | 49    | MI100   |
| login node leibniz         | GenuineIntel | 6          | 79    | GA100   |
| visualisation node leibniz | GenuineIntel | 6          | 79    | GP104GL |
| compute node leibniz       | GenuineIntel | 6          | 79    | /       |
| compute node hopper        | GenuineIntel | 6          | 62    | /       |
| Pascal node leibniz        | GenuineIntel | 6          | 79    | GP100GL |
| Aurora node leibniz        | GenuineIntel | 6          | 85    | NEC     |
| Biomina node leibniz       | GenuineIntel | 6          | 85    | /       |


### Final solution

The solution chosen was the last one, reading information from `/proc/cpuinfo`, `/etc/os-release`
and the output of `lspci`.

The detection is implemented in `LMOD/SitePackage_system_info.lua`. 


## Binary versions loaded by the cluster and arch modules

### Option 1: Maximal common installations

There are almost always three levels:

-   Level 1: Unoptimized generic x86 64-bit CPU

-   Level 2: Specific CPU architecture, but the package is fully GPU agnostic

-   Level 3: Specific CPU architecture and the package may have accelerated versions
    that we need to install with the same name.

Combinations:

| Node                  | L1 (generic)   | L2                | L3                        |
|:----------------------|:---------------|:------------------|:--------------------------|
| login/compute vaughan | redhat8-x86_64 | redhat8-zen2      | redhat8-zen2-noaccel      |
| vaughan Ampere node   | redhat8-x86_64 | redhat8-zen2      | redhat8-zen2-ampere       |
| vaughan MI100         | redhat8-x86_64 | redhat8-zen2      | redhat8-zen2-arcturus     |
| login/compute leibniz | redhat8-x86_64 | redhat8-broadwell | redhat8-broadwell-noaccel |
| leibniz visualisation | redhat8-x86_64 | redhat8-broadwell | redhat8-broadwell-P5000   |
| leibniz Pascal        | redhat8-x86_64 | redhat8-broadwell | redhat8-broadwell-pascal  |
| BioMina node          | redhat8-x86_64 | redhat8-skylake   | redhat8-skylake-noaccel   |
| Leibniz aurora        | redhat8-x86_64 | redhat8-skylake   | redhat8-skylake-aurora1   |
| Hopper node           | redhat8-x86_64 | redhat8-ivybridge | /                         |

For Hopper we could drop the highest level as we only have nodes without accelerator
and no new nodes with this CPU will ever come in.

Advantages:

-   Minimal number of duplicated installations

Disadvantages:

-   Very easy to make mistakes about what to install where. No package should be installed with the same
    full name (name + version + versionsuffix) at multiple levels. No package can have
    dependencies at a higher level.

-   As it would be dangerous to have both an OpenMPI with and without accelerator support loaded, it means
    we have to install OpenMPI and all packages that depend on it at level 3, so we need to be very careful
    here.

    -   Everything installed with Intel that does not need a GPU can be installed at level 2 as there is
        no GPU-specific Intel MPI.

    -   With FOSS and its subtoolchains the situation is different. GCCcore and GCC can be installed at level
        1 or 2 but as long as we do not know if the EasyBuild community will succeed at building a single
        MPI module that works for everything, gompi and foss software should be installed at level 3.


### Option 2: Only common installations for software such as Matlab or maybe system toolchain

Now there are two levels:

-   Level 1: Unoptimized generic x86 64-bit CPU

-   Level 2: Optimised software

| Node                  | L1 (generic)   | L2 (shortest)            | L2 (3-component)          |
|:----------------------|:---------------|:-------------------------|:--------------------------|
| login/compute vaughan | redhat8-x86_64 | redhat8-zen2             | redhat8-zen2-noaccel      |
| vaughan Ampere node   | redhat8-x86_64 | redhat8-zen2-ampere      | redhat8-zen2-ampere       |
| vaughan MI100         | redhat8-x86_64 | redhat8-zen2-arcturus    | redhat8-zen2-arcturus     |
| login/compute leibniz | redhat8-x86_64 | redhat8-broadwell        | redhat8-broadwell-noaccel |
| leibniz visualisation | redhat8-x86_64 | redhat8-broadwell-P5000  | redhat8-broadwell-P5000   |
| leibniz Pascal        | redhat8-x86_64 | redhat8-broadwell-pascal | redhat8-broadwell-pascal  |
| BioMina node          | redhat8-x86_64 | redhat8-skylake          | redhat8-skylake-noaccel   |
| Leibniz aurora        | redhat8-x86_64 | redhat8-skylake-aurora1  | redhat8-skylake-aurora1   |
| Hopper node           | redhat8-x86_64 | redhat8-ivybridge        | redhat8-ivybridge-noaccel |


Users could in principle still use software from another architecture within the stack
by loading the appropriate clusterarch module so we could still be fairly selective
about what we provide for the "special" nodes with accelerators. However, many of the
often recurring dependencies like alternatives for what are often basic OS libraries
would have to be installed multiple times.

In this case the "noaccel" architecture isn't really needed unless we want all names
to have three components if they are on level 2 (which may ease a transition to option
1 later on).

Advantages

-   Conceptually certainly simpler as there is little doubt about where to install a module

Disadvantages

-   Larger volume of the overall software stack as more modules will be duplicated.

