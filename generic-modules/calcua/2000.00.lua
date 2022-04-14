-- calcua generic module code
-- Written by Kurt Lust, kurt.lust@uantwerpen.be
--

if os.getenv( '_CALCUA_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. myModuleFullName() .. ', mode ' .. mode() )
end

-- -----------------------------------------------------------------------------
--
-- Initialisations
--

family( 'CalcUA_SoftwareStack' )
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

-- Detect the software stack from the name and version of the module
local stack_name    = myModuleName()
local stack_version = myModuleVersion()
 
-- Detect the architecture of the current node. 
local long_osarch_current = get_calcua_top( get_calcua_longosarch_current( stack_version ), stack_version )
if os.getenv( '_CALCUA_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. myModuleName() .. '/' .. myModuleVersion() .. 
                 ', stack name/version is  ' .. stack_name .. '/' .. stack_version ..
                 ', arch module to load is arch/' .. long_osarch_current )
end

-- -----------------------------------------------------------------------------
--
-- Help information
--

whatis( 'Enables the calcua-' .. stack_version .. ' software stack for the current architecture.' )

help( [[

Description
===========
This module enables the calcua/]] .. stack_version .. [[ software stack for the current architecture.

By swapping the architecture module it is possible to load software compiled for
a different architecture instead, but be careful as that software may not run as
expected.

The module will also set a number of environment variables that can be useful
for references in scripts:
  * CALCUA_STACK_NAME to ]] .. stack_name .. [[ (name of the software stack)
  * CALCUA_STACK_VERSION to ]] .. stack_version .. [[ (version of the software stack)
  * CALCUA_STACK_NAME_VERSION to ]] .. stack_name .. '/' .. stack_version .. [[ (name/version of the software stack)
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
setenv( 'CALCUA_MODULEPATH_ROOT',    pathJoin( install_root, 'modules' ) )
setenv( 'CALCUA_STACK_NAME',         stack_name )
setenv( 'CALCUA_STACK_VERSION',      stack_version )
setenv( 'CALCUA_STACK_NAME_VERSION', stack_name .. '/' .. stack_version )

-- Load the architecture module
load( 'arch/' .. long_osarch_current )

-- Final debugging information

if os.getenv( '_CALCUA_LMOD_DEBUG' ) ~= nil then
    local modulepath = os.getenv( 'MODULEPATH' ):gsub( ':', '\n' )
    LmodMessage( 'DEBUG: The MODULEPATH before exiting ' .. myModuleFullName() .. ' (mode ' .. mode() .. ') is:\n' .. modulepath .. '\n' )
end
