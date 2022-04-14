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
-- Print the version of each software stack that will be used.
--

for stack,_ in pairs( CalcUA_ClusterMap ) do
    print( 'Used architecture for this node for ' .. stack .. ': ' .. get_calcua_top( get_calcua_longosarch_current( stack ), stack ) )
end
