-- Generic module for the software stack
-- Written by Kurt Lust, kurt.lust@uantwerpen.be
--

if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. myModuleFullName() .. ', mode ' .. mode() )
end

-- -----------------------------------------------------------------------------
--
-- Initialisations
--

family( 'ClusterMod_SoftwareStack' )
add_property( 'lmod', 'sticky' )

-- Detect the module root from the position of this module in the module tree
local install_root = myFileName():match( '(.*)/modules%-infrastructure/stack/.*' )

-- Detect the directory of LMOD configuration files from LMOD_PACKAGE_PATH
-- as that variable has to be set anyway for the LUMI module system to work
-- as we rely on SitePackage.lua, and this file does rely on the
-- detect_CALCUA_partition function defined in SitePackage.lua.
-- NOTE: Change this code if the LMOD configuration would be stored elsewhere!
local LMOD_root = os.getenv( 'LMOD_PACKAGE_PATH' )
if LMOD_root == nil then
    LmodError( 'Failed to get the value of LMOD_PACKAGE_PATH' )
end

-- Get the cluster name from the system definition to determine the prefix for
-- environment variables.


-- Detect the software stack from the name and version of the module
local stack_name    = myModuleName()
local stack_version = myModuleVersion()
 
-- Detect the architecture of the current node.
local node_osarch = get_stack_osarch_current( stack_version )
local used_osarch = get_stack_matchingarch( node_osarch, stack_version, stack_version )
if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. myModuleName() .. '/' .. myModuleVersion() .. 
                 ', stack name/version is  ' .. stack_name .. '/' .. stack_version ..
                 ', arch module to load is arch/' .. used_osarch )
end

local envvar_prefix = get_clustername():upper()

-- -----------------------------------------------------------------------------
--
-- Help information
--

whatis( 'Enables the ' .. stack_name .. '/' .. stack_version .. ' software stack for the current architecture.' )

help( [[

Description
===========
This module enables the ]] .. stack_name .. '/' .. stack_version .. [[ software stack for the current architecture.

By swapping the architecture module it is possible to load software compiled for
a different architecture instead, but be careful as that software may not run as
expected.

The module will also set a number of environment variables that can be useful
for references in scripts:
  * ]] .. envvar_prefix .. [[_STACK_NAME to ]] .. stack_name .. [[ (name of the software stack)
  * ]] .. envvar_prefix .. [[_STACK_VERSION to ]] .. stack_version .. [[ (version of the software stack)
  * ]] .. envvar_prefix .. [[_STACK_NAME_VERSION to ]] .. stack_name .. '/' .. stack_version .. [[ (name/version of the software stack)
]] )

-- -----------------------------------------------------------------------------
--
-- Main module logic
--

-- Add the architecture modules to the MODULEPATH.
prepend_path( 'MODULEPATH', pathJoin( install_root, 'modules-infrastructure/arch', stack_name, stack_version ) )

-- The following variables may be used by various modules and LUA configuration files.
-- However, take care as those variables may not be defined anymore when your module
-- gets unloaded.
setenv( envvar_prefix .. '_STACK_NAME',         stack_name )
setenv( envvar_prefix .. '_STACK_VERSION',      stack_version )
setenv( envvar_prefix .. '_STACK_NAME_VERSION', stack_name .. '/' .. stack_version )

-- Load the architecture module
load( 'arch/' .. used_osarch )

-- Final debugging information

if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    local modulepath = os.getenv( 'MODULEPATH' ):gsub( ':', '\n' )
    LmodMessage( 'DEBUG: The MODULEPATH before exiting ' .. myModuleFullName() .. ' (mode ' .. mode() .. ') is:\n' .. modulepath .. '\n' )
end
