# Environment variables


## Set by `ClusterMod-init` 

-   `_<PREFIX>_INIT_FIRST_LOAD`: Set to one as soon as the module has been loaded for the first time
    and used to avoid re-displaying the message-of-the-day when the module is reloaded because of
    a `module purge`.
    
    
## Set by the `stack` generic module

-   `<PREFIX>_STACK_NAME`: Name of the software stack that is loaded.  

-   `<PREFIX>_STACK_VERSION`: version of the software stack that is loaded.  

-   `<PREFIX>_STACK_NAME_VERSION`: Name and version (format name/version) of the software stack that is loaded.  


## Set by the `clusterarch` generic module


-   `<PREFIX>_ARCH_OSARCH`: The long os + architecture string for the activated architecture.


## Set by LMOD

-   `<PREFIX>_FAMILY_CLUSTERMOD_SOFTWARESTACK`

-   `<PREFIX>_FAMILY_CLUSTERMOD_SOFTWARESTACK_VERSION`

-   `<PREFIX>_FAMILY_CLUSTERMOD_CLUSTERARCH`

-   `<PREFIX>_FAMILY_CLUSTERMOD_CLUSTERARCH_VERSION`

