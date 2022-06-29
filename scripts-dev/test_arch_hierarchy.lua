#! /usr/bin/env lua

dofile( '../scripts/calcua_tools/lmod_emulation.lua' )

--
-- Instead of readint etc/SystemDefnition.lua. we use a test configuration
-- defined in this directory.
--

dofile( 'SystemDefinition_debug_1.lua' )

-- -----------------------------------------------------------------------------
--
-- Other included files
--

dofile( '../LMOD/SitePackage_helper.lua' )
dofile( '../LMOD/SitePackage_system_info.lua' )
dofile( '../LMOD/SitePackage_map_toolchain.lua' )
dofile( '../LMOD/SitePackage_arch_hierarchy.lua' )



-- -----------------------------------------------------------------------------
--
-- Some "constants"
--

local mssg_sysdep = '\27[34mSystem-dependend!\27[0m'
local colour_title = '\27[35m'
local colour_reset = '\27[0m'

local function testresult( result )

  if ( result ) then
      return '\27[32mOK!\27[0m '
  else
      return '\27[31mNOT OK!\27[0m '
  end

end

--
-- Testing extract_*(name) functions
--

print( colour_title .. '\nTesting extract_* functions\n' .. colour_reset )
local testtable = { 
    ['redhat8-zen2-arcturus'] = { ['OS'] = 'redhat8', ['CPU'] = 'zen2',   ['accel'] = 'arcturus', ['arch'] = 'zen2-arcturus' },
    ['redhat8-zen2-noaccel']  = { ['OS'] = 'redhat8', ['CPU'] = 'zen2',   ['accel'] = 'noaccel',  ['arch'] = 'zen2-noaccel' },
    ['redhat8-x86_64']        = { ['OS'] = 'redhat8', ['CPU'] = 'x86_64', ['accel'] = 'None',     ['arch'] = 'x86_64' },
} 
for longname,value in pairs(testtable) 
do 
    local found_os    = extract_os( longname )
    local found_cpu   = extract_cpu( longname )
    local found_accel = extract_accel( longname ) or 'None'
    local found_arch  = extract_arch( longname )
    
    print( testresult( found_os == testtable[longname]['OS'] and found_cpu == testtable[longname]['CPU'] and 
                       found_accel == testtable[longname]['accel'] and found_arch == testtable[longname]['arch'] )  .. 
           longname .. ': os is ' .. found_os ..
           ', CPU is ' .. found_cpu ..
           ', accelerator is ' .. found_accel ..
           ', arch is ' .. found_arch )
    
end


-- -----------------------------------------------------------------------------
--
-- Testing get_long_osarchs and get_long_osarchs_reverse
-- We do so for a 2L and a 3L toolchain.
--

print( colour_title .. '\ntesting get_long_osarch and get_long_osarch_reverse' .. colour_reset )

stack_versions = { '2020a', '3000a' }
for _, stack_version in ipairs( stack_versions ) do

    print( '\nHierarchy type of toolchain version ' .. stack_version.. ': ' .. 
           CalcUA_SystemProperties[stack_version]['hierarchy'] )

    osname   = 'redhat8'
    archname = 'x86_64'
    expected = { 
        ['2020a'] = 'redhat8-x86_64',
        ['3000a'] = 'redhat8-x86_64',
    }
    result = get_long_osarchs( stack_version, osname, archname )
    print( testresult( table.concat( result, ', ') == expected[stack_version] ) .. 
           'Arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )
    expected = { 
        ['2020a'] = 'redhat8-x86_64',
        ['3000a'] = 'redhat8-x86_64',
    }
    result = get_long_osarchs_reverse( stack_version, osname, archname )
    print( testresult( table.concat( result, ', ') == expected[stack_version] ) .. 
           'Reverse arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )

    osname   = 'redhat8'
    archname = 'zen2-noaccel'
    expected = { 
        ['2020a'] = 'redhat8-zen2-noaccel, redhat8-x86_64',
        ['3000a'] = 'redhat8-zen2-noaccel, redhat8-zen2, redhat8-x86_64',
    }
    result = get_long_osarchs( stack_version, osname, archname )
    print( testresult( table.concat( result, ', ') == expected[stack_version] ) .. 
           'Arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )
    expected = { 
        ['2020a'] = 'redhat8-x86_64, redhat8-zen2-noaccel',
        ['3000a'] = 'redhat8-x86_64, redhat8-zen2, redhat8-zen2-noaccel',
    }
    result = get_long_osarchs_reverse( stack_version, osname, archname )
    print( testresult( table.concat( result, ', ') == expected[stack_version] ) .. 
           'Reverse arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )

    osname   = 'redhat8'
    archname = 'zen2-arcturus'
    expected = { 
        ['2020a'] = 'redhat8-zen2-arcturus, redhat8-x86_64',
        ['3000a'] = 'redhat8-zen2-arcturus, redhat8-zen2, redhat8-x86_64',
    }
    result = get_long_osarchs( stack_version, osname, archname )
    print( testresult( table.concat( result, ', ') == expected[stack_version] ) .. 
           'Arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )
    expected = { 
        ['2020a'] = 'redhat8-x86_64, redhat8-zen2-arcturus',
        ['3000a'] = 'redhat8-x86_64, redhat8-zen2, redhat8-zen2-arcturus',
    }
    result = get_long_osarchs_reverse( stack_version, osname, archname )
    print( testresult( table.concat( result, ', ') == expected[stack_version] ) .. 
           'Reverse arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )

end

-- -----------------------------------------------------------------------------
--
-- Testing map_long_to_short
--

print( colour_title .. '\nTesting map_long_to_short\n' .. colour_reset )
local tests = { 
    ['redhat8-skylake-aurora1']   = 'RH8-SKLX-NEC1',
    ['redhat8-broadwell-noaccel'] = 'RH8-BRW-host',
    ['redhat8-ivybridge']         = 'RH8-IVB',
} 
for long,short in pairs( tests )
do
    local found_short = map_long_to_short( long )
    print( testresult( found_short == short )  .. long .. ' converts to ' .. found_short )
end

-- -----------------------------------------------------------------------------
--
-- Testing map_short_to_;long
--

print( colour_title .. '\nTesting map_short_to_long\n' .. colour_reset )
local tests = {
    ['RH8-SKLX-NEC1'] = 'redhat8-skylake-aurora1',
    ['RH8-BRW-host']  = 'redhat8-broadwell-noaccel',
    ['RH8-IVB']       = 'redhat8-ivybridge',
}
for short,long in pairs( tests )
do
    local found_long = map_short_to_long( short )
    print( testresult( found_long == long )  .. short .. ' converts to ' .. found_long )
end

-- -----------------------------------------------------------------------------
--
-- Testing get_calcua_generic
--

print( colour_title .. '\nTesting get_calcua_generic function\n' .. colour_reset )

local inputdata = {
    {   
       ['stack_version'] = '2021b',
       ['cluster_arch'] =  'redhat8-zen2-noaccel',
       ['expected'] =      'redhat8-x86_64',
    },
    {   
       ['stack_version'] = '2021b',
       ['cluster_arch'] =  'redhat8-zen2-arcturus',
       ['expected'] =      'redhat8-x86_64',
    },            
}

for index, data in ipairs( inputdata ) do
    local got = get_calcua_generic( data['cluster_arch'], data['stack_version'] )
    local expected = data['expected']
    print( testresult( got == expected ) .. 'Generic for ' .. data['cluster_arch'] ..
           ' in calcua/' .. data['stack_version'] .. ': ' ..
           got .. ', expected: ' .. data['expected'] )
end
              
-- -----------------------------------------------------------------------------
--
-- Testing get_calcua_top
--

print( colour_title .. '\nTesting get_calcua_top function\n' .. colour_reset )

local inputdata = {
    -- Manual test cases (2L)
    {   
        ['stack_version'] = 'manual',
        ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
        ['expected'] =      'redhat7-x86_64',
     },
     {   
        ['stack_version'] = 'manual',
        ['cluster_arch'] =  'redhat7-broadwell-noaccel',
        ['expected'] =      'redhat7-x86_64',
     },
     {   
        ['stack_version'] = 'manual',
        ['cluster_arch'] =  'redhat8-broadwell-noaccel',
        ['expected'] =      'redhat8-x86_64',
     },
     {   
        ['stack_version'] = 'manual',
        ['cluster_arch'] =  'redhat8-broadwell-pascal',
        ['expected'] =      'redhat8-x86_64',
     },
     {   
        ['stack_version'] = 'manual',
        ['cluster_arch'] =  'redhat8-broadwell-P5000',
        ['expected'] =      'redhat8-x86_64',
     },
     {   
        ['stack_version'] = 'manual',
        ['cluster_arch'] =  'redhat8-skylake-noaccel',
        ['expected'] =      'redhat8-x86_64',
     },
     {   
        ['stack_version'] = 'manual',
        ['cluster_arch'] =  'redhat8-skylake-aurora1',
        ['expected'] =      'redhat8-x86_64',
     },
     {   
        ['stack_version'] = 'manual',
        ['cluster_arch'] =  'redhat8-zen2-noaccel',
        ['expected'] =      'redhat8-x86_64',
     },
     {   
        ['stack_version'] = 'manual',
        ['cluster_arch'] =  'redhat8-zen2-ampere',
        ['expected'] =      'redhat8-x86_64',
     },
     {   
        ['stack_version'] = 'manual',
        ['cluster_arch'] =  'redhat8-zen2-arcturus',
        ['expected'] =      'redhat8-x86_64',
     },
     -- System test cases (2L)
     {   
         ['stack_version'] = 'system',
         ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
         ['expected'] =      'redhat7-x86_64',
      },
      {   
         ['stack_version'] = 'system',
         ['cluster_arch'] =  'redhat7-broadwell-noaccel',
         ['expected'] =      'redhat7-x86_64',
      },
      {   
         ['stack_version'] = 'system',
         ['cluster_arch'] =  'redhat8-broadwell-noaccel',
         ['expected'] =      'redhat8-broadwell-noaccel',
      },
      {   
         ['stack_version'] = 'system',
         ['cluster_arch'] =  'redhat8-broadwell-pascal',
         ['expected'] =      'redhat8-broadwell-noaccel',
      },
      {   
         ['stack_version'] = 'system',
         ['cluster_arch'] =  'redhat8-broadwell-P5000',
         ['expected'] =      'redhat8-broadwell-noaccel',
      },
      {   
         ['stack_version'] = 'system',
         ['cluster_arch'] =  'redhat8-skylake-noaccel',
         ['expected'] =      'redhat8-broadwell-noaccel',
      },
      {   
         ['stack_version'] = 'system',
         ['cluster_arch'] =  'redhat8-skylake-aurora1',
         ['expected'] =      'redhat8-broadwell-noaccel',
      },
      {   
         ['stack_version'] = 'system',
         ['cluster_arch'] =  'redhat8-zen2-noaccel',
         ['expected'] =      'redhat8-zen2-noaccel',
      },
      {   
         ['stack_version'] = 'system',
         ['cluster_arch'] =  'redhat8-zen2-ampere',
         ['expected'] =      'redhat8-zen2-noaccel',
      },
      {   
         ['stack_version'] = 'system',
         ['cluster_arch'] =  'redhat8-zen2-arcturus',
         ['expected'] =      'redhat8-zen2-noaccel',
      },
     -- 2020a test cases (2L)
     {   
        ['stack_version'] = '2020a',
        ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
        ['expected'] =      'redhat7-ivybridge-noaccel',
     },
     {   
        ['stack_version'] = '2020a',
        ['cluster_arch'] =  'redhat7-broadwell-noaccel',
        ['expected'] =      'redhat7-broadwell-noaccel',
     },
     {   
        ['stack_version'] = '2020a',
        ['cluster_arch'] =  'redhat8-broadwell-noaccel',
        ['expected'] =      'redhat8-x86_64',
     },
     {   
        ['stack_version'] = '2020a',
        ['cluster_arch'] =  'redhat8-broadwell-pascal',
        ['expected'] =      'redhat8-x86_64',
     },
     {   
        ['stack_version'] = '2020a',
        ['cluster_arch'] =  'redhat8-broadwell-P5000',
        ['expected'] =      'redhat8-x86_64',
     },
     {   
        ['stack_version'] = '2020a',
        ['cluster_arch'] =  'redhat8-skylake-noaccel',
        ['expected'] =      'redhat8-skylake-noaccel',
     },
     {   
        ['stack_version'] = '2020a',
        ['cluster_arch'] =  'redhat8-skylake-aurora1',
        ['expected'] =      'redhat8-skylake-noaccel',
     },
     {   
        ['stack_version'] = '2020a',
        ['cluster_arch'] =  'redhat8-zen2-noaccel',
        ['expected'] =      'redhat8-zen2-noaccel',
     },
     {   
        ['stack_version'] = '2020a',
        ['cluster_arch'] =  'redhat8-zen2-ampere',
        ['expected'] =      'redhat8-zen2-noaccel',
     },
     {   
        ['stack_version'] = '2020a',
        ['cluster_arch'] =  'redhat8-zen2-arcturus',
        ['expected'] =      'redhat8-zen2-noaccel',
     },
     -- 2021b test cases (2L)
     {   
        ['stack_version'] = '2021b',
        ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
        ['expected'] =      'redhat7-ivybridge-noaccel',
     },
     {   
        ['stack_version'] = '2021b',
        ['cluster_arch'] =  'redhat7-broadwell-noaccel',
        ['expected'] =      'redhat7-ivybridge-noaccel',
     },
     {   
        ['stack_version'] = '2021b',
        ['cluster_arch'] =  'redhat8-broadwell-noaccel',
        ['expected'] =      'redhat8-broadwell-noaccel',
     },
     {   
        ['stack_version'] = '2021b',
        ['cluster_arch'] =  'redhat8-broadwell-pascal',
        ['expected'] =      'redhat8-broadwell-noaccel',
     },
     {   
        ['stack_version'] = '2021b',
        ['cluster_arch'] =  'redhat8-broadwell-P5000',
        ['expected'] =      'redhat8-broadwell-noaccel',
     },
     {   
        ['stack_version'] = '2021b',
        ['cluster_arch'] =  'redhat8-skylake-noaccel',
        ['expected'] =      'redhat8-skylake-noaccel',
     },
     {   
        ['stack_version'] = '2021b',
        ['cluster_arch'] =  'redhat8-skylake-aurora1',
        ['expected'] =      'redhat8-skylake-noaccel',
     },
     {   
        ['stack_version'] = '2021b',
        ['cluster_arch'] =  'redhat8-zen2-noaccel',
        ['expected'] =      'redhat8-zen2-noaccel',
     },
     {   
        ['stack_version'] = '2021b',
        ['cluster_arch'] =  'redhat8-zen2-ampere',
        ['expected'] =      'redhat8-zen2-noaccel',
     },
     {   
        ['stack_version'] = '2021b',
        ['cluster_arch'] =  'redhat8-zen2-arcturus',
        ['expected'] =      'redhat8-zen2-arcturus',
     },
     -- 3000a test cases (3L)
     {   
        ['stack_version'] = '3000a',
        ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
        ['expected'] =      'redhat7-ivybridge-noaccel',
     },
     {   
        ['stack_version'] = '3000a',
        ['cluster_arch'] =  'redhat7-broadwell-noaccel',
        ['expected'] =      'redhat7-ivybridge-noaccel',
     },
     {   
        ['stack_version'] = '3000a',
        ['cluster_arch'] =  'redhat8-broadwell-noaccel',
        ['expected'] =      'redhat8-broadwell-noaccel',
     },
     {   
        ['stack_version'] = '3000a',
        ['cluster_arch'] =  'redhat8-broadwell-pascal',
        ['expected'] =      'redhat8-broadwell-noaccel',
     },
     {   
        ['stack_version'] = '3000a',
        ['cluster_arch'] =  'redhat8-broadwell-P5000',
        ['expected'] =      'redhat8-broadwell-noaccel',
     },
     {   
        ['stack_version'] = '3000a',
        ['cluster_arch'] =  'redhat8-skylake-noaccel',
        ['expected'] =      'redhat8-skylake-noaccel',
     },
     {   
        ['stack_version'] = '3000a',
        ['cluster_arch'] =  'redhat8-skylake-aurora1',
        ['expected'] =      'redhat8-skylake-noaccel',
     },
     {   
        ['stack_version'] = '3000a',
        ['cluster_arch'] =  'redhat8-zen2-noaccel',
        ['expected'] =      'redhat8-zen2-noaccel',
     },
     {   
        ['stack_version'] = '3000a',
        ['cluster_arch'] =  'redhat8-zen2-ampere',
        ['expected'] =      'redhat8-zen2-noaccel',
     },
     {   
        ['stack_version'] = '3000a',
        ['cluster_arch'] =  'redhat8-zen2-arcturus',
        ['expected'] =      'redhat8-zen2-arcturus',
     },
     -- 4000a test cases (3L)
     {   
        ['stack_version'] = '4000a',
        ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
        ['expected'] =      nil,
     },
     {   
        ['stack_version'] = '4000a',
        ['cluster_arch'] =  'redhat7-broadwell-noaccel',
        ['expected'] =      nil,
     },
     {   
        ['stack_version'] = '4000a',
        ['cluster_arch'] =  'redhat8-broadwell-noaccel',
        ['expected'] =      'redhat8-broadwell-noaccel',
     },
     {   
        ['stack_version'] = '4000a',
        ['cluster_arch'] =  'redhat8-broadwell-pascal',
        ['expected'] =      'redhat8-broadwell-noaccel',
     },
     {   
        ['stack_version'] = '4000a',
        ['cluster_arch'] =  'redhat8-broadwell-P5000',
        ['expected'] =      'redhat8-broadwell-noaccel',
     },
     {   
        ['stack_version'] = '4000a',
        ['cluster_arch'] =  'redhat8-skylake-noaccel',
        ['expected'] =      'redhat8-skylake-noaccel',
     },
     {   
        ['stack_version'] = '4000a',
        ['cluster_arch'] =  'redhat8-skylake-aurora1',
        ['expected'] =      'redhat8-skylake-noaccel',
     },
     {   
        ['stack_version'] = '4000a',
        ['cluster_arch'] =  'redhat8-zen2-noaccel',
        ['expected'] =      'redhat8-zen2-noaccel',
     },
     {   
        ['stack_version'] = '4000a',
        ['cluster_arch'] =  'redhat8-zen2-ampere',
        ['expected'] =      'redhat8-zen2-noaccel',
     },
     {   
        ['stack_version'] = '4000a',
        ['cluster_arch'] =  'redhat8-zen2-arcturus',
        ['expected'] =      'redhat8-zen2-arcturus',
     },
}

for index, data in ipairs( inputdata ) do
    local got = get_calcua_top( data['cluster_arch'], data['stack_version'] )
    local expected = data['expected']
    print( testresult( got == expected ) ..
           'Top architecture for ' .. data['cluster_arch'] .. ' in ' .. data['stack_version'] .. ' is ' ..
           ( got or 'nil' ) .. ', expected: ' .. ( data['expected'] or 'nil' ) )
end

-- -----------------------------------------------------------------------------
--
-- Testing get_system_module_dirs( longname, stack_name, stack_version )
-- and through it get_calcua_subarchs( longname, stack_version )
--

print( colour_title .. '\nTesting get_system_module_dirs and hence get_calcua_subarchs\n' .. colour_reset )

local tests = {
    -- system
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = 'system',
        ['longname'] =      'redhat7-x86_64',
        ['own_modules'] =   'modules-easybuild/system/redhat7-x86_64',
        ['full_modules'] =  'modules-easybuild/system/redhat7-x86_64'
    },
    {   -- This one should work as we must also be able to generate the module directories for subarchitectures.
        ['stack_name'] =    'calcua',
        ['stack_version'] = 'system',
        ['longname'] =      'redhat8-x86_64',
        ['own_modules'] =   'modules-easybuild/system/redhat8-x86_64',
        ['full_modules'] =  'modules-easybuild/system/redhat8-x86_64'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = 'system',
        ['longname'] =      'redhat8-broadwell-noaccel',
        ['own_modules'] =   'modules-easybuild/system/redhat8-broadwell-noaccel', -- system for redhat8 has specific CPU support
        ['full_modules'] =  'modules-easybuild/system/redhat8-x86_64,modules-easybuild/system/redhat8-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = 'system',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   'modules-easybuild/system/redhat8-zen2-noaccel', -- system for redhat8 has specific CPU support
        ['full_modules'] =  'modules-easybuild/system/redhat8-x86_64,modules-easybuild/system/redhat8-zen2-noaccel'
    },
    -- 2020a
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2020a',
        ['longname'] =      'redhat7-ivybridge-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-2020a/redhat7-ivybridge-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-2020a/redhat7-x86_64,modules-easybuild/CalcUA-2020a/redhat7-ivybridge-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2020a',
        ['longname'] =      'redhat7-broadwell-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-2020a/redhat7-broadwell-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-2020a/redhat7-x86_64,modules-easybuild/CalcUA-2020a/redhat7-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2020a',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-2020a/redhat8-zen2-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-2020a/redhat8-x86_64,modules-easybuild/CalcUA-2020a/redhat8-zen2-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2020a',
        ['longname'] =      'redhat8-skylake-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-2020a/redhat8-skylake-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-2020a/redhat8-x86_64,modules-easybuild/CalcUA-2020a/redhat8-skylake-noaccel'
    },
    -- 2021b
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat7-ivybridge-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-2021b/redhat7-ivybridge-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-2021b/redhat7-x86_64,modules-easybuild/CalcUA-2021b/redhat7-ivybridge-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat8-broadwell-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-2021b/redhat8-broadwell-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-2021b/redhat8-x86_64,modules-easybuild/CalcUA-2021b/redhat8-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat8-zen2-arcturus',
        ['own_modules'] =   'modules-easybuild/CalcUA-2021b/redhat8-zen2-arcturus',
        ['full_modules'] =  'modules-easybuild/CalcUA-2021b/redhat8-x86_64,modules-easybuild/CalcUA-2021b/redhat8-zen2-arcturus'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-2021b/redhat8-zen2-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-2021b/redhat8-x86_64,modules-easybuild/CalcUA-2021b/redhat8-zen2-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat8-skylake-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-2021b/redhat8-skylake-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-2021b/redhat8-x86_64,modules-easybuild/CalcUA-2021b/redhat8-skylake-noaccel'
    },
    -- 3000a
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat7-ivybridge-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-3000a/redhat7-ivybridge-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-3000a/redhat7-x86_64,modules-easybuild/CalcUA-3000a/redhat7-ivybridge,modules-easybuild/CalcUA-3000a/redhat7-ivybridge-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat8-broadwell-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-3000a/redhat8-broadwell-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-3000a/redhat8-x86_64,modules-easybuild/CalcUA-3000a/redhat8-broadwell,modules-easybuild/CalcUA-3000a/redhat8-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat8-zen2-arcturus',
        ['own_modules'] =   'modules-easybuild/CalcUA-3000a/redhat8-zen2-arcturus',
        ['full_modules'] =  'modules-easybuild/CalcUA-3000a/redhat8-x86_64,modules-easybuild/CalcUA-3000a/redhat8-zen2,modules-easybuild/CalcUA-3000a/redhat8-zen2-arcturus'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-3000a/redhat8-zen2-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-3000a/redhat8-x86_64,modules-easybuild/CalcUA-3000a/redhat8-zen2,modules-easybuild/CalcUA-3000a/redhat8-zen2-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat8-skylake-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-3000a/redhat8-skylake-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-3000a/redhat8-x86_64,modules-easybuild/CalcUA-3000a/redhat8-skylake,modules-easybuild/CalcUA-3000a/redhat8-skylake-noaccel'
    },
    -- 4000a
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-broadwell-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-4000a/redhat8-broadwell-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-4000a/redhat8-x86_64,modules-easybuild/CalcUA-4000a/redhat8-broadwell,modules-easybuild/CalcUA-4000a/redhat8-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-zen2-arcturus',
        ['own_modules'] =   'modules-easybuild/CalcUA-4000a/redhat8-zen2-arcturus',
        ['full_modules'] =  'modules-easybuild/CalcUA-4000a/redhat8-x86_64,modules-easybuild/CalcUA-4000a/redhat8-zen2,modules-easybuild/CalcUA-4000a/redhat8-zen2-arcturus'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-4000a/redhat8-zen2-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-4000a/redhat8-x86_64,modules-easybuild/CalcUA-4000a/redhat8-zen2,modules-easybuild/CalcUA-4000a/redhat8-zen2-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-skylake-noaccel',
        ['own_modules'] =   'modules-easybuild/CalcUA-4000a/redhat8-skylake-noaccel',
        ['full_modules'] =  'modules-easybuild/CalcUA-4000a/redhat8-x86_64,modules-easybuild/CalcUA-4000a/redhat8-skylake,modules-easybuild/CalcUA-4000a/redhat8-skylake-noaccel'
    },
    -- Cases that should print error messages.
    { 
      ['stack_name'] =    'calcua',
      ['stack_version'] = 'system',
      ['longname'] =      'redhat7-broadwell-noaccel',
      ['own_modules'] =   nil, -- system for redhat7 exists only in an x86_64 version.
      ['full_modules'] =  nil
    },
    { 
      ['stack_name'] =    'calcua',
      ['stack_version'] = 'system',
      ['longname'] =      'redhat8-zen2-arcturus',
      ['own_modules'] =   nil, -- system for redhat8 has specific CPU support but no GPU support.
      ['full_modules'] =  nil
    },
} 

for _,test in ipairs( tests )
do
    local hierarchy =          CalcUA_SystemProperties[test['stack_version']]['hierarchy'] 
    local system_module_dir =  get_system_module_dir(  test['longname'], test['stack_name'], test['stack_version'] )
    local system_module_dirs = get_system_module_dirs( test['longname'], test['stack_name'], test['stack_version'] )
    local string_system_module_dirs
    if system_module_dirs == nil then
        string_system_module_dirs = nil
    else
        string_system_module_dirs = table.concat( system_module_dirs, ',')
    end
    print( testresult( system_module_dir == test['own_modules'] and string_system_module_dirs == test['full_modules'] ) ..
           'Modules of ' .. test['stack_name'] .. '/' .. test['stack_version'] ..
           ' (' .. hierarchy .. ') for arch ' .. test['longname'] .. 
           ' are in \n      ' .. ( system_module_dir or 'nil' ) )
           
    if system_module_dirs == nil then
        print(  '    Full hierarchy (lowest priority first):\n      nil' )
    else
        print(  '    Full hierarchy (lowest priority first):\n      ' ..
                table.concat( system_module_dirs, '\n      ') )
    end
    if system_module_dir ~= test['own_modules'] then
        print( '    Expected module dir: ' .. ( test['own_modules'] or 'nil' )  )
    end
    if string_system_module_dirs ~= test['full_modules'] then
        print( '    Expected full hierarchy: ' .. (test['full_modules'] or ''):gsub(',', ', ') )
    end
    print( '\n' )
         
end

--
-- Special case
-- 
stack_name =    'manual'
stack_version = ''
longname = 'redhat8-zen2-arcturus'
result = get_system_module_dirs( longname, stack_name, stack_version )
if result == nil then
    print( testresult( result == nil )  .. 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' returned nil as expected.\n' )
else
    print( testresult( result == nil )  .. 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' \27[31mDID NOT RETURN NIL!\27[0m\n' )
end


-- -----------------------------------------------------------------------------
--
-- Testing get_system_inframodule_dir() longname, stack_name, stack_version )
--

print( colour_title .. '\nTesting get_system_inframodule_dirs\n' .. colour_reset )

tests = {
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = 'modules-infrastructure/infrastructure/CalcUA-2021b/redhat8-zen2-arcturus',
    },
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-x86_64',
        ['expected']      = 'modules-infrastructure/infrastructure/CalcUA-2021b/redhat8-x86_64',
    },
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = 'system',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = 'modules-infrastructure/infrastructure/system/redhat8-zen2-arcturus',
    },
    {
        ['stack_name']    = 'manual',
        ['stack_version'] = '',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = nil,
    },
}

for _,test in ipairs( tests )
do
    local got = get_system_inframodule_dir( test['longname'], test['stack_name'], test['stack_version'] )
    print( testresult( got == test['expected']  ) ..
           'Modules of ' .. test['stack_name'] .. '/' .. test['stack_version'] .. ' for arch ' .. test['longname'] .. ' are in \n  ' .. ( got or 'NIL' )  ..'\n' )
end


-- -----------------------------------------------------------------------------
--
-- Testing get_system_SW_dir() longname, stack_name, stack_version )
--

print( colour_title .. '\nTesting get_system_SW_dirs\n' .. colour_reset )

tests = {
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = 'SW/CalcUA-2021b/RH8-zen2-GFX908',
    },
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-x86_64',
        ['expected']      = 'SW/CalcUA-2021b/RH8-x86_64',
    },
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = 'system',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = 'SW/system/RH8-zen2-GFX908',
    },
    {
        ['stack_name']    = 'manual',
        ['stack_version'] = '',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = 'SW/MNL/RH8-zen2-GFX908',
    },
}

for _,test in ipairs( tests )
do
    local got = get_system_SW_dir( test['longname'], test['stack_name'], test['stack_version'] )
    print( testresult( got == test['expected']  ) ..
           'Modules of ' .. test['stack_name'] .. '/' .. test['stack_version'] .. ' for arch ' .. test['longname'] .. ' are in \n  ' .. ( got or 'NIL' )  ..'\n' )
end


-- -----------------------------------------------------------------------------
--
-- Testing get_system_EBrepo_dir( longname, stack_name, stack_version )
--

print( colour_title .. '\nTesting get_system_EBrepo_dirs\n' .. colour_reset )

tests = {
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = 'EBrepo_files/CalcUA-2021b/redhat8-zen2-arcturus',
    },
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-x86_64',
        ['expected']      = 'EBrepo_files/CalcUA-2021b/redhat8-x86_64',
    },
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = 'system',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = 'EBrepo_files/system/redhat8-zen2-arcturus',
    },
    {
        ['stack_name']    = 'manual',
        ['stack_version'] = '',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = nil,
    },
}

for _,test in ipairs( tests )
do
    local got = get_system_EBrepo_dir( test['longname'], test['stack_name'], test['stack_version'] )
    print( testresult( got == test['expected']  ) ..
           'Modules of ' .. test['stack_name'] .. '/' .. test['stack_version'] .. ' for arch ' .. test['longname'] .. ' are in \n  ' .. ( got or 'NIL' )  ..'\n' )
end


-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
--
-- Testing specific for the current cluster, so no way to check the results automatically
--

print( colour_title .. '\nTESTING CURRENT CLUSTER\n========================' .. colour_reset )

-- -----------------------------------------------------------------------------
--
-- Testing get_calcua_generic_current
--

print( colour_title .. '\nTesting get_calcua_generic_current function\n' .. colour_reset )

for stack,_ in pairs( CalcUA_SystemTable ) do
       print( mssg_sysdep .. ' Generic for ' .. stack .. ' on the current node: ' .. get_calcua_generic_current( stack ) )
end
              
-- -----------------------------------------------------------------------------
--
-- Testing get_calcua_longosarch_current
--

print( colour_title .. '\nTesting get_calcua_longosarch_current function\n' .. colour_reset )

for stack,_ in pairs( CalcUA_SystemTable ) do
    local hierarchy = CalcUA_SystemProperties[stack]['hierarchy'] 
    print( mssg_sysdep .. ' Architecture of the current node in the format for ' .. stack .. 
           ' (' .. hierarchy .. '): ' ..
           get_calcua_longosarch_current( stack ) )
end

-- -----------------------------------------------------------------------------
--
-- Testing get_calcua_top with get_cluster_longosarch
--

print( colour_title .. '\nTesting get_calcua_top function with get_cluster_longosarch\n' .. colour_reset )

local inputdata = {
    {   
       ['stack_version'] = '2020a',
       ['cluster_arch'] =  'redhat8-zen2-noaccel',
       ['expected'] =      'redhat8-zen2-noaccel',
    },
    {   
       ['stack_version'] = '2020a',
       ['cluster_arch'] =  'redhat8-zen2-arcturus',
       ['expected'] =      'redhat8-zen2-noaccel',
    },            
}

for stack,_ in pairs( CalcUA_SystemTable ) do
    local hierarchy = CalcUA_SystemProperties[stack]['hierarchy'] 
    local current_osarch = get_cluster_longosarch()
    print( mssg_sysdep .. ' Used architecture for ' .. current_osarch  .. 
           ' (this node) for ' .. stack .. ' (' .. hierarchy .. '): ' .. 
           ( get_calcua_top( current_osarch, stack ) or '\27[31mPROBLEM, GOT NIL\27[0m' ) )
end
       

