-- clusterarch generic module code
-- Written by Kurt Lust, kurt.lust@uantwerpen.be
--
-- This module works together with the calcua generic module to set up a version
-- of the software stack optimised for the hardware of the system
--

if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
--    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myModuleFullName() .. ': Entering' )
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myFileName() .. ': Entering' )
end

family( 'ClusterMod_clusterarch' )
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
local osarch
install_root, stack_name, stack_version, osarch = 
    myFileName():match( '(.*)/modules%-infrastructure/arch/([^/]+)/([^/]+)/arch/(.+)%.lua' )

if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myModuleFullName() .. ': Detected:\n' ..
                 '- install_root: ' .. install_root .. '\n' .. 
                 '- stack name/version: ' .. stack_name .. '/' .. stack_version .. '\n' ..
                 '- clusterarch:' .. osarch )
end

-- Check if we have all the data we need for this stack version

if stack_name ~= get_stackname() then
    LmodError( myModuleFullName() .. ': Support for stack name ' .. stack_name .. 
               ' (detected from the module file name ' ..  myFileName() .. ') is not supported.' )
end
        
if not is_Stack_SystemTable( stack_version ) then
    LmodError( myModuleFullName() .. ': No information for ' .. get_stackname() .. '/' .. stack_version .. 
               ' in ClusterMod_SystemTable in the system definition file.' )
end

--
-- Check where the user stack is located (if there is any)
--
local user_easybuild_root = get_user_install_root()
-- if user_easybuild_modules ~= nil then
--     user_easybuild_modules = pathJoin( user_easybuild_modules, 'modules')
--     if not isDir( user_easybuild_modules ) then
--         user_easybuild_modules = nil
--     end
-- end
if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myModuleFullName() .. ': Detected user installation root at ' .. ( user_easybuild_root or 'NIL' ) )
end

--
-- Get the prefix for the environment variables
--
local envvar_prefix = get_clustername():upper()

-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------

--
-- Build the system module directories for the stack
--

local system_moduledirs = {} 
local user_moduledirs = {}
            
-- First build in reverse order (which actually corresponds to the order of prepend_path
-- calls in the module file)

local osarch_system = get_stack_matchingarch( osarch, stack_version, 'system' )
local system_systemstack_dirs = get_system_module_dirs( osarch_system, stack_name, 'system' )
if system_systemstack_dirs == nil then
    io.stderr.write( 'No system modules found for ' .. stack_version .. '. This points to an error in the module system or cluster definition.\n' )
else
    for _,system_systemstack_dir in ipairs( system_systemstack_dirs ) do
        table.insert( system_moduledirs, system_systemstack_dir )
    end
end
local user_systemstack_dirs = get_user_module_dirs( osarch_system, stack_name, 'system' )
if user_systemstack_dirs == nil then
    io.stderr.write( 'No user modules found for ' .. stack_version .. '. This points to an error in the module system or cluster definition.\n' )
else
    for _,user_systemstack_dir in ipairs( user_systemstack_dirs ) do
        table.insert( user_moduledirs, user_systemstack_dir )
    end
end


if stack_version ~= 'system' then 
    local system_stack_dirs = get_system_module_dirs( osarch, stack_name, stack_version )
    if system_stack_dirs == nil then
        io.stderr.write( 'No regular modules found for ' .. stack_version .. '. This points to an error in the module system or cluster definition.\n' )
    else
        for _,system_stack_dir in ipairs( system_stack_dirs ) do
            table.insert( system_moduledirs, system_stack_dir )
        end
    end
    local user_stack_dirs = get_user_module_dirs( osarch, stack_name, stack_version )
    if user_stack_dirs == nil then
        io.stderr.write( 'No regular modules found for ' .. stack_version .. '. This points to an error in the module system or cluster definition.\n' )
    else
        for _,user_stack_dir in ipairs( user_stack_dirs ) do
            table.insert( user_moduledirs, user_stack_dir )
        end
    end
end -- if stack_version ~= 'system'

local inframodule_dir = get_system_inframodule_dir( osarch, stack_name, stack_version )
if inframodule_dir == nil then
    io.stderr.write( 'No infrastructure modules found for ' .. stack_version .. '. This points to an error in the module system or cluster definition.\n' )
else
    table.insert( system_moduledirs, inframodule_dir )
end

--
-- Add the module directories to the MODULEPATH
--
local number
local moduledir
for number,moduledir in ipairs( system_moduledirs )
do
    prepend_path( 'MODULEPATH', moduledir )
end
if user_easybuild_root ~= nil then
    for number,moduledir in ipairs( user_moduledirs )
    do
        prepend_path( 'MODULEPATH', moduledir )
    end
end

--
-- Set the environment variables with the stack architecture.
--
setenv( envvar_prefix .. '_STACK_OSARCH', osarch )


-- Final debugging information

if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    local modulepath = os.getenv( 'MODULEPATH' ):gsub( ':', '\n' )
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myModuleFullName() .. ': The MODULEPATH before exiting ' .. myModuleFullName() .. ' (mode ' .. mode() .. ') is:\n' .. modulepath .. '\n' )
end
