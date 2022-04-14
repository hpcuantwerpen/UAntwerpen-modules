#! /usr/bin/env lua

local lfs = require( 'lfs' )

local routine_name = 'check_cluster'

local script_called_dir = arg[0]:match( '(.*)/[^/]+' )
lfs.chdir( script_called_dir )
local repo_root = lfs.currentdir():match( '(.*)/scripts/calcua_tools' )
local root_dir = repo_root:match( '(.*)/[^/]+' )

dofile( repo_root .. '/scripts/calcua_tools/lmod_emulation.lua' )
dofile( repo_root .. '/etc/SystemDefinition.lua' )
dofile( repo_root .. '/LMOD/SitePackage_helper.lua' )
dofile( repo_root .. '/LMOD/SitePackage_system_info.lua' )
dofile( repo_root .. '/LMOD/SitePackage_map_toolchain.lua' )
dofile( repo_root .. '/LMOD/SitePackage_arch_hierarchy.lua' )

-- -----------------------------------------------------------------------------
--
-- Detected system information.
--

print( '\nInformation about this system:' )

print( '- The host name is ' .. get_hostname() )

local osname
local osversion
osname, osversion = get_os_info()
print( '- The OS is ' .. osname .. ' ' .. osversion )

print( '- The CPU string is ' .. get_cpu_info() )

print( '- Detected accelerator is ' .. ( get_accelerator_info() or 'none detected' ) )

local clusterarch_short_minimal
local clusterarch_long_minimal
local clusterarch_short_maximal
local clusterarch_long_maximal
clusterarch_short_minimal, clusterarch_long_minimal, clusterarch_short_maximal, clusterarch_long_maximal = get_clusterarch()
print( '- Short minimal clusterarch: ' .. clusterarch_short_minimal )
print( '- Long minimal clusterarch:  ' .. clusterarch_long_minimal )
print( '- Short maximal clusterarch: ' .. clusterarch_short_maximal )
print( '- Long maximal clusterarch:  ' .. clusterarch_long_maximal )

-- -----------------------------------------------------------------------------
--
-- Print the version of each software stack that will be used.
--

print()
for stack,_ in pairs( CalcUA_ClusterMap ) do
    print( '- Used architecture for this node for ' .. stack .. ': ' .. get_calcua_top( get_calcua_longosarch_current( stack ), stack ) )
end
