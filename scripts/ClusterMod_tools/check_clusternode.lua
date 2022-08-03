#! /usr/bin/env lua

local lfs = require( 'lfs' )

local routine_name = 'check_clusternode'

if #arg ~= 1 then
    io.stderr:write( routine_name .. ': ERROR: One command line argument is expected: path to the system definition file.\n' )
    os.exit( 1 )
end

local systemdefinition_file = arg[1]
if systemdefinition_file:find( '/' ) ~= 1 then
    -- Not an absolute path, it does not start with a slash.
    systemdefinition_file = lfs.currentdir() .. '/' .. systemdefinition_file
end

local script_called_dir = arg[0]:match( '(.*)/[^/]+' )
lfs.chdir( script_called_dir )
local repo_root = lfs.currentdir():match( '(.*)/scripts/ClusterMod_tools' )
local root_dir = repo_root:match( '(.*)/[^/]+' )

dofile( repo_root .. '/scripts/ClusterMod_tools/lmod_emulation.lua' )
dofile( systemdefinition_file )
dofile( repo_root .. '/LMOD/SitePackage_helper.lua' )
dofile( repo_root .. '/LMOD/SitePackage_system_info.lua' )
dofile( repo_root .. '/LMOD/SitePackage_map_toolchain.lua' )
dofile( repo_root .. '/LMOD/SitePackage_arch_hierarchy.lua' )


-- -----------------------------------------------------------------------------
--
-- Detected system information.
--

print( '\nInformation about this node:' )

print( '- The host name is ' .. get_hostname() )

local osname
local osversion
osname, osversion = get_os_info()
print( '- The OS is ' .. osname .. ' ' .. osversion )

print( '- The CPU string is ' .. get_cpu_info() )

print( '- Detected accelerator is ' .. ( get_accelerator_info() or 'none detected' ) )

local clusternode_long_osarch = get_cluster_longosarch()
print( '- Detected node architecture: ' .. clusternode_long_osarch )

-- -----------------------------------------------------------------------------
--
-- Print the version of each software stack that will be used.
--

print()
for stack,_ in pairs( ClusterMod_ClusterMap ) do
    print( '- Used architecture for this node for ' .. stack .. ': ' .. get_stack_top( get_stack_osarch_current( stack ), stack ) )
end

-- -----------------------------------------------------------------------------
--
-- Extended information about the software stack.
--

print()

for stack_version,_ in pairs( ClusterMod_ClusterMap ) do

    -- if stack_version ~= 'system' and stack_version ~= 'manual' then
    if stack_version ~= 'manual' then

        local stack = ClusterMod_StackName .. '/' .. stack_version

        local use_longarch = get_stack_top( get_stack_osarch_current( stack_version ), stack_version )
        local use_longarch_system = get_stack_top( get_stack_osarch_current( 'system' ), 'system' )

        print( '- EasyBuild stack ' .. stack .. ': ' )
        print( '  - Used top architecture for the stack: ' .. use_longarch )
        print( '  - Used top architecture for the system modules: ' .. use_longarch_system )

        -- Check if there is an alternative name for the architecture

        local current_longosarch = get_stack_osarch_current( stack_version )
        if ClusterMod_ClusterMap[stack_version] ~= nil then
            for name,longarch in pairs( ClusterMod_ClusterMap[stack_version] ) do
                if longarch == current_longosarch then
                    print( '  - Alternative architecture name: cluster/' .. name )
                end
            end
        end

        -- Construct the MODULEPATH entries
        
        local moduledirs = {} 

        local system_dirs = get_system_module_dirs( use_longarch_system, ClusterMod_StackName, 'system' )
        if system_dirs == nil then
            io.stderr.write( 'No system modules found for ' .. stack .. '. This points to an error in the module system or cluster definition.\n' )
        else
            for _,system_dir in ipairs( system_dirs ) do
                table.insert( moduledirs, system_dir )
            end
        end

        if stack_version ~= 'system' then
            local stack_dirs = get_system_module_dirs( use_longarch, ClusterMod_StackName, stack_version )
            if stack_dirs == nil then
                io.stderr.write( 'No regular modules found for ' .. stack .. '. This points to an error in the module system or cluster definition.\n' )
            else
                for _,stack_dir in ipairs( stack_dirs ) do
                    table.insert( moduledirs, stack_dir )
                end
            end
        end

        local inframodule_dir = get_system_inframodule_dir( use_longarch, ClusterMod_StackName, stack_version )
        if inframodule_dir == nil then
            io.stderr.write( 'No infrastructure modules found for ' .. stack .. '. This points to an error in the module system or cluster definition.\n' )
        else
            table.insert( moduledirs, inframodule_dir )
        end

        print( '  - Modules (reverse order of MODULEPATH):\n    + ' .. table.concat( moduledirs, '\n    + ' ) )

    end

end

