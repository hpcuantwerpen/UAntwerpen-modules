#! /usr/bin/env lua

dofile( '../scripts/calcua_tools/lmod_emulation.lua' )
dofile( '../etc/SystemDefinition.lua' )
dofile( '../LMOD/SitePackage_system_info.lua' )

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
print( '- Long minimal clusterarch:  ' .. clusterarch_long_maximal )
print( '- Short maximal clusterarch: ' .. clusterarch_short_minimal )
print( '- Long maximal clusterarch:  ' .. clusterarch_long_maximal )
  

