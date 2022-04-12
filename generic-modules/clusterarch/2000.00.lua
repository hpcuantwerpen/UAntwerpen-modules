-- clusterarch generic module code
-- Written by Kurt Lust, kurt.lust@uantwerpen.be
--
-- This module works together with the calcua generic module to set up a version
-- of the software stack optimised for the hardware of the system
--

if os.getenv( '_CALCUA_LMOD_DEBUG' ) ~= nil then
--    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myModuleFullName() .. ': Entering' )
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myFileName() .. ': Entering' )
end

family( 'CalcUA_clusterarch' )
add_property( 'lmod', 'sticky' )

-- Detect the directory of LMOD configuration files from LMOD_PACKAGE_PATH
-- as that variable has to be set anyway for the LUMI module system to work
-- as we rely on SitePackage.lua, and this file does rely on the
-- detect_CALCUA_partition function defined in SitePackage.lua.
-- NOTE: Change this code if the LMOD configuration would be stored elsewhere!
local LMOD_root = os.getenv( 'LMOD_PACKAGE_PATH' )
if LMOD_root == nil then
    LmodError( 'Failed to get the value of LMOD_PACKAGE_PATH' )
end

--
-- Parse the full name of the module file to get all the information needed about
-- the installroot, stack and cluster architecture
--
local install_root
local stack_name
local stack_version
local cluster_arch
install_root, stack_name, stack_version, cluster_arch = 
    myFileName():match( '(.*)/modules%-infrastructure/arch/([^/]+)/([^/]+)/arch/(.+)%.lua' )  

if os.getenv( '_CALCUA_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myModuleFullName() .. ': Detected:\n' ..
                 '- install_root: ' .. install_root .. '\n' .. 
                 '- stack name/version: ' .. stack_name .. '/' .. stack_version .. '\n' ..
                 '- clusterarch:' .. cluster_arch )
end

-- Check if we have all the data we need for this stack version

if stack_name ~= 'calcua' then
    LmodError( myModuleFullName() .. ': Support for stack name ' .. stack_name .. 
               ' (detected from the module file name ' ..  myFileName() .. ') is not supported.' )
end
        
if not is_Stack_SystemTable( stack_version ) then
    LmodError( myModuleFullName() .. ': No information for calcua/' .. stack_version .. 
               ' in CalcUA_SystemTable in etc/SystemDefinition.lua.' )
end

--
-- Check where the user stack is located (if there is any)
--



--
-- Build the list of architectures for the given stack
--



--
-- If the stack is not calcua/system:
-- -   Look for the best matching architecture

-- -   And then build the list of architectures for that one







-- Final debugging information

if os.getenv( '_CALCUA_LMOD_DEBUG' ) ~= nil then
    local modulepath = os.getenv( 'MODULEPATH' ):gsub( ':', '\n' )
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myModuleFullName() .. ': The MODULEPATH before exiting ' .. myModuleFullName() .. ' (mode ' .. mode() .. ') is:\n' .. modulepath .. '\n' )
end
