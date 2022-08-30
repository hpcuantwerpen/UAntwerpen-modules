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
local system_containerpath =       pathJoin( system_install_root, 'containers' )
local system_packagepath =         pathJoin( system_install_root, 'packages' )

local user_sourcepath =            pathJoin( user_install_root,   'sources' )
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
end

--   + The system source path is always included so that user installations that make small modifications
--     to a config don't need to download again
table.insert( source_paths, system_sourcepath )

-- - Build the robot path ROBOT_PATHS

local robot_paths = {}

--   + We do no longer include the current directory in user mode as this caused performance problems
--     when used outside of an EasyBuild repository.

--   + Always included in usermode: the user repository directories for the software stack
local EBrepo_work_dirs
if detail_mode == 'user' then

    EBrepo_work_dirs = get_user_EBrepo_dirs( osarch, stack_name, stack_version )
    for i,dir in ipairs( EBrepo_work_dirs ) do
        table.insert( robot_paths, dir )
    end

    if stack_version ~= 'system' then
        EBrepo_work_dirs = get_user_EBrepo_dirs( osarch_system, stack_name, 'system' )
        for i,dir in ipairs( EBrepo_work_dirs ) do
            table.insert( robot_paths, dir )
        end
    end

end

--   + Include in user and production mode: The system repositories

if detail_mode == 'user' or detail_mode == 'production' then

    EBrepo_work_dirs = get_system_EBrepo_dirs( osarch, stack_name, stack_version )
    for i,dir in ipairs( EBrepo_work_dirs ) do
        table.insert( robot_paths, dir )
    end

    if stack_version ~= 'system' then
        EBrepo_work_dirs = get_system_EBrepo_dirs( osarch_system, stack_name, 'system' )
        for i,dir in ipairs( EBrepo_work_dirs ) do
            table.insert( robot_paths, dir )
        end
    end

end

--   + Always include: The infrastructure repository for the current arch (no hierarchy)

table.insert( robot_paths, infra_repositorypath )

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
        table.insert( search_paths, pathJoin( ebroot_easybuild, 'easybuild/easyconfigs' ) )
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


-- Final debugging information

if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    io.stderr:write( 'DEBUG: Exiting ' .. myModuleFullName() .. ', mode ' .. mode() .. '\n' )
end
