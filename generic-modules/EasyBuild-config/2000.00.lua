-- EasyBuild configuration module
-- Written by Kurt Lust, kurt.lust@uantwerpen.be
--

if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. myModuleFullName() .. ', mode ' .. mode() )
end

--
-- Some site configuration, but there may be more as there are more parts currently
-- tuned for the UAntwerp configuration
--

-- System configuration: install root etc.
local system_install_root = get_system_install_root()
local systemrepo_,modules = get_systemrepo_modules()
local systemrepo_easybuild = get_systemrepo_easybuild()
-- User configuration
local user_install_root = get_user_install_root()

-- Prefixes for environment variables
local site = get_clustername():upper() -- Site-specific prefix for the environment variable names set in the software stack modules.

-- Get the current software stack including the architecture from the location of the module.
local stack_name
local stack_version
local osarch
stack_name, stack_version, osarch = 
    myFileName():match( '.*/modules%-infrastructure/infrastructure/([^/]+)-([^/]+)/([^/]+)/' )


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













-- Final debugging information

if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    local modulepath = os.getenv( 'MODULEPATH' ):gsub( ':', '\n' )
    LmodMessage( 'DEBUG: The MODULEPATH before exiting ' .. myModuleFullName() .. ' (mode ' .. mode() .. ') is:\n' .. modulepath .. '\n' )
end
