dofile( 'test_import_from_lua.lua' )
dofile( '../LMOD/SitePackage_arch_hierarchy.lua' )

--
-- Testing get_long_osarchs and get_long_osarchs_reverse
--

print( '\ntesting get_long_osarch and get_long_osarch_reverse' )

osname = 'redhat8'
archname = 'x86_64'
result = get_long_osarchs( osname, archname )
print( 'Arch chain for ' .. archname .. ' on ' .. osname .. ' is ' .. table.concat( result, ', ') )
result = get_long_osarchs_reverse( osname, archname )
print( 'Reverse arch chain for ' .. archname .. ' on ' .. osname .. ' is ' .. table.concat( result, ', ') )

osname = 'redhat8'
archname = 'zen2-arcturus'
result = get_long_osarchs( osname, archname )
print( 'Arch chain for ' .. archname .. ' on ' .. osname .. ' is ' .. table.concat( result, ', ') )
result = get_long_osarchs_reverse( osname, archname )
print( 'Reverse arch chain for ' .. archname .. ' on ' .. osname .. ' is ' .. table.concat( result, ', ') )

--
-- Testing map_long_to_short
--

print( '\nTesting map_long_to_short' )
long = 'redhat8-skylake-aurora1'
print( long .. ' converts to ' .. map_long_to_short( long ) )
long = 'redhat8-broadwell-noaccel'
print( long .. ' converts to ' .. map_long_to_short( long ) )
long = 'redhat8-ivybridge'
print( long .. ' converts to ' .. map_long_to_short( long ) )

--
-- Testing map_short_to_;long
--

print( '\nTesting map_short_to_long' )
long = 'RH8-SKLX-NEC1'
print( long .. ' converts to ' .. map_short_to_long( long ) )
long = 'RH8-BRW-host'
print( long .. ' converts to ' .. map_short_to_long( long ) )
long = 'RH8-IVB'
print( long .. ' converts to ' .. map_short_to_long( long ) )

