-- EasyBuild configuration module
-- Written by Kurt Lust, kurt.lust@uantwerpen.be
--

if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    io.stderr:write( 'DEBUG: Entering ' .. myModuleFullName() .. ', mode ' .. mode() .. '\n' )
end

--
-- Some site configuration, but there may be more as there are more parts currently
-- tuned for the UAntwerp configuration
--

-- System configuration: install root etc.
local system_install_root = get_system_install_root()
local systemrepo_modules = get_systemrepo_modules()
local systemrepo_easybuild = get_systemrepo_easybuild()
-- User configuration
local user_install_root = get_user_install_root()
local support_user_installation
if user_install_root == nil then
    support_user_installation = false
    user_install_root = '' -- To avoid problems further on and avoid having to test all the time for nil values.
else
    support_user_installation = true
end

-- Prefixes for filename (cluster) and for environment variables (site)
local cluster = get_clustername()  -- Site-specific prefix for, e.g., the hookds file.
local site = cluster:upper()       -- Site-specific prefix for the environment variable names set in the software stack modules.

-- Get the current software stack including the architecture from the location of the module.
local stack_name
local stack_version
local osarch
stack_name, stack_version, osarch = 
    myFileName():match( '.*/modules%-infrastructure/infrastructure/([^/]+)/([^/]+)/arch/([^/]+)/' )
if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    io.stderr:write( 'DEBUG: ' .. myModuleFullName() .. ': stack_name = ' .. ( stack_name or 'NIL' ) ..
                     ', stack_version = ' .. ( stack_version or 'NIL' ) ..
                     ', osarch = ' .. ( osarch or 'NIL' ) .. 
                     ', derived from module file name ' .. myFileName() .. '\n' )
end
 
local osarch_system = get_stack_matchingarch( osarch, stack_version, 'system' )


-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
--
-- Actual module code
--

local modulename = myModuleName()

--
-- Check if I am replacing another module.
-- If so, no message will be shown at the end. This eliminates a double message
-- as loading another module of the same family will load the module twice. The
-- first time the message will not be shown.
--
local show_message = true
if modulename ~= 'EasyBuild-user'           and isloaded( 'EasyBuild-user' )           then show_message = false end
if modulename ~= 'EasyBuild-production'     and isloaded( 'EasyBuild-production' )     then show_message = false end
if modulename ~= 'EasyBuild-infrastructure' and isloaded( 'EasyBuild-infrastructure' ) then show_message = false end

--
-- Avoid loading any of EasyBuild-user, EasyBuild-production or EasyBuild-infrastructure at the same time
--

family( 'EasyBuildConfig' )

--
-- Detect the mode
--
local detail_mode = modulename:gsub( 'EasyBuild%-', '') -- production, infrastructure or user
local mod_mode                                          -- system,     system         or user
local mod_prefix                                        -- easybuild,  infrastructure or easybuild
if detail_mode == 'user' then
    mod_mode =   'user'
    mod_prefix = 'easybuild'  -- TODO: Do we need this?
elseif detail_mode == 'production' then
    mod_mode =   'system'
    mod_prefix = 'easybuild'
elseif detail_mode == 'infrastructure' then
    mod_mode =   'system'
    mod_prefix = 'infrastructure'
else
    LmodError( 'Unrecongnized module name' )
end

-- Make sure that when in system mode, the unlock module is loaded.
if mode() == 'load' and mod_mode == 'system' and not isloaded( 'EasyBuild-unlock' ) then
    LmodError( 'This module requires EasyBuild-unlock to be loaded first as an additional precaution to avoid damaging the system installation.' )
end

-- Produce an error message when loading in user mode and user_prefix == '' which implies that
-- EBU_USER_PREFIX was set but empty. This value of EBU_USER_PREFIX can be used if we really
-- do not want a user installation, also not the default one.
-- Also make sure that user prefix is some kind of absolute path, starting either with a slash or with
-- a ~, though we don't do a full test for a valid directory. Relative directories should not be
-- used as this may lead to installing in the wrong directories.
if mode() == 'load' and mod_mode == 'user' then
    if not support_user_installation then
        LmodError( 'User installation is impossible as it was explicitly turned off by setting EBU_USER_PREFIX to an empty value.' )
    elseif user_install_root:match('^[~/]') == nil then
        LmodError( 'Detected an invalid user installation directory. When using EBU_PREFIX_USER, an absolute path should be used.' )
    end
end

-- Make sure EasyBuild is loaded when in user mode. In any of the system modes
-- we assume the user is clever enough and want to support using an eb version
-- which is not in the module tree, e.g., to bootstrap.
local easybuild_versionless = os.getenv( 'EBU_EASYBUILD_VERSIONLESS' ) or 0
if string.lower( easybuild_versionless ) == 'no' or easybuild_versionless == 0 then
    easybuild_versionless = false 
else
    easybuild_versionless = true
end
local easybuild_version
local easybuild_module
if easybuild_versionless then
    easybuild_module = 'EasyBuild'
else
    easybuild_version = get_stack_EasyBuild_version( stack_version )
    if easybuild_version == nil then
        LmodError( 'Failed to find a matching EasyBuild version for the stack ' .. (stack_name or 'NIL') .. '/' .. (stack_version or 'NIL') )
    end
    easybuild_module = 'EasyBuild/' .. easybuild_version
end

if not isloaded( easybuild_module ) then
    if mod_mode == 'system' then
        try_load( easybuild_module )
    else
        load( easybuild_module )
    end
end


-- -----------------------------------------------------------------------------
--
-- Compute the configuration
--

-- - Prepare some additional variables to reduce the length of some lines

local stack = stack_version == 'system'  and 'system' or stack_name  .. '-' .. stack_version

-- - Find a suitable directory to create some temporary build space for EasyBuild
--   We set the work directory based on where we are running, not based on for which partition
--   we are compiling.
--   Strategy:
--   - if EBU_REMOTE_BUILD is defined and not 0 or no, then the build directocy is in
--     /dev/shm/$USER/easybuild as that is always available. The disadvantage of this choice is that it does
--     not get cleaned automatically.
--   - If XDG_RUNTIME_DIR is defined, which is the case on the login nodes, then the 
--     subdirectory 'easybuild' of that directory is used.
--   - Otherwise, if we detect SLURM_JOB_ID, use /dev/shm/$USER-$JOBID/easybuild. In that way
--     we may have multiple jobs on a node each compiling the same package (though in a different
--     configuration) without one job overwriting the work of another one.
--   - Otherwise we simply use /dev/shm/$USER/easybuild
--

local workdir

local remote_build = os.getenv( 'EBU_REMOTE_BUILD' ) or 0 
if string.lower( remote_build ) == 'no' or remote_build == 0 then
    remote_build = false
else
    remote_build = true
end

local userid = os.getenv( 'USER' )
if userid == nil then
    LmodError( 'Failed to get the value of the environment variable USER' )
end

if remote_build then
    workdir = pathJoin( '/dev/shm', user, 'easybuild' )
else

    local XDG_dir = os.getenv( 'XDG_RUNTIME_DIR' )
    local SLURM_id = os.getenv( 'SLURM_JOB_ID' )

    if XDG_dir ~= nil then
        workdir = pathJoin( XDG_dir, 'easybuild' )
    elseif SLURM_id ~= nil then
        workdir = pathJoin( '/dev/shm', userid .. SLURM_id, 'easybuild' )
    else
        workdir = pathJoin( '/dev/shm', user, 'easybuild' )
    end

end

-- - Compute the location of certain directories and files

--    + Some easy ones that do not depend the software stack itself

local system_configdir =           pathJoin( systemrepo_easybuild, 'easybuild/config' )
local system_easyconfigdir =       pathJoin( systemrepo_easybuild, 'easybuild/easyconfigs' )
local system_easyblockdir =        pathJoin( systemrepo_easybuild, 'easybuild/easyblocks' )
local system_hookdir =             pathJoin( systemrepo_easybuild, 'easybuild/hooks' )
local system_installpath =         system_install_root

local user_configdir =             pathJoin( user_install_root, 'UserRepo', 'easybuild/config' )
local user_easyconfigdir =         pathJoin( user_install_root, 'UserRepo', 'easybuild/easyconfigs' )
local user_easyblockdir =          pathJoin( user_install_root, 'UserRepo', 'easybuild/easyblocks' )
local user_installpath =           user_install_root

local configdir =     mod_mode == 'user' and user_configdir     or system_configdir
local easyconfigdir = mod_mode == 'user' and user_easyconfigdir or system_easyconfigdir
local installpath =   mod_mode == 'user' and user_installpath   or system_installpath

local system_sourcepath =          pathJoin( system_install_root, 'sources' )
local system_sourcepath_manual =   pathJoin( system_install_root, 'sources-manual' )
local system_containerpath =       pathJoin( system_install_root, 'containers' )
local system_packagepath =         pathJoin( system_install_root, 'packages' )

local user_sourcepath =            pathJoin( user_install_root,   'sources' )
local user_sourcepath_manual =     pathJoin( user_install_root,   'sources-manual' )
local user_containerpath =         pathJoin( user_install_root,   'containers' )
local user_packagepath =           pathJoin( user_install_root,   'packages' )

local containerpath = mod_mode == 'user' and user_containerpath or system_containerpath
local packagepath =   mod_mode == 'user' and user_packagepath   or system_packagepath

local module_naming_scheme_dir =   pathJoin( SystemRepo_prefix, 'easybuild/tools/module_naming_scheme/*.py' )

local buildpath =                  pathJoin( workdir, 'build' )
local tmpdir =                     pathJoin( workdir, 'tmp' )

--    + Directories that depend on the software stack

local system_installpath_software =  get_system_SW_dir( osarch, stack_name, stack_version )
local system_installpath_modules =   get_system_module_dir( osarch, stack_name, stack_version )
local system_repositorypath =        get_system_EBrepo_dir( osarch, stack_name, stack_version )

local user_installpath_software =    get_user_SW_dir( osarch, stack_name, stack_version )
local user_installpath_modules =     get_user_module_dir( osarch, stack_name, stack_version )
local user_repositorypath =          get_user_EBrepo_dir( osarch, stack_name, stack_version )

local infra_installpath_software =   get_system_SW_dir( osarch, stack_name, stack_version )
local infra_installpath_modules =    get_system_inframodule_dir( osarch, stack_name, stack_version )
local infra_repositorypath =         get_system_infra_EBrepo_dir( osarch, stack_name, stack_version )

local installpath_software, installpath_modules, repositorypath
if detail_mode == 'user' then
    installpath_software = user_installpath_software
    installpath_modules  = user_installpath_modules
    repositorypath       = user_repositorypath
elseif detail_mode == 'production' then
    installpath_software = system_installpath_software
    installpath_modules  = system_installpath_modules
    repositorypath       = system_repositorypath
elseif detail_mode == 'infrastructure' then
    installpath_software = infra_installpath_software
    installpath_modules  = infra_installpath_modules
    repositorypath       = infra_repositorypath
else
    LmodError( 'INTERNAL ERROR: detail_mode has an unexpected value when setting the installation directories' )
end

--    + The relevant config files

local system_configfile_generic = pathJoin( system_configdir, 'easybuild-production.cfg' )
local system_configfile_stack =   pathJoin( system_configdir, 'easybuild-production-' .. stack .. '.cfg' )

local user_configfile_generic =   pathJoin( user_configdir,   'easybuild-user.cfg' )
local user_configfile_stack =     pathJoin( user_configdir,   'easybuild-user-' .. stack .. '.cfg' )

-- - Settings for the module naming scheme

local module_naming_scheme_dir =  pathJoin( systemrepo_easybuild, 'easybuild/tools/module_naming_scheme/*.py' )
local module_naming_scheme =      'CalcUAMNS'
local suffix_modules_path =       ''

-- - Settings for the custom EasyBlocks

local easyblocks = { pathJoin( system_easyblockdir, '*/*.py' ) }
if mod_mode == 'user' then
    table.insert( easyblocks, pathJoin( user_easyblockdir, '*/*.py' ) )
end

-- - Settings for the hooks

local hooks = get_versionedfile( stack_version, system_hookdir, cluster .. '_site_hooks-', '.py' )
if hooks == nil then
    LmodWarning( 'Failed to determine the hooks file, so running EasyBuild without using hooks.' )
end

-- - Build the source paths

local source_paths = {}

--   + In usermode: The user source path comes first as that is where we want to write.
if mod_mode == 'user' then
    table.insert( source_paths, user_sourcepath )
    table.insert( source_paths, user_sourcepath_manual )
end

--   + The system source path is always included so that user installations that make small modifications
--     to a config don't need to download again
table.insert( source_paths, system_sourcepath )
table.insert( source_paths, system_sourcepath_manual )

-- - Build the robot path ROBOT_PATHS

local robot_paths = {}

--   + We do no longer include the current directory in user mode as this caused performance problems
--     when used outside of an EasyBuild repository.

--   + Always included in usermode: the user repository directories for the software stack
local EBrepo_work_dirs
if detail_mode == 'user' then

    EBrepo_work_dirs = get_user_EBrepo_dirs( osarch, stack_name, stack_version )
    for i = #EBrepo_work_dirs, 1, -1 do
        table.insert( robot_paths, EBrepo_work_dirs[i] )
    end


    if stack_version ~= 'system' then
        EBrepo_work_dirs = get_user_EBrepo_dirs( osarch_system, stack_name, 'system' )
        for i = #EBrepo_work_dirs, 1, -1 do
            table.insert( robot_paths, EBrepo_work_dirs[i] )
        end
    end

end

--   + Always include: The infrastructure repository for the current arch (no hierarchy)

table.insert( robot_paths, infra_repositorypath )

--   + Include in user and production mode: The system repositories

if detail_mode == 'user' or detail_mode == 'production' then

    EBrepo_work_dirs = get_system_EBrepo_dirs( osarch, stack_name, stack_version )
    for i = #EBrepo_work_dirs, 1, -1 do
        table.insert( robot_paths, EBrepo_work_dirs[i] )
    end

    if stack_version ~= 'system' then
        EBrepo_work_dirs = get_system_EBrepo_dirs( osarch_system, stack_name, 'system' )
        for i = #EBrepo_work_dirs, 1, -1 do
            table.insert( robot_paths, EBrepo_work_dirs[i] )
        end
    end

end

--   + Now add the user easyconfig directory
if detail_mode == 'user' then
    table.insert( robot_paths, user_easyconfigdir )
end

--   + Now include the system easyconfig directory.
table.insert( robot_paths, system_easyconfigdir )

--   + Finally see if we can determine the directory with EasyConfigs provided
--     by EasyBuild itself and add that one.
--     The constant EASYBIILD_ROBOT_PATHS which is available for that purpose only
--     works in configuration files.
--     We currently definitely don't want to install infrastructure modules directly
--     from the easybuilders repository so we disable this.
if detail_mode == 'user' or detail_mode == 'production' then
    local ebroot_easybuild = os.getenv( 'EBROOTEASYBUILD' )
    if ebroot_easybuild ~= nil then
        table.insert( robot_paths, pathJoin( ebroot_easybuild, 'easybuild/easyconfigs' ) )
    end
end

-- - List of additional directories for eb -S
--   Currently there are none.

local search_paths = {}

-- - List of config files. Later in the list overwrites settings by files earlier in the list.
local configfiles = {}

if isFile( system_configfile_generic )                      then table.insert( configfiles, system_configfile_generic ) end
if mod_mode == 'user' and isFile( user_configfile_generic ) then table.insert( configfiles, user_configfile_generic )   end
if isFile( system_configfile_stack )                        then table.insert( configfiles, system_configfile_stack )   end
if mod_mode == 'user' and isFile( user_configfile_stack )   then table.insert( configfiles, user_configfile_stack )     end

-- - Determine the necessary optimization options

local optarch = get_optarch( osarch, stack_name, stack_version )

--
-- Set the EasyBuild variables that point to paths or files
--

-- - Single component paths

setenv( 'EASYBUILD_PREFIX',                        ( mod_mode == 'user' and user_install_root or system_install_root ) )
setenv( 'EASYBUILD_SOURCEPATH',                    table.concat( source_paths, ':' ) )
setenv( 'EASYBUILD_CONTAINERPATH',                 containerpath )
setenv( 'EASYBUILD_PACKAGEPATH',                   packagepath )
setenv( 'EASYBUILD_INSTALLPATH',                   installpath )
setenv( 'EASYBUILD_INSTALLPATH_SOFTWARE',          installpath_software )
setenv( 'EASYBUILD_INSTALLPATH_MODULES',           installpath_modules )

setenv( 'EASYBUILD_REPOSITORY',                    'FileRepository' )
setenv( 'EASYBUILD_REPOSITORYPATH',                repositorypath )

setenv( 'EASYBUILD_BUILDPATH',                     buildpath )
setenv( 'EASYBUILD_TMPDIR',                        tmpdir )

-- - Path variables
setenv( 'EASYBUILD_ROBOT_PATHS',                   table.concat( robot_paths, ':' ) )
if #search_paths > 0 then
    setenv( 'EASYBUILD_SEARCH_PATHS',              table.concat( search_paths, ':' ) )
end

-- - List of configfiles
if #configfiles > 0 then
    setenv( 'EASYBUILD_CONFIGFILES',               table.concat( configfiles, ',' ) )
end

-- - Custom EasyBlocks
setenv( 'EASYBUILD_INCLUDE_EASYBLOCKS',            table.concat( easyblocks, ',' ) )

-- - Hooks
if hooks ~= nil then
    setenv( 'EASYBUILD_HOOKS',                     hooks )
end

-- - Naming scheme
setenv( 'EASYBUILD_INCLUDE_MODULE_NAMING_SCHEMES', module_naming_scheme_dir )
setenv( 'EASYBUILD_MODULE_NAMING_SCHEME',          module_naming_scheme )
setenv( 'EASYBUILD_SUFFIX_MODULES_PATH',           suffix_modules_path )

--
-- Other EasyBuild settings that do not depend on paths
--

-- Let's all use python3 for EasyBuild, but this assumes at least EasyBuild version 4.
setenv( 'EB_PYTHON', 'python3' )

-- Set optarch.
if optarch ~= nil then
    setenv( 'EASYBUILD_OPTARCH', optarch )
end

-- Set <PREFIX>_EASYBUILD_MODE to be used in hooks to only execute certain hooks in production mode.
setenv( site .. '_EASYBUILD_MODE', detail_mode )

-- -----------------------------------------------------------------------------
--
-- Define a bash function to clear temporary files.
-- The implementation of the C-shell function will likely only work on tcsh.
--
local bash_clear_eb = '[ -d ' .. workdir .. ' ] && /bin/rm -r ' .. workdir .. '; '
local csh_clear_eb =  'if ( -d ' .. workdir .. ' ) /bin/rm -r ' .. workdir .. '; '
set_shell_function( 'clear-eb', bash_clear_eb, csh_clear_eb )


-- -----------------------------------------------------------------------------
--
-- Create the user directory structure (in user mode only)
--
-- This isn't really needed as EasyBuild will create those that it needs on the
-- fly, but it does help to suggest to users right away where which files will
-- land.
--

if ( mode() == 'load' or mode() == 'show' ) and detail_mode == 'user' then

    if not isDir( user_repositorypath )       then execute{ cmd='/usr/bin/mkdir -p ' .. user_repositorypath,       modeA={'load'} } end
    if not isDir( user_sourcepath )           then execute{ cmd='/usr/bin/mkdir -p ' .. user_sourcepath,           modeA={'load'} } end
    if not isDir( user_easyconfigdir )        then execute{ cmd='/usr/bin/mkdir -p ' .. user_easyconfigdir,        modeA={'load'} } end
    if not isDir( user_easyblockdir )         then
        execute{ cmd='/usr/bin/mkdir -p ' .. user_easyblockdir, modeA={'load'} }
        -- Need to copy a dummy file here or eb --show-config will complain.
        execute{ cmd='/usr/bin/cp -r ' .. pathJoin( system_easyblockdir, '00') .. ' ' .. user_easyblockdir, modeA={'load'} }
    end
    if not isDir( user_configdir )            then execute{ cmd='/usr/bin/mkdir -p ' .. user_configdir,            modeA={'load'} } end
    if not isDir( user_installpath_software ) then execute{ cmd='/usr/bin/mkdir -p ' .. user_installpath_software, modeA={'load'} } end
    if not isDir( user_installpath_modules )  then
        execute{ cmd='/usr/bin/mkdir -p ' .. user_installpath_modules,  modeA={'load'} }
        -- If the clusterach modules would be changed in a way that they do not put
        -- directories in the MODULEPATH as long as they don't exist, then the next
        -- line should be uncommented.
        -- prepend_path( 'MODULEPATH', user_installpath_modules )
    end
  
end
  

-- -----------------------------------------------------------------------------
--
-- Make an adaptive help block: If the module is loaded, different information
-- will be shown.
--

if detail_mode == 'user' then
    whatis( 'Prepares EasyBuild for installation in a user or project directory.' )
elseif detail_mode == 'production' then
    whatis( 'Prepares EasyBuild for production installation in the system directories. Appropriate rights required.' )
elseif detail_mode == 'infrastructure' then
    whatis( 'Prepares EasyBuild for production installation in the system infrastructure directories. Appropriate rights required.' )
else
    LmodError( 'Unrecongnized module name' )
end


-- TODO: Add help.


if detail_mode == 'user' then

help( [[
Description
===========
The EasyBuild-user module configures EasyBuild through environment variables
for installation of software in a user directory.

The module works together with the software stack modules. Hence it is needed to first
load an appropriate software stack and only then load EasyBuild-user. After changing
the software stack it is needed to re-load this module (if it is not done automatically).

After loading the module, it is possible to simply use the eb command without further
need for long command line arguments to specify the configuration.

The module assumes the following environment variables:
    * EBU_USER_PREFIX: Prefix for the EasyBuild user installation. The default
      is $HOME/EasyBuild.
    * EBU_EASYBUILD_VERSIONLESS: When set and not 0 or no, the module will not try to
      load a specific version of EasyBuild. As such it would preserve whatever version
      a user has loaded already, or load the default version as determined by Lmod rules
      if no module is loaded.
    * EBU_REMOTE_BUILD: When set and not 0 or no, configure EasyBuild with a build and
      temporary directory that works everywhere so that EasyBuild can start Slurm jobs
      to build an application with lots of dependencies.

The following user-specific directories and files are used by this module:
    * Directory for user EasyConfig files:       ]] .. user_easyconfigdir .. '\n' .. [[
    * EasyBuild user configuration files:        ]] .. user_configdir .. '\n' .. [[
        - Generic config file:                   ]] .. user_configfile_generic .. '\n' .. [[
        - Software stack-specific config file:   ]] .. user_configfile_stack .. '\n' .. [[

The following system directories and files are used (if present):
    * Custom module naming schemes:             ]] .. module_naming_scheme_dir .. '\n' .. [[
    Using module naming scheme:                 ]] .. module_naming_scheme .. '\n' .. [[
    with suffix-module-path:                    ]] .. '\'' .. suffix_modules_path .. '\'\n' .. [[
    * EasyBuild configuration files:            ]] .. system_configdir .. '\n' .. [[
      - Generic config file:                    ]] .. system_configfile_generic .. '\n' .. [[
      - Software stack-specific config file:    ]] .. system_configfile_stack .. '\n' .. [[
    * Directory of system EasyConfig files:     ]] .. system_easyconfigdir .. '\n' .. [[
    * Repository of installed EasyConfigs:      ]] .. system_repositorypath .. '\n' .. [[

Based on this information, the following settings are used:
    * Software installation directory:          ]] .. installpath_software .. '\n' .. [[
    * Module files installation directory:      ]] .. installpath_modules .. '\n' .. [[
    * Repository of installed EasyConfigs       ]] .. repositorypath .. '\n' .. [[
    * Sources of installed packages:            ]] .. table.concat( source_paths, ':' ) .. '\n' .. [[
    * Containers installed in:                  ]] .. containerpath .. '\n' .. [[
    * Packages installed in:                    ]] .. packagepath .. '\n' .. [[
    * Custom EasyBlocks:                        ]] .. table.concat( easyblocks, ',' ) .. '\n' .. [[
    * Custom module naming schemes:             ]] .. module_naming_scheme_dir .. '\n' .. [[
      Using module naming scheme:               ]] .. module_naming_scheme .. '\n' .. [[
      with suffix-module-path:                  ]] .. '\'' .. suffix_modules_path .. '\'\n' .. [[
    * Robot search path:                        ]] .. table.concat( robot_paths, ':' ) .. '\n' .. [[
    * Search path for eb -S/--search:           ]] .. table.concat( search_paths, ':' ) .. '\n' .. [[
    * Builds are performed in:                  ]] .. buildpath .. '\n' .. [[
    * EasyBuild temporary files in:             ]] .. tmpdir .. '\n' .. [[

If multiple configuration files are given, they are read in the following order:
    1. System generic configuration file
    2. User generic configuration file
    3. System stack-specific configuration file
    4. User stack-specific configuration file
Options that are redefined overwrite the old value. However, environment variables set by
this module do take precedence over the values computed from the configuration files.

To check the actual configuration used by EasyBuild, run ``eb --show-config``. This is
also a good syntax check for the configuration files.

First use for a software stack
==============================
The module will also take care of creating most of the subdirectories that it
sets, even though EasyBuild would do so anyway when you use it. It does however
give you a clear picture of the directory structure just after loading the
module, and it also ensures that the software stack modules can add your user
modules to the front of the module search path.
]] )

else -- Help text for system mode

-- The help text in system mode is built up from several blocks.
-- Help system mode: Title
local helptext = [[
Description
===========
]]

if detail_mode == 'production' then

-- Help system mode: First block for EasyBuild-production
helptext = helptext .. [[
The EasyBuild-production module configures EasyBuild through environment variables
for installation of software in the system directories. Appropriate rights are required
for a successful install.

The module works together with the software stack modules. Hence it is needed to first
load an appropriate software stack and only then load EasyBuild-production. After changing
the software stack it is needed to re-load this module (if it is not done automatically).

After loading the module, it is possible to simply use the eb command without further
need for long command line arguments to specify the configuration.

The module assumes the following environment variables:
    * EBU_EASYBUILD_VERSIONLESS: When set and not 0 or no, the module will not try to
      load a specific version of EasyBuild. As such it would preserve whatever version
      a user has loaded already, or load the default version as determined by Lmod rules
      if no module is loaded.
    * EBU_REMOTE_BUILD: When set and not 0 or no, configure EasyBuild with a build and
      temporary directory that works everywhere so that EasyBuild can start Slurm jobs
      to build an application with lots of dependencies.

]]

else

-- First block for EasyBuild-infrastructure
helptext = helptext .. [[
The EasyBuild-infrastructure module configures EasyBuild through environment variables
for installation of software in the system infrastructure directories. Appropriate rights
are required for a successful install.

The module works together with the software stack modules. Hence it is needed to first
load an appropriate software stack and only then load EasyBuild-infrastructure. After changing
the software stack it is needed to re-load this module (if it is not done automatically).

It should only be used to install the Cray cpe* toolchains, EasyBuild configuration
modules (if they would be ported to EasyBuild), etc. as the Infrastructure
module tree should only be used for modules that need to be available for all
4 LUMI partitions and the hidden common pseudo-partition, where the modules in
common should not be visible or available in the other partitions, i.e., a
number of modules that are needed to make a hierarchy work and to reload
correctly when switching modules.

The EasyBuild configuration generated by this module is exactly the same
as the one generated by EasyBuild-production except for the location where
the modules are stored.

After loading the module, it is possible to simply use the eb command without further
need for long command line arguments to specify the configuration.

]]

end -- Of adding the first block of the help text in system mode (if detail_mode == production then else)

-- Help system mode: Middle block of the help text, same for EasyBuild-production and EasyBuild-infrastructure.
helptext = helptext .. [[
The following directories and files are used by this module:

    * Directory for EasyConfig files:           ]] .. system_easyconfigdir .. '\n' .. [[
    * Software installed in:                    ]] .. system_installpath_software .. '\n' .. [[
    * Module files installed in:                ]] .. system_installpath_modules .. '\n' .. [[
    * Repository of installed EasyConfigs:      ]] .. system_repositorypath .. '\n' .. [[
    * Sources of installed packages:            ]] .. system_sourcepath .. '\n' .. [[
    * Containers installed in:                  ]] .. system_containerpath .. '\n' .. [[
    * Packages installed in:                    ]] .. system_packagepath .. '\n' .. [[
    * Custom EasyBlocks:                        ]] .. table.concat( easyblocks, ',' ) .. '\n' .. [[
    * Custom module naming schemes:             ]] .. module_naming_scheme_dir .. '\n' .. [[
      Using module naming scheme:               ]] .. module_naming_scheme .. '\n' .. [[
      with suffix-module-path:                  ]] .. '\'' .. suffix_modules_path .. '\'\n' .. [[
    * EasyBuild configuration files:            ]] .. system_configdir .. '\n' .. [[
      - Generic config file:                    ]] .. system_configfile_generic .. '\n' .. [[
      - Software stack-specific config file:    ]] .. system_configfile_stack .. '\n' .. [[
    * Robot search path:                        ]] .. table.concat( robot_paths, ':' ) .. '\n' .. [[
    * Search path for eb -S/--search:           ]] .. table.concat( search_paths, ':' ) .. '\n' .. [[
    * Builds are performed in:                  ]] .. buildpath .. '\n' .. [[
    * EasyBuild temporary files in:             ]] .. tmpdir .. '\n' .. [[

If multiple configuration files are given, they are read in the following order:
    1. System generic configuration file
    2. System stack-specific configuration file
Options that are redefined overwrite the old value. However, environment variables set by
this module do take precedence over the values computed from the configuration files.

To check the actual configuration used by EasyBuild, run ``eb --show-config`` or
``eb --show-full-config``. This is also a good syntax check for the configuration files.

]]


if detail_mode == 'production' then

-- Help system mode: Final block for EasyBuild-production only
helptext = helptext .. [[
First use for a software stack
==============================
This module can actually be used when bootstrapping EasyBuild. It is possible to
do a temporary installation of EasyBuild outside the regular installation directories
and then load this module to install EasyBuild in its final location from an EasyConfig
file for EasyBuild and the temporary installation.

No directories are created or added to the MODULEPATH by this modules as modules are
installed in the directory where this module is found and as directories are created
by EasyBuild as needed.

]]

end -- End of adding final block to the help text

help( helptext ) -- Show help text in system mode.

end -- Of the help block (if detail_mode == user then else)

-- -----------------------------------------------------------------------------
--
-- Print an informative message so that the user knows that EasyBuild is
-- configured properly.
--

if mode() == 'load' and show_message then

    local stack_message
    stack_message = '\nEasyBuild configured to install software from the ' ..
            stack_name .. '/'.. stack_version ..
            ' software stack for the architecture ' .. osarch

    if detail_mode == 'user' then
        stack_message = stack_message ..
            ' in the user tree at ' .. user_install_root .. '.\n'
    elseif detail_mode == 'production' then
        stack_message = stack_message ..
            ' in the system application directories.\n'
    elseif detail_mode == 'infrastructure' then
        stack_message = stack_message ..
            ' in the system infrastructure directories.\n'
    else
        LmodError( 'Unrecongnized module name' )
    end

    -- Unfortunately it looks like LmodMessage reformats the string and deletes the spaces?
    stack_message = stack_message ..
        '  * Software installation directory:    ' .. installpath_software             .. '\n' ..
        '  * Modules installation directory:     ' .. installpath_modules              .. '\n' ..
        '  * Repository:                         ' .. repositorypath                   .. '\n' ..
        '  * Work directory for builds and logs: ' .. pathJoin( workdir, 'easybuild' ) .. '\n' ..
        '    Clear work directory with clear-eb\n'

    LmodMessage( stack_message )

end -- if mode() == 'load' and show_message

-- Final debugging information

if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    io.stderr:write( 'DEBUG: Exiting ' .. myModuleFullName() .. ', mode ' .. mode() .. '\n' )
end
