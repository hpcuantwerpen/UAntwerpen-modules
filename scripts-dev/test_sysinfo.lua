#! /usr/bin/env lua

dofile( '../scripts/ClusterMod_tools/lmod_emulation.lua' )
dofile( '../etc/SystemDefinition.lua' )
dofile( '../LMOD/SitePackage_system_info.lua' )

print( '\nInformation about this system:' )

print( '- (get_clustername) The name of the cluster is ' .. get_clustername() )

print( '- (get_hostname) The host name is ' .. get_hostname() )

local osname
local osversion
osname, osversion = get_os_info()
print( '- (get_os_info) The OS is ' .. osname .. ' ' .. osversion )

print( '- (get_cpu_info) The CPU string is ' .. get_cpu_info() )

print( '- (get_accelerator_info) Detected accelerator is ' .. ( get_accelerator_info() or 'none detected' ) )

print( '- (get_cluster_osarch) Detected node architecture: ' .. ( get_cluster_osarch() or 'RETURNED NIL') )

print( '- (get_stackname) The name of the primary EasyBuild-managed software stack is ' .. get_stackname() )

-- local clusterarch_short_minimal
-- local clusterarch_long_minimal
-- local clusterarch_short_maximal
-- local clusterarch_long_maximal
-- clusterarch_short_minimal, clusterarch_long_minimal, clusterarch_short_maximal, clusterarch_long_maximal = get_clusterarch()
-- print( '- (get_clusterarch) Short minimal clusterarch: ' .. clusterarch_short_minimal )
-- print( '- (get_clusterarch) Long minimal clusterarch:  ' .. clusterarch_long_minimal )
-- print( '- (get_clusterarch) Short maximal clusterarch: ' .. clusterarch_short_maximal )
-- print( '- (get_clusterarch) Long maximal clusterarch:  ' .. clusterarch_long_maximal )

print()
