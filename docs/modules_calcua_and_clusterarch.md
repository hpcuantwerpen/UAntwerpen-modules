# The generic calcua and clusterarch modules

The calcua and clusterarch modules work together to load a version of the
software stack for the right architecture. Moreover they ensure that the
EasyBuild-config module can recover all the information it needs to install
software in the right directories.

The calcua module is loaded first. This module sets the version of the software
stack. The version of the software stack is of the form year followed by the letter
a or b.

TODO: Think about support for yyyy.mm also as this is used during the development
of new toolchains in EasyBuild itself, and also for EESSI.

The calcua modules will automatically load the best fitting clusterarch module
for the node on which the module is loaded. However, it is always possible to
overwrite that option later on.

Instances of the generic clusterarch module come in two shapes:
  * cluster/<name> or cluster/<name>-<OS> or cluster/<name>-<target> or
    cluster/<name>-<OS>-<target> or any other special designator: This is because
    users will typically be more familiar with the name of the cluster than with
    the CPU architecture. The mapping to CPU architecture is coded internally.
  * arch/<target> or arch/<OS>-<target>: This is a direct mapping
    to the underlying directory structure.
The <target> and <OS> fields correspond to what would be used in Spack,
with the exception that we use skylake instead of skylake_avx512.


## The calcua generic module






## The clusterarch generic module



## Clusterarch

This is a very complete list. Certainly initially some clusterarchs will be mapped
on others (e.g., no specific stacks on the GPU nodes) but this may be revised
over time.

Note for the long names:
  * The CPU target is based on the target that spack would report (or for that
    reason the archspec tool), except that we use skylake instead of
    skylake_avx512 and don't distinguish with Cascade Lake as that is just
    a different stepping fo the same CPU family and model.
  * The OS name is also based on what spack would report
In doing so, we hopefully ensure that the stack is future-proof and will
use similar naming as what would be used in Spack or in EESSI, as that also
follows these conventions for CPU targets. For the accelerators we've chosen
user-friendly names rather than their technical names.

Note for the short names:
  * For the AMD processors we simply refer to the zen name as that is
    already a very short name.
  * For the Intel processors we use established abbreviations: IVB for
    Ivy Bridge, BRW for Broadwell and SKLX for Skylake (in fact, the more
    often used abbreviation for Skylake with AVX512 is SKL-X but we want
    to avoid dashes in the name).
  * For the AMD GPUs we refer to their internal GFX code which is often
    used in architecture strings for compilers with OpenMP offload.
  * For NVIDIA GPUs we refer to their Compute Capability as that is
    a parameter that needs to be set when compiling. Furthermore we add "GL"
    to the string if it is a GPU for OpenGL visualisation. Hence:
      * The Ampere A100 becomes NVCC80 as it has compute capability 8.0.
      * The Tesla P100 becomes NVCC60 as it has compute capability 6.0.
      * The Quadro P5000 which is based on the GP104 chip becomes
        NVCC61GL as it has compute capability 6.1 and is also meant for
        visualisation with OpenGL.

These names are fixed in a function in `SitePackage.lua`.

| long                     | short             |
|:-------------------------|:------------------|
| centos8-zen2             | COS8-zen2         |
| centos8-zen2-ampere      | COS8-zen2-NVCC80  |
| centos8-zen2-arcturus    | COS8-zen2-GFX908  |
| centos8-broadwell        | COS8-BRW          |
| centos8-broadwell-quadro | COS8-BRW-NVGP61GL |
| centos8-broadwell-pascal | COS8-BRW-NVCC60   |
| centos8-skylake-aurora1  | COS8-SKLX-NEC1    |
| centos8-ivybridge        | COS8-IVB          |
| centos8-skylake          | COS8-SKLX         |


## Node detection

### Based on names

It is difficult to get hostname and domain in one. `hostname -f` does not have the
desired effect on vaughan. One workaround is to use

```bash
host $(hostname -i) | awk '{print $NF }'
```

Results:

| Node type                  | `host $(hostname -i) | awk '{print $NF }'` |
|:---------------------------|:-------------------------------------------|
| login node vaughan         | lnX.vaughan.antwerpenb.vsc                 |
| compute node vaughan       | rXcYYcnZ.vaughan.antwerpen.vsc             |
| NVIDIA node vaughan        | nvam1.vaughan.antwerpen.vsc                |
| MI100 node vaughan         | amdarcX.vaughan.antwerpen.vsc              |
| login node leibniz         | lnX.leibniz.antwerpen.vsc                  |
| visualisation node leibniz | vizX.leibniz.antwerpen.vsc                 |
| compute node leibniz       | rXcYYcnZ.leibniz.antwerpen.vsc             |
| compute node hopper        | rXcYYcnZ.hopper.antwerpen.vsc              |
| Pascal node leibniz        | paX.leibniz.antwerpen.vsc                  |
| Aurora node leibniz        | aurora.leibniz.antwerpen.vsc               |
| Biomina node leibniz       | r0c03cZ.leibniz.antwerpen.vsc              |


### Based on VSC_ variables

  * Variables:

      * VSC_ARCH_LOCAL: Currently ivybridge, broadwell or rome.

          * The BioMina node also returns VSC_ARCH_LOCA=broadwell...

          * What about the aurora node?

      * VSC_OS_LOCAL: centos7 or centos8

  * It is not possible to detect the accelerator type


### Reading information in /proc etc.


  * Get the CPU type:

    ```bash
    cat /proc/cpuinfo | grep -m 1 "model name"  | cut -d : -f 2
    ```

    The only problem with this one is that it will still have a leading space but that
    is easily dealt with in the subsequent pattern matching to find the CPU family.

  * Instead of extracting the "model name" line one could also extract the "vendor_id",
    "cpu family" and "model" lines.

    E.g.,

      * AMD Rome: CPU family 23, model 49.
      * Intel Ivy Bridge: CPU family 6, model 62
      * Intel Broadwell: CPU family 6, model 79
      * Intel Skylake: CPU family 6, model 85
      * Intel Cascade Lake: Actually also CPU family 6, model 85, just a different
        stepping: 7 versus 4 for our Skylake CPUs

  * Accelerators can be detected by looking in the output of the lspci command

  * The OS can be detected from the variables that can be set through /etc/os-release,
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


