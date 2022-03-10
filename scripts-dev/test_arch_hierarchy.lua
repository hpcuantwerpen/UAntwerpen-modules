#! /usr/bin/env lua

dofile( '../scripts/calcua_tools/lmod_emulation.lua' )
dofile( '../etc/SystemDefinition.lua' )
dofile( '../LMOD/SitePackage_helper.lua' )
dofile( '../LMOD/SitePackage_map_toolchain.lua' )
dofile( '../LMOD/SitePackage_arch_hierarchy.lua' )

--
-- Testing get_long_osarchs and get_long_osarchs_reverse
--

print( '\ntesting get_long_osarch and get_long_osarch_reverse\n' )

stack_version = '202001'
osname = 'redhat8'
archname = 'x86_64'
result = get_long_osarchs( stack_version, osname, archname )
print( 'Arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )
result = get_long_osarchs_reverse( stack_version, osname, archname )
print( 'Reverse arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )

osname = 'redhat8'
archname = 'zen2-arcturus'
result = get_long_osarchs( stack_version, osname, archname )
print( 'Arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )
result = get_long_osarchs_reverse( stack_version, osname, archname )
print( 'Reverse arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )

--
-- Testing map_long_to_short
--

print( '\nTesting map_long_to_short\n' )
long = 'redhat8-skylake-aurora1'
print( long .. ' converts to ' .. map_long_to_short( long ) )
long = 'redhat8-broadwell-noaccel'
print( long .. ' converts to ' .. map_long_to_short( long ) )
long = 'redhat8-ivybridge'
print( long .. ' converts to ' .. map_long_to_short( long ) )

--
-- Testing map_short_to_;long
--

print( '\nTesting map_short_to_long\n' )
long = 'RH8-SKLX-NEC1'
print( long .. ' converts to ' .. map_short_to_long( long ) )
long = 'RH8-BRW-host'
print( long .. ' converts to ' .. map_short_to_long( long ) )
long = 'RH8-IVB'
print( long .. ' converts to ' .. map_short_to_long( long ) )

--
-- Testing extract_*(name) functions
--

print( '\nTesting extract_* functions\n' )
for index, longname in ipairs( { 'redhat8-zen2-arcturus', 'redhat8-x86_64' } )
do
    print( longname .. ': os is ' .. extract_os( longname ) ..
            ', CPU is ' .. extract_cpu( longname ) ..
            ', accelerator is ' .. ( extract_accel( longname ) or '' ) ..
            ', arch is ' .. extract_arch( longname ) )
end

--
-- Testing get_system_module_dirs( longname, stack_name, stack_version )
--

print( '\nTesting get_system_module_dirs\n' )

stack_name =    'calcua'
stack_version = '2021b'
longname = 'redhat8-zen2-arcturus'
result = get_system_module_dirs( longname, stack_name, stack_version )
print( 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_module_dir( longname, stack_name, stack_version ) ..
       '\nFull hierarchy (lowest priority first):\n  ' ..
       table.concat( result, '\n  ') .. '\n' )

stack_name =    'calcua'
stack_version = '2021b'
longname = 'redhat8-x86_64'
result = get_system_module_dirs( longname, stack_name, stack_version )
print( 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_module_dir( longname, stack_name, stack_version ) ..
       '\nFull hierarchy (lowest priority first):\n  ' ..
       table.concat( result, '\n  ') .. '\n' )

stack_name =    'calcua'
stack_version = 'system'
longname = 'redhat8-zen2-arcturus'
result = get_system_module_dirs( longname, stack_name, stack_version )
print( 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_module_dir( longname, stack_name, stack_version ) ..
       '\nFull hierarchy (lowest priority first):\n  ' ..
       table.concat( result, '\n  ') .. '\n' )

stack_name =    'manual'
stack_version = ''
longname = 'redhat8-zen2-arcturus'
result = get_system_module_dirs( longname, stack_name, stack_version )
print( 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_module_dir( longname, stack_name, stack_version ) ..
       '\nFull hierarchy (lowest priority first):\n  ' ..
       table.concat( result, '\n  ') .. '\n' )

