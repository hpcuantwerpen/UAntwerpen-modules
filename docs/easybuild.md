# The EasyBuild configuration


## Location of the EasyBuild modules

Ideally we would have an EasyBuild module for each software stack stored in the generic 
architecture(s) for the software stack. However, we also need one for the `system` partition
and it may not be a good idea to stick to an old version there.

There are two options:

1.  One in the generic architecture(s) for `calcua/system` and one in each the generic
    architecture(s) for each of the `calcua/yyyyx` software stacks. This would guarantee
    that at least for the non-system stacks the EasyBuild version would remain constant,
    and it could even remain constant for the `system` stack for quite a while

2.  All EasyBuild installations are done in the generic architecture(s) of `calcua/system`.
    This would allow to use a different version of EasyBuild than intended for the stack.

We did chose to go for the second option. However, we do let the EasyBuild config modules
force-load the correct version so the user has to overwrite explicitly after loading that
module.

The stack does implement a script that will bootstrap EasyBuild rather than install
EasyBuild with another version of EasyBuild. This makes it very easy to set up a 
test stack in a different file system.


## Configuration modes (modules)

-   `EasyBuild-production` is the configuration for installing software with modules 
    in the `modules-easybuild` tree. Where software will be installed, is determined
    by the software stack and cluster architecture modules that are loaded at that
    time.

-   `EasyBuild-user` is the configuration for installing software in the user
    directory. The place where software will be installed in the user tree again
    depends on the software stack and cluster architecture modules that are 
    loaded at that time.

-   `EasyBuild-infrastructure` is the configuration for installing software whose
    modules go in the `modules-infrastrcutrue/infrastructure` tree. It is implemented
    but not really tested as we have no use for it at the moment.


## Settings in configuration files

-   Module syntax and naming scheme. Given that the whole module framework is based on Lmod, 
    it is not a good idea though to use Tcl-based modules even though Lmod can work with them.

-   Module naming scheme

-   Modules that should be hidden.

    This is not currently used in the configuration at UAntwerpen. It may be better to hide modules
    through Lmod instead as then modules maintain their regular version numbers and it is easier
    to change visibility afterwards.

-   Modules that may be loaded when EasyBuild runs.

-   Setting to ignore EBROOT variables without matching modules as this is very useful to define
    additional EBROOT variables in bundles.


## Settings through environment variables

-   Module installation path

    -   `production`: Determined by the `get_system_module_dir` function and based on 
        the system installation root.

    -   `infrastructure`: Determined by the `get_system_inframodule_dir` function and based
        on the system installation root.

    -   `user`: Determined by the `get_user_module_dir` function and based on 
        the user installation root.

-   Software installation path

    -   `production` and `infrastructure` use the same path, determined by the 
        `get_system_SW_dir` function and based on top of the system installation directory.

    -   `user`: Determined by the `gget_user_SW_dir` function and based on top of
        the user installation root.

-   Installed EasyConfigs repository

    -   `production` and `infrastructure` use the same directory, determined by the
        `get_system_EBrepo_dir` function and based on top of the system installation
        directory.

        As we should not have modules with the same name in the infrastructure and in
        the regular module tree, there does not seem to be a problem with this approach.

    -   `user`: Determined by the `get_user_EBrepo_dir` function and based on top
        of the user installation directory.

-   Sources subdirectories:

    -   `production` and `infrastructure` use the same directory, determined by the
        `get_system_EBsources_dir` function and based on top of the system installation
        directory.

    -   `user` stores the sources in the directory determined by the `get_user_EBsources_dir`
        function based on top of the user installation directory, but also adds the directory
        used by `production` to the sources path so that sources that are already on the
        system don't need to be downloaded again.
    
-   Robot search path.

    -   The goal of our settings is that we ensure as much as possible that for installed modules
        EasyBuild will find the EasyConfig used for that install. Therefore we put the repository
        of installed EasyConfigs first in the robot path, even though that is not commonly done.

        This does have a negative aspect also though: When re-installing a module after a change
        to the EasyConfig, we need to re-install each package that needs to be reinstalled by hand 
        from the directory of the corresponding EasyConfig, or the old one in the repository will be
        used instead.

    -   We use the `EASYBUILD_ROBOT_PATHS` environment variable so that dependency resolution is
        not turned on by default and the `-r` option remains available for users to add additional
        directories to the front of the search path.

    -   After that comes the default name for the user repository, if present and if the `user`
        module is being loaded.

    -   Next comes the system repository as can be obtained from `etc/SystemDefinition.lua`.

    -   Next we add the default EasyBuilders repository.

-   EasyConfig search path for `-S` and `--search`: No additional directories are used at the moment. 
    This can be changed should we chose to pull in additional repositories.

-   EasyBlocks:

    -   In user mode, if there is a user repository and if it contains an easyblocks subdirectory, then
        that one has the highest priority (but looks like it has to go at the end of the list).

    -   In all modes, the next highest priority are the EasyBlocks in the `easyblocks` subdirectory in the
        system EasyBuild repository.

    -   Last in line are the EasyBlocks from the EasyBuild distribution that is being used.

-   Configuration files: These are in the `easybuild/config` subdirectory of the system repo and the similar
    subdirectory in `UserRepo` of the user installation.

    In the order in which they should be read, so the later one wins on the earlier ones:

    1.  In all modes, `easybuild-production.cfg`

    2.  In `user` mode only, `easybuild-user.cfg`

    3.  In all modes, `easybuild-production-<stackname>-<stackversion>.cfg` where the stack name for the `system`
        version is also the regular stack name.

    4.  In `user` mode, `easybuild-user-<stackname>-<stackversion>.cfg` 

