#! /usr/bin/env lua

dofile( '../scripts/ClusterMod_tools/lmod_emulation.lua' )

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

    local found_cpu_from_arch = extract_cpu_from_arch( found_arch )
    local found_accel_from_arch = extract_accel_from_arch( found_arch ) or 'None'
    
    print( testresult( found_os == testtable[longname]['OS'] and found_cpu == testtable[longname]['CPU'] and 
                       found_accel == testtable[longname]['accel'] and found_arch == testtable[longname]['arch'] and
                       found_cpu_from_arch == testtable[longname]['CPU'] and found_accel_from_arch == testtable[longname]['accel'] )  .. 
           longname .. ': os is ' .. found_os ..
           ', CPU is ' .. found_cpu .. ' and from arch ' .. found_cpu_from_arch ..
           ', accelerator is ' .. found_accel .. ' and from arch ' .. found_accel_from_arch .. 
           ', arch is ' .. found_arch )
    
end


-- -----------------------------------------------------------------------------
--
-- Testing get_osarchs and get_osarchs_reverse
-- We do so for a 2L and a 3L toolchain.
--

print( colour_title .. '\ntesting get_osarchs and get_osarchs_reverse' .. colour_reset )

stack_versions = { '2020a', '3000a' }
for _, stack_version in ipairs( stack_versions ) do

    print( '\nHierarchy type of toolchain version ' .. stack_version.. ': ' .. 
           ClusterMod_SystemProperties[stack_version]['hierarchy'] )

    osname   = 'redhat8'
    archname = 'x86_64'
    expected = { 
        ['2020a'] = 'redhat8-x86_64',
        ['3000a'] = 'redhat8-x86_64',
    }
    result = get_osarchs( stack_version, osname, archname )
    print( testresult( table.concat( result, ', ') == expected[stack_version] ) .. 
           'Arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )
    expected = { 
        ['2020a'] = 'redhat8-x86_64',
        ['3000a'] = 'redhat8-x86_64',
    }
    result = get_osarchs_reverse( stack_version, osname, archname )
    print( testresult( table.concat( result, ', ') == expected[stack_version] ) .. 
           'Reverse arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )

    osname   = 'redhat8'
    archname = 'zen2-noaccel'
    expected = { 
        ['2020a'] = 'redhat8-zen2-noaccel, redhat8-x86_64',
        ['3000a'] = 'redhat8-zen2-noaccel, redhat8-zen2, redhat8-x86_64',
    }
    result = get_osarchs( stack_version, osname, archname )
    print( testresult( table.concat( result, ', ') == expected[stack_version] ) .. 
           'Arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )
    expected = { 
        ['2020a'] = 'redhat8-x86_64, redhat8-zen2-noaccel',
        ['3000a'] = 'redhat8-x86_64, redhat8-zen2, redhat8-zen2-noaccel',
    }
    result = get_osarchs_reverse( stack_version, osname, archname )
    print( testresult( table.concat( result, ', ') == expected[stack_version] ) .. 
           'Reverse arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )

    osname   = 'redhat8'
    archname = 'zen2-arcturus'
    expected = { 
        ['2020a'] = 'redhat8-zen2-arcturus, redhat8-x86_64',
        ['3000a'] = 'redhat8-zen2-arcturus, redhat8-zen2, redhat8-x86_64',
    }
    result = get_osarchs( stack_version, osname, archname )
    print( testresult( table.concat( result, ', ') == expected[stack_version] ) .. 
           'Arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )
    expected = { 
        ['2020a'] = 'redhat8-x86_64, redhat8-zen2-arcturus',
        ['3000a'] = 'redhat8-x86_64, redhat8-zen2, redhat8-zen2-arcturus',
    }
    result = get_osarchs_reverse( stack_version, osname, archname )
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
-- Testing get_stack_generic
--

print( colour_title .. '\nTesting get_stack_generic function\n' .. colour_reset )

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
    local got = get_stack_generic( data['cluster_arch'], data['stack_version'] )
    local expected = data['expected']
    print( testresult( got == expected ) .. 'Generic for ' .. data['cluster_arch'] ..
           ' in calcua/' .. data['stack_version'] .. ': ' ..
           got .. ', expected: ' .. data['expected'] )
end
              
-- -----------------------------------------------------------------------------
--
-- Testing get_stack_top
--

print( colour_title .. '\nTesting get_stack_top function\n' .. colour_reset )

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
        ['cluster_arch'] =  'redhat7-x86_64',
        ['expected'] =      'redhat7-x86_64',
    },
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
    local got = get_stack_top( data['cluster_arch'], data['stack_version'] )
    local expected = data['expected']
    print( testresult( got == expected ) ..
           'Top architecture for ' .. data['cluster_arch'] .. ' in ' .. data['stack_version'] .. ' is ' ..
           ( got or 'nil' ) .. ', expected: ' .. ( data['expected'] or 'nil' ) )
end

-- -----------------------------------------------------------------------------
--
-- Testing get_stack_matchingarch
--

print( colour_title .. '\nTesting get_stack_matchingarch function\n' .. colour_reset )

local inputdata = {
   -- Manual test cases (2L)
   {   
      ['stack_version'] = 'manual',
      ['red_version'] =   'manual',
      ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
      ['expected'] =      'redhat7-x86_64',
   },
   {   
      ['stack_version'] = 'manual',
      ['red_version'] =   'manual',
      ['cluster_arch'] =  'redhat7-broadwell-noaccel',
      ['expected'] =      'redhat7-x86_64',
   },
   {   
      ['stack_version'] = 'manual',
      ['red_version'] =   'manual',
      ['cluster_arch'] =  'redhat8-broadwell-noaccel',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = 'manual',
      ['red_version'] =   'manual',
      ['cluster_arch'] =  'redhat8-broadwell-pascal',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = 'manual',
      ['red_version'] =   'manual',
      ['cluster_arch'] =  'redhat8-broadwell-P5000',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = 'manual',
      ['red_version'] =   'manual',
      ['cluster_arch'] =  'redhat8-skylake-noaccel',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = 'manual',
      ['red_version'] =   'manual',
      ['cluster_arch'] =  'redhat8-skylake-aurora1',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = 'manual',
      ['red_version'] =   'manual',
      ['cluster_arch'] =  'redhat8-zen2-noaccel',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = 'manual',
      ['red_version'] =   'manual',
      ['cluster_arch'] =  'redhat8-zen2-ampere',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = 'manual',
      ['red_version'] =   'manual',
      ['cluster_arch'] =  'redhat8-zen2-arcturus',
      ['expected'] =      'redhat8-x86_64',
   },
   -- System test cases (2L)
   {   
         ['stack_version'] = 'system',
         ['red_version'] =   'system',
         ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
         ['expected'] =      'redhat7-x86_64',
      },
      {   
         ['stack_version'] = 'system',
         ['red_version'] =   'system',
         ['cluster_arch'] =  'redhat7-broadwell-noaccel',
         ['expected'] =      'redhat7-x86_64',
      },
      {   
         ['stack_version'] = 'system',
         ['red_version'] =   'system',
         ['cluster_arch'] =  'redhat8-broadwell-noaccel',
         ['expected'] =      'redhat8-broadwell-noaccel',
      },
      {   
         ['stack_version'] = 'system',
         ['red_version'] =   'system',
         ['cluster_arch'] =  'redhat8-broadwell-pascal',
         ['expected'] =      'redhat8-broadwell-noaccel',
      },
      {   
         ['stack_version'] = 'system',
         ['red_version'] =   'system',
         ['cluster_arch'] =  'redhat8-broadwell-P5000',
         ['expected'] =      'redhat8-broadwell-noaccel',
      },
      {   
         ['stack_version'] = 'system',
         ['red_version'] =   'system',
         ['cluster_arch'] =  'redhat8-skylake-noaccel',
         ['expected'] =      'redhat8-broadwell-noaccel',
      },
      {   
         ['stack_version'] = 'system',
         ['red_version'] =   'system',
         ['cluster_arch'] =  'redhat8-skylake-aurora1',
         ['expected'] =      'redhat8-broadwell-noaccel',
      },
      {   
         ['stack_version'] = 'system',
         ['red_version'] =   'system',
         ['cluster_arch'] =  'redhat8-zen2-noaccel',
         ['expected'] =      'redhat8-zen2-noaccel',
      },
      {   
         ['stack_version'] = 'system',
         ['red_version'] =   'system',
         ['cluster_arch'] =  'redhat8-zen2-ampere',
         ['expected'] =      'redhat8-zen2-noaccel',
      },
      {   
         ['stack_version'] = 'system',
         ['red_version'] =   'system',
         ['cluster_arch'] =  'redhat8-zen2-arcturus',
         ['expected'] =      'redhat8-zen2-noaccel',
      },
   -- 2020a test cases (2L)
   {   
      ['stack_version'] = '2020a',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
      ['expected'] =      'redhat7-ivybridge-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
      ['expected'] =      'redhat7-x86_64',
   },
   {   
      ['stack_version'] = '2020a',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat7-broadwell-noaccel',
      ['expected'] =      'redhat7-broadwell-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat7-broadwell-noaccel',
      ['expected'] =      'redhat7-x86_64',
   },
   {   
      ['stack_version'] = '2020a',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-broadwell-noaccel',
      ['expected'] =      'redhat8-x86_64',
   },
   {   -- Irrelevant case in practice as there will be no redhat8-broadwell-noaccel arch module for calcua/2020a.
      ['stack_version'] = 'system',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-broadwell-noaccel',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '2020a',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-broadwell-pascal',
      ['expected'] =      'redhat8-x86_64',
   },
   {  -- Irrelevant case in practice as there will be no redhat8-broadwell-pascal or redhat8-broadwell-noaccel arch module for calcua/2020a.
      ['stack_version'] = 'system',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-broadwell-pascal',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '2020a',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-broadwell-P5000',
      ['expected'] =      'redhat8-x86_64',
   },
   {  -- Irrelevant case in practice as there will be no redhat8-broadwell-P5000 or redhat8-broadwell-noaccel arch module for calcua/2020a.  
      ['stack_version'] = 'system',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-broadwell-P5000',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '2020a',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-skylake-noaccel',
      ['expected'] =      'redhat8-skylake-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-skylake-noaccel',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '2020a',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-skylake-aurora1',
      ['expected'] =      'redhat8-skylake-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-skylake-aurora1',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '2020a',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-zen2-noaccel',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-zen2-noaccel',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = '2020a',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-zen2-ampere',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-zen2-ampere',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = '2020a',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-zen2-arcturus',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2020a',
      ['cluster_arch'] =  'redhat8-zen2-arcturus',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   -- 2021b test cases (2L)
   {   
      ['stack_version'] = '2021b',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
      ['expected'] =      'redhat7-ivybridge-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
      ['expected'] =      'redhat7-x86_64',
   },
   {   
      ['stack_version'] = '2021b',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat7-broadwell-noaccel',
      ['expected'] =      'redhat7-ivybridge-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat7-broadwell-noaccel',
      ['expected'] =      'redhat7-x86_64',
   },
   {   
      ['stack_version'] = '2021b',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-broadwell-noaccel',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-broadwell-noaccel',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '2021b',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-broadwell-pascal',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-broadwell-pascal',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '2021b',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-broadwell-P5000',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-broadwell-P5000',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '2021b',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-skylake-noaccel',
      ['expected'] =      'redhat8-skylake-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-skylake-noaccel',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '2021b',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-skylake-aurora1',
      ['expected'] =      'redhat8-skylake-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-skylake-aurora1',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '2021b',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-zen2-noaccel',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {
      ['stack_version'] = 'system',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-zen2-noaccel',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = '2021b',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-zen2-ampere',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-zen2-ampere',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = '2021b',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-zen2-arcturus',
      ['expected'] =      'redhat8-zen2-arcturus',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '2021b',
      ['cluster_arch'] =  'redhat8-zen2-arcturus',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   -- 3000a test cases (3L)
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
      ['expected'] =      'redhat7-ivybridge-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
      ['expected'] =      'redhat7-x86_64',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat7-ivybridge',
      ['expected'] =      'redhat7-ivybridge',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat7-ivybridge',
      ['expected'] =      'redhat7-x86_64',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat7-x86_64',
      ['expected'] =      'redhat7-x86_64',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat7-x86_64',
      ['expected'] =      'redhat7-x86_64',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat7-broadwell-noaccel',
      ['expected'] =      'redhat7-ivybridge-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat7-broadwell-noaccel',
      ['expected'] =      'redhat7-x86_64',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat7-broadwell',
      ['expected'] =      'redhat7-ivybridge',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat7-broadwell',
      ['expected'] =      'redhat7-x86_64',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-x86_64',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-x86_64',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-broadwell',
      ['expected'] =      'redhat8-broadwell',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-broadwell',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-broadwell-noaccel',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-broadwell-noaccel',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-broadwell-pascal',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-broadwell-pascal',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-broadwell-P5000',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-broadwell-P5000',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-skylake',
      ['expected'] =      'redhat8-skylake',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-skylake',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-skylake-noaccel',
      ['expected'] =      'redhat8-skylake-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-skylake-noaccel',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-skylake-aurora1',
      ['expected'] =      'redhat8-skylake-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-skylake-aurora1',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-zen2',
      ['expected'] =      'redhat8-zen2',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-zen2',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-zen2-noaccel',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-zen2-noaccel',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-zen2-ampere',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-zen2-ampere',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = '3000a',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-zen2-arcturus',
      ['expected'] =      'redhat8-zen2-arcturus',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '3000a',
      ['cluster_arch'] =  'redhat8-zen2-arcturus',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   -- 4000a test cases (3L)
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
      ['expected'] =      nil,
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat7-ivybridge-noaccel',
      ['expected'] =      nil,
   },
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat7-broadwell-noaccel',
      ['expected'] =      nil,
   },
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-x86_64',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-x86_64',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-broadwell',
      ['expected'] =      'redhat8-broadwell',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-broadwell',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-broadwell-noaccel',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-broadwell-noaccel',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-broadwell-pascal',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-broadwell-pascal',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-broadwell-P5000',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-broadwell-P5000',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-skylake',
      ['expected'] =      'redhat8-skylake',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-skylake',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-skylake-noaccel',
      ['expected'] =      'redhat8-skylake-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-skylake-noaccel',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-skylake-aurora1',
      ['expected'] =      'redhat8-skylake-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-skylake-aurora1',
      ['expected'] =      'redhat8-broadwell-noaccel',
   },
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-zen2',
      ['expected'] =      'redhat8-zen2',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-zen2',
      ['expected'] =      'redhat8-x86_64',
   },
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-zen2-noaccel',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   'system',
      ['cluster_arch'] =  'redhat8-zen2-noaccel',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-zen2-ampere',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-zen2-ampere',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
   {   
      ['stack_version'] = '4000a',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-zen2-arcturus',
      ['expected'] =      'redhat8-zen2-arcturus',
   },
   {   
      ['stack_version'] = 'system',
      ['red_version'] =   '4000a',
      ['cluster_arch'] =  'redhat8-zen2-arcturus',
      ['expected'] =      'redhat8-zen2-noaccel',
   },
}

for index, data in ipairs( inputdata ) do
   local got = get_stack_matchingarch( data['cluster_arch'], data['red_version'], data['stack_version'] )
   local expected = data['expected']
   print( testresult( got == expected ) ..
         'Matching architecture for ' .. data['cluster_arch'] .. ' for ' .. data['stack_version'] .. 
         ' in calcua/' .. data['red_version'] .. ' is ' ..
         ( got or 'nil' ) .. ', expected: ' .. ( data['expected'] or 'nil' ) )
end
    
-- -----------------------------------------------------------------------------
--
-- Testing get_stack_EasyBuild_version
--

print( colour_title .. '\nTesting get_stack_EasyBuild_version\n' .. colour_reset )

local inputdata = {
    {   
        ['stack_version'] = 'system',
        ['expected'] =      '4.5.3',
     },
     {   
        ['stack_version'] = '2020a',
        ['expected'] =      '4.2.2',
     },
     {   
        ['stack_version'] = '2021b',
        ['expected'] =      '4.5.3',
     },
     {   
        ['stack_version'] = '3000a',
        ['expected'] =      '4.5.3',
     },
     {   
        ['stack_version'] = '4000a',
        ['expected'] =      '4.5.3',
     },
     {   
        ['stack_version'] = '5000a',
        ['expected'] =      nil,
     },
     {   
        ['stack_version'] = 'manual',
        ['expected'] =      nil,
     },
 }

 for index, data in ipairs( inputdata ) do
    local got = get_stack_EasyBuild_version( data['stack_version'] )
    local expected = data['expected']
    print( testresult( got == expected ) ..
          'EasyBuild version for ' .. data['stack_version'] .. ' is ' ..
          ( got or 'nil' ) .. ', expected: ' .. ( data['expected'] or 'nil' ) )
 end
     
 
    
-- -----------------------------------------------------------------------------
--
-- Testing get_system_module_dirs( longname, stack_name, stack_version )
-- and through it get_stack_subarchs( longname, stack_version )
--

print( colour_title .. '\nTesting get_system_module_dirs and hence get_stack_subarchs\n' .. colour_reset )

function get_system_install_root()

   return '<SYSROOT>'

end

local tests = {
    -- system
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = 'system',
        ['longname'] =      'redhat7-x86_64',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/system/redhat7-x86_64',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/system/redhat7-x86_64'
    },
    {   -- This one should work as we must also be able to generate the module directories for subarchitectures.
        ['stack_name'] =    'calcua',
        ['stack_version'] = 'system',
        ['longname'] =      'redhat8-x86_64',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/system/redhat8-x86_64',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/system/redhat8-x86_64'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = 'system',
        ['longname'] =      'redhat8-broadwell-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/system/redhat8-broadwell-noaccel', -- system for redhat8 has specific CPU support
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/system/redhat8-x86_64,<SYSROOT>/modules-easybuild/system/redhat8-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = 'system',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/system/redhat8-zen2-noaccel', -- system for redhat8 has specific CPU support
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/system/redhat8-x86_64,<SYSROOT>/modules-easybuild/system/redhat8-zen2-noaccel'
    },
    -- 2020a
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2020a',
        ['longname'] =      'redhat7-ivybridge-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-2020a/redhat7-ivybridge-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-2020a/redhat7-x86_64,<SYSROOT>/modules-easybuild/calcua-2020a/redhat7-ivybridge-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2020a',
        ['longname'] =      'redhat7-broadwell-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-2020a/redhat7-broadwell-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-2020a/redhat7-x86_64,<SYSROOT>/modules-easybuild/calcua-2020a/redhat7-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2020a',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-2020a/redhat8-zen2-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-2020a/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-2020a/redhat8-zen2-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2020a',
        ['longname'] =      'redhat8-skylake-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-2020a/redhat8-skylake-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-2020a/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-2020a/redhat8-skylake-noaccel'
    },
    -- 2021b
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat7-ivybridge-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-2021b/redhat7-ivybridge-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-2021b/redhat7-x86_64,<SYSROOT>/modules-easybuild/calcua-2021b/redhat7-ivybridge-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat8-broadwell-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-2021b/redhat8-broadwell-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-2021b/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-2021b/redhat8-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat8-zen2-arcturus',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-2021b/redhat8-zen2-arcturus',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-2021b/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-2021b/redhat8-zen2-arcturus'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-2021b/redhat8-zen2-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-2021b/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-2021b/redhat8-zen2-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat8-skylake-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-2021b/redhat8-skylake-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-2021b/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-2021b/redhat8-skylake-noaccel'
    },
    -- 3000a
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat7-x86_64',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-3000a/redhat7-x86_64',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-3000a/redhat7-x86_64'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat7-ivybridge',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-3000a/redhat7-ivybridge',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-3000a/redhat7-x86_64,<SYSROOT>/modules-easybuild/calcua-3000a/redhat7-ivybridge'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat7-ivybridge-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-3000a/redhat7-ivybridge-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-3000a/redhat7-x86_64,<SYSROOT>/modules-easybuild/calcua-3000a/redhat7-ivybridge,<SYSROOT>/modules-easybuild/calcua-3000a/redhat7-ivybridge-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat8-broadwell-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-broadwell-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-broadwell,<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat8-zen2-arcturus',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-zen2-arcturus',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-zen2,<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-zen2-arcturus'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-zen2-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-zen2,<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-zen2-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat8-skylake-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-skylake-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-skylake,<SYSROOT>/modules-easybuild/calcua-3000a/redhat8-skylake-noaccel'
    },
    -- 4000a
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-x86_64',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-x86_64',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-x86_64'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-broadwell',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-broadwell',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-broadwell'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-broadwell-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-broadwell-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-broadwell,<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-zen2-arcturus',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-zen2-arcturus',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-zen2,<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-zen2-arcturus'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-zen2-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-zen2,<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-zen2-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-skylake-noaccel',
        ['own_modules'] =   '<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-skylake-noaccel',
        ['full_modules'] =  '<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-x86_64,<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-skylake,<SYSROOT>/modules-easybuild/calcua-4000a/redhat8-skylake-noaccel'
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
     { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2020a',
        ['longname'] =      'redhat8-zen2',
        ['own_modules'] =   nil, -- 2L scheme so this level is not present.
        ['full_modules'] =  nil
     },
     { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat7-ivybridge-noaccel',
        ['own_modules'] =   nil, -- No redhat7 software in 4000a.
        ['full_modules'] =  nil
     },
     { 
        ['stack_name'] =    'manual',
        ['stack_version'] = '',
        ['longname'] =      'redhat8-zen2-arcturus',
        ['own_modules'] =   nil, -- No modules for manual.
        ['full_modules'] =  nil
     },
     { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = 'manual',
        ['longname'] =      'redhat8-zen2-arcturus',
        ['own_modules'] =   nil, -- No modules for manual.
        ['full_modules'] =  nil
     },
 } 

for _,test in ipairs( tests )
do
    local hierarchy
    if ClusterMod_SystemProperties[test['stack_version']] == nil then
        -- Needed for manual.
        hierarchy = '*'
    else
        hierarchy =          ClusterMod_SystemProperties[test['stack_version']]['hierarchy']
    end
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


-- -----------------------------------------------------------------------------
--
-- Testing get_user_module_dirs( longname, stack_name, stack_version )
-- and through it get_stack_subarchs( longname, stack_version )
--

print( colour_title .. '\nTesting get_user_module_dirs and hence get_stack_subarchs\n' .. colour_reset )

function get_user_install_root()

   return '<USERROOT>'

end

local tests = {
    -- system
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = 'system',
        ['longname'] =      'redhat7-x86_64',
        ['own_modules'] =   '<USERROOT>/modules/system/redhat7-x86_64',
        ['full_modules'] =  '<USERROOT>/modules/system/redhat7-x86_64'
    },
    {   -- This one should work as we must also be able to generate the module directories for subarchitectures.
        ['stack_name'] =    'calcua',
        ['stack_version'] = 'system',
        ['longname'] =      'redhat8-x86_64',
        ['own_modules'] =   '<USERROOT>/modules/system/redhat8-x86_64',
        ['full_modules'] =  '<USERROOT>/modules/system/redhat8-x86_64'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = 'system',
        ['longname'] =      'redhat8-broadwell-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/system/redhat8-broadwell-noaccel', -- system for redhat8 has specific CPU support
        ['full_modules'] =  '<USERROOT>/modules/system/redhat8-x86_64,<USERROOT>/modules/system/redhat8-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = 'system',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/system/redhat8-zen2-noaccel', -- system for redhat8 has specific CPU support
        ['full_modules'] =  '<USERROOT>/modules/system/redhat8-x86_64,<USERROOT>/modules/system/redhat8-zen2-noaccel'
    },
    -- 2020a
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2020a',
        ['longname'] =      'redhat7-ivybridge-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-2020a/redhat7-ivybridge-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-2020a/redhat7-x86_64,<USERROOT>/modules/calcua-2020a/redhat7-ivybridge-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2020a',
        ['longname'] =      'redhat7-broadwell-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-2020a/redhat7-broadwell-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-2020a/redhat7-x86_64,<USERROOT>/modules/calcua-2020a/redhat7-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2020a',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-2020a/redhat8-zen2-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-2020a/redhat8-x86_64,<USERROOT>/modules/calcua-2020a/redhat8-zen2-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2020a',
        ['longname'] =      'redhat8-skylake-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-2020a/redhat8-skylake-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-2020a/redhat8-x86_64,<USERROOT>/modules/calcua-2020a/redhat8-skylake-noaccel'
    },
    -- 2021b
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat7-ivybridge-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-2021b/redhat7-ivybridge-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-2021b/redhat7-x86_64,<USERROOT>/modules/calcua-2021b/redhat7-ivybridge-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat8-broadwell-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-2021b/redhat8-broadwell-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-2021b/redhat8-x86_64,<USERROOT>/modules/calcua-2021b/redhat8-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat8-zen2-arcturus',
        ['own_modules'] =   '<USERROOT>/modules/calcua-2021b/redhat8-zen2-arcturus',
        ['full_modules'] =  '<USERROOT>/modules/calcua-2021b/redhat8-x86_64,<USERROOT>/modules/calcua-2021b/redhat8-zen2-arcturus'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-2021b/redhat8-zen2-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-2021b/redhat8-x86_64,<USERROOT>/modules/calcua-2021b/redhat8-zen2-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2021b',
        ['longname'] =      'redhat8-skylake-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-2021b/redhat8-skylake-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-2021b/redhat8-x86_64,<USERROOT>/modules/calcua-2021b/redhat8-skylake-noaccel'
    },
    -- 3000a
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat7-x86_64',
        ['own_modules'] =   '<USERROOT>/modules/calcua-3000a/redhat7-x86_64',
        ['full_modules'] =  '<USERROOT>/modules/calcua-3000a/redhat7-x86_64'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat7-ivybridge',
        ['own_modules'] =   '<USERROOT>/modules/calcua-3000a/redhat7-ivybridge',
        ['full_modules'] =  '<USERROOT>/modules/calcua-3000a/redhat7-x86_64,<USERROOT>/modules/calcua-3000a/redhat7-ivybridge'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat7-ivybridge-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-3000a/redhat7-ivybridge-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-3000a/redhat7-x86_64,<USERROOT>/modules/calcua-3000a/redhat7-ivybridge,<USERROOT>/modules/calcua-3000a/redhat7-ivybridge-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat8-broadwell-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-3000a/redhat8-broadwell-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-3000a/redhat8-x86_64,<USERROOT>/modules/calcua-3000a/redhat8-broadwell,<USERROOT>/modules/calcua-3000a/redhat8-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat8-zen2-arcturus',
        ['own_modules'] =   '<USERROOT>/modules/calcua-3000a/redhat8-zen2-arcturus',
        ['full_modules'] =  '<USERROOT>/modules/calcua-3000a/redhat8-x86_64,<USERROOT>/modules/calcua-3000a/redhat8-zen2,<USERROOT>/modules/calcua-3000a/redhat8-zen2-arcturus'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-3000a/redhat8-zen2-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-3000a/redhat8-x86_64,<USERROOT>/modules/calcua-3000a/redhat8-zen2,<USERROOT>/modules/calcua-3000a/redhat8-zen2-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '3000a',
        ['longname'] =      'redhat8-skylake-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-3000a/redhat8-skylake-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-3000a/redhat8-x86_64,<USERROOT>/modules/calcua-3000a/redhat8-skylake,<USERROOT>/modules/calcua-3000a/redhat8-skylake-noaccel'
    },
    -- 4000a
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-x86_64',
        ['own_modules'] =   '<USERROOT>/modules/calcua-4000a/redhat8-x86_64',
        ['full_modules'] =  '<USERROOT>/modules/calcua-4000a/redhat8-x86_64'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-broadwell',
        ['own_modules'] =   '<USERROOT>/modules/calcua-4000a/redhat8-broadwell',
        ['full_modules'] =  '<USERROOT>/modules/calcua-4000a/redhat8-x86_64,<USERROOT>/modules/calcua-4000a/redhat8-broadwell'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-broadwell-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-4000a/redhat8-broadwell-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-4000a/redhat8-x86_64,<USERROOT>/modules/calcua-4000a/redhat8-broadwell,<USERROOT>/modules/calcua-4000a/redhat8-broadwell-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-zen2-arcturus',
        ['own_modules'] =   '<USERROOT>/modules/calcua-4000a/redhat8-zen2-arcturus',
        ['full_modules'] =  '<USERROOT>/modules/calcua-4000a/redhat8-x86_64,<USERROOT>/modules/calcua-4000a/redhat8-zen2,<USERROOT>/modules/calcua-4000a/redhat8-zen2-arcturus'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-zen2-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-4000a/redhat8-zen2-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-4000a/redhat8-x86_64,<USERROOT>/modules/calcua-4000a/redhat8-zen2,<USERROOT>/modules/calcua-4000a/redhat8-zen2-noaccel'
    },
    { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat8-skylake-noaccel',
        ['own_modules'] =   '<USERROOT>/modules/calcua-4000a/redhat8-skylake-noaccel',
        ['full_modules'] =  '<USERROOT>/modules/calcua-4000a/redhat8-x86_64,<USERROOT>/modules/calcua-4000a/redhat8-skylake,<USERROOT>/modules/calcua-4000a/redhat8-skylake-noaccel'
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
     { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '2020a',
        ['longname'] =      'redhat8-zen2',
        ['own_modules'] =   nil, -- 2L scheme so this level is not present.
        ['full_modules'] =  nil
     },
     { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = '4000a',
        ['longname'] =      'redhat7-ivybridge-noaccel',
        ['own_modules'] =   nil, -- No redhat7 software in 4000a.
        ['full_modules'] =  nil
     },
     { 
        ['stack_name'] =    'manual',
        ['stack_version'] = '',
        ['longname'] =      'redhat8-zen2-arcturus',
        ['own_modules'] =   nil, -- No modules for manual.
        ['full_modules'] =  nil
     },
     { 
        ['stack_name'] =    'calcua',
        ['stack_version'] = 'manual',
        ['longname'] =      'redhat8-zen2-arcturus',
        ['own_modules'] =   nil, -- No modules for manual.
        ['full_modules'] =  nil
     },
 } 

for _,test in ipairs( tests )
do
    local hierarchy
    if ClusterMod_SystemProperties[test['stack_version']] == nil then
        -- Needed for manual.
        hierarchy = '*'
    else
        hierarchy =          ClusterMod_SystemProperties[test['stack_version']]['hierarchy']
    end
    local user_module_dir =  get_user_module_dir(  test['longname'], test['stack_name'], test['stack_version'] )
    local user_module_dirs = get_user_module_dirs( test['longname'], test['stack_name'], test['stack_version'] )
    local string_user_module_dirs
    if user_module_dirs == nil then
        string_user_module_dirs = nil
    else
        string_user_module_dirs = table.concat( user_module_dirs, ',')
    end
    print( testresult( user_module_dir == test['own_modules'] and string_user_module_dirs == test['full_modules'] ) ..
           'Modules of ' .. test['stack_name'] .. '/' .. test['stack_version'] ..
           ' (' .. hierarchy .. ') for arch ' .. test['longname'] .. 
           ' are in \n      ' .. ( user_module_dir or 'nil' ) )
           
    if user_module_dirs == nil then
        print(  '    Full hierarchy (lowest priority first):\n      nil' )
    else
        print(  '    Full hierarchy (lowest priority first):\n      ' ..
                table.concat( user_module_dirs, '\n      ') )
    end
    if user_module_dir ~= test['own_modules'] then
        print( '    Expected module dir: ' .. ( test['own_modules'] or 'nil' )  )
    end
    if string_user_module_dirs ~= test['full_modules'] then
        print( '    Expected full hierarchy: ' .. (test['full_modules'] or ''):gsub(',', ', ') )
    end
    print( '\n' )
         
end


-- -----------------------------------------------------------------------------
--
-- Testing get_system_inframodule_dir() longname, stack_name, stack_version )
--

print( colour_title .. '\nTesting get_system_inframodule_dirs\n' .. colour_reset )

function get_system_install_root()

   return '<SYSROOT>'

end

tests = {
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = '<SYSROOT>/modules-infrastructure/infrastructure/calcua/2021b/arch/redhat8-zen2-arcturus',
    },
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-x86_64',
        ['expected']      = '<SYSROOT>/modules-infrastructure/infrastructure/calcua/2021b/arch/redhat8-x86_64',
    },
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = 'system',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = '<SYSROOT>/modules-infrastructure/infrastructure/calcua/system/arch/redhat8-zen2-arcturus',
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
           'Infrastructure odules of ' .. test['stack_name'] .. '/' .. test['stack_version'] .. ' for arch ' .. test['longname'] .. ' are in \n  ' .. ( got or 'NIL' )  ..'\n' )
end


-- -----------------------------------------------------------------------------
--
-- Testing get_system_SW_dir() longname, stack_name, stack_version )
--

print( colour_title .. '\nTesting get_system_SW_dir\n' .. colour_reset )

function get_system_install_root()

   return '<SYSROOT>'

end

tests = {
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = '<SYSROOT>/SW/calcua-2021b/RH8-zen2-GFX908',
    },
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-x86_64',
        ['expected']      = '<SYSROOT>/SW/calcua-2021b/RH8-x86_64',
    },
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = 'system',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = '<SYSROOT>/SW/system/RH8-zen2-GFX908',
    },
    {
        ['stack_name']    = 'manual',
        ['stack_version'] = '',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = '<SYSROOT>/SW/MNL/RH8-zen2-GFX908',
    },
}

for _,test in ipairs( tests )
do
    local got = get_system_SW_dir( test['longname'], test['stack_name'], test['stack_version'] )
    print( testresult( got == test['expected']  ) ..
           'Software installations of ' .. test['stack_name'] .. '/' .. test['stack_version'] .. ' for arch ' .. test['longname'] .. ' are in \n  ' .. ( got or 'NIL' )  ..'\n' )
end


-- -----------------------------------------------------------------------------
--
-- Testing get_user_SW_dir() longname, stack_name, stack_version )
--

print( colour_title .. '\nTesting get_user_SW_dir\n' .. colour_reset )

function get_user_install_root()

   return '<USERROOT>'

end

tests = {
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = '<USERROOT>/SW/calcua-2021b/RH8-zen2-GFX908',
    },
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-x86_64',
        ['expected']      = '<USERROOT>/SW/calcua-2021b/RH8-x86_64',
    },
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = 'system',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = '<USERROOT>/SW/system/RH8-zen2-GFX908',
    },
    {
        ['stack_name']    = 'manual',
        ['stack_version'] = '',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = '<USERROOT>/SW/MNL/RH8-zen2-GFX908',
    },
}

for _,test in ipairs( tests )
do
    local got = get_user_SW_dir( test['longname'], test['stack_name'], test['stack_version'] )
    print( testresult( got == test['expected']  ) ..
           'Software installations of ' .. test['stack_name'] .. '/' .. test['stack_version'] .. ' for arch ' .. test['longname'] .. ' are in \n  ' .. ( got or 'NIL' )  ..'\n' )
end


-- -----------------------------------------------------------------------------
--
-- Testing get_system_EBrepo_dir( longname, stack_name, stack_version )
--

print( colour_title .. '\nTesting get_system_EBrepo_dir\n' .. colour_reset )

function get_system_install_root()

   return '<SYSROOT>'

end

local tests = {
   -- system
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = 'system',
       ['longname'] =      'redhat7-x86_64',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/system/redhat7-x86_64',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/system/redhat7-x86_64'
   },
   {   -- This one should work as we must also be able to generate the module directories for subarchitectures.
       ['stack_name'] =    'calcua',
       ['stack_version'] = 'system',
       ['longname'] =      'redhat8-x86_64',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/system/redhat8-x86_64',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/system/redhat8-x86_64'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = 'system',
       ['longname'] =      'redhat8-broadwell-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/system/redhat8-broadwell-noaccel', -- system for redhat8 has specific CPU support
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/system/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/system/redhat8-broadwell-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = 'system',
       ['longname'] =      'redhat8-zen2-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/system/redhat8-zen2-noaccel', -- system for redhat8 has specific CPU support
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/system/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/system/redhat8-zen2-noaccel'
   },
   -- 2020a
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2020a',
       ['longname'] =      'redhat7-ivybridge-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-2020a/redhat7-ivybridge-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-2020a/redhat7-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-2020a/redhat7-ivybridge-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2020a',
       ['longname'] =      'redhat7-broadwell-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-2020a/redhat7-broadwell-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-2020a/redhat7-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-2020a/redhat7-broadwell-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2020a',
       ['longname'] =      'redhat8-zen2-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-2020a/redhat8-zen2-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-2020a/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-2020a/redhat8-zen2-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2020a',
       ['longname'] =      'redhat8-skylake-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-2020a/redhat8-skylake-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-2020a/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-2020a/redhat8-skylake-noaccel'
   },
   -- 2021b
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2021b',
       ['longname'] =      'redhat7-ivybridge-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat7-ivybridge-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat7-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat7-ivybridge-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2021b',
       ['longname'] =      'redhat8-broadwell-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat8-broadwell-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat8-broadwell-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2021b',
       ['longname'] =      'redhat8-zen2-arcturus',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat8-zen2-arcturus',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat8-zen2-arcturus'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2021b',
       ['longname'] =      'redhat8-zen2-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat8-zen2-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat8-zen2-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2021b',
       ['longname'] =      'redhat8-skylake-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat8-skylake-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-2021b/redhat8-skylake-noaccel'
   },
   -- 3000a
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '3000a',
       ['longname'] =      'redhat7-x86_64',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat7-x86_64',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat7-x86_64'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '3000a',
       ['longname'] =      'redhat7-ivybridge',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat7-ivybridge',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat7-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat7-ivybridge'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '3000a',
       ['longname'] =      'redhat7-ivybridge-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat7-ivybridge-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat7-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat7-ivybridge,<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat7-ivybridge-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '3000a',
       ['longname'] =      'redhat8-broadwell-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-broadwell-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-broadwell,<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-broadwell-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '3000a',
       ['longname'] =      'redhat8-zen2-arcturus',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-zen2-arcturus',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-zen2,<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-zen2-arcturus'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '3000a',
       ['longname'] =      'redhat8-zen2-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-zen2-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-zen2,<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-zen2-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '3000a',
       ['longname'] =      'redhat8-skylake-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-skylake-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-skylake,<SYSROOT>/mgmt/EBrepo_files/calcua-3000a/redhat8-skylake-noaccel'
   },
   -- 4000a
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '4000a',
       ['longname'] =      'redhat8-x86_64',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-x86_64',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-x86_64'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '4000a',
       ['longname'] =      'redhat8-broadwell',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-broadwell',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-broadwell'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '4000a',
       ['longname'] =      'redhat8-broadwell-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-broadwell-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-broadwell,<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-broadwell-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '4000a',
       ['longname'] =      'redhat8-zen2-arcturus',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-zen2-arcturus',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-zen2,<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-zen2-arcturus'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '4000a',
       ['longname'] =      'redhat8-zen2-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-zen2-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-zen2,<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-zen2-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '4000a',
       ['longname'] =      'redhat8-skylake-noaccel',
       ['own_repo'] =      '<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-skylake-noaccel',
       ['full_repo'] =     '<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-x86_64,<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-skylake,<SYSROOT>/mgmt/EBrepo_files/calcua-4000a/redhat8-skylake-noaccel'
   },
   -- Cases that should print error messages.
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = 'system',
       ['longname'] =      'redhat7-broadwell-noaccel',
       ['own_repo'] =      nil, -- system for redhat7 exists only in an x86_64 version.
       ['full_repo'] =     nil
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = 'system',
       ['longname'] =      'redhat8-zen2-arcturus',
       ['own_repo'] =      nil, -- system for redhat8 has specific CPU support but no GPU support.
       ['full_repo'] =     nil
    },
    { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2020a',
       ['longname'] =      'redhat8-zen2',
       ['own_repo'] =      nil, -- 2L scheme so this level is not present.
       ['full_repo'] =     nil
    },
    { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '4000a',
       ['longname'] =      'redhat7-ivybridge-noaccel',
       ['own_repo'] =      nil, -- No redhat7 software in 4000a.
       ['full_repo'] =     nil
    },
    { 
       ['stack_name'] =    'manual',
       ['stack_version'] = '',
       ['longname'] =      'redhat8-zen2-arcturus',
       ['own_repo'] =      nil, -- No modules for manual.
       ['full_repo'] =     nil
    },
    { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = 'manual',
       ['longname'] =      'redhat8-zen2-arcturus',
       ['own_repo'] =      nil, -- No modules for manual.
       ['full_repo'] =     nil
    },
} 

for _,test in ipairs( tests )
do
    local hierarchy
    if ClusterMod_SystemProperties[test['stack_version']] == nil then
        -- Needed for manual.
        hierarchy = '*'
    else
        hierarchy =          ClusterMod_SystemProperties[test['stack_version']]['hierarchy']
    end
    local system_repo_dir =  get_system_EBrepo_dir(  test['longname'], test['stack_name'], test['stack_version'] )
    local system_repo_dirs = get_system_EBrepo_dirs( test['longname'], test['stack_name'], test['stack_version'] )
    local string_system_repo_dirs
    if system_repo_dirs == nil then
        string_system_repo_dirs = nil
    else
        string_system_repo_dirs = table.concat( system_repo_dirs, ',')
    end
    print( testresult( system_repo_dir == test['own_repo'] and string_system_repo_dirs == test['full_repo'] ) ..
           'System EasyConfig repository files of ' .. test['stack_name'] .. '/' .. test['stack_version'] ..
           ' (' .. hierarchy .. ') for arch ' .. test['longname'] .. 
           ' are in \n      ' .. ( system_repo_dir or 'nil' ) )
           
    if system_repo_dirs == nil then
        print(  '    Full hierarchy (lowest priority first):\n      nil' )
    else
        print(  '    Full hierarchy (lowest priority first):\n      ' ..
                table.concat( system_repo_dirs, '\n      ') )
    end
    if system_repo_dir ~= test['own_repo'] then
        print( '    Expected repo dir: ' .. ( test['own_repo'] or 'nil' )  )
    end
    if string_system_repo_dirs ~= test['full_repo'] then
        print( '    Expected full hierarchy: ' .. (test['full_repo'] or ''):gsub(',', ', ') )
    end
    print( '\n' )
         
end



-- -----------------------------------------------------------------------------
--
-- Testing get_user_EBrepo_dir( longname, stack_name, stack_version )
--

print( colour_title .. '\nTesting get_user_EBrepo_dir\n' .. colour_reset )

function get_user_install_root()

   return '<USERROOT>'

end

local tests = {
   -- system
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = 'system',
       ['longname'] =      'redhat7-x86_64',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/system/redhat7-x86_64',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/system/redhat7-x86_64'
   },
   {   -- This one should work as we must also be able to generate the module directories for subarchitectures.
       ['stack_name'] =    'calcua',
       ['stack_version'] = 'system',
       ['longname'] =      'redhat8-x86_64',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/system/redhat8-x86_64',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/system/redhat8-x86_64'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = 'system',
       ['longname'] =      'redhat8-broadwell-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/system/redhat8-broadwell-noaccel', -- system for redhat8 has specific CPU support
       ['full_repo'] =     '<USERROOT>/EBrepo_files/system/redhat8-x86_64,<USERROOT>/EBrepo_files/system/redhat8-broadwell-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = 'system',
       ['longname'] =      'redhat8-zen2-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/system/redhat8-zen2-noaccel', -- system for redhat8 has specific CPU support
       ['full_repo'] =     '<USERROOT>/EBrepo_files/system/redhat8-x86_64,<USERROOT>/EBrepo_files/system/redhat8-zen2-noaccel'
   },
   -- 2020a
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2020a',
       ['longname'] =      'redhat7-ivybridge-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-2020a/redhat7-ivybridge-noaccel',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-2020a/redhat7-x86_64,<USERROOT>/EBrepo_files/calcua-2020a/redhat7-ivybridge-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2020a',
       ['longname'] =      'redhat7-broadwell-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-2020a/redhat7-broadwell-noaccel',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-2020a/redhat7-x86_64,<USERROOT>/EBrepo_files/calcua-2020a/redhat7-broadwell-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2020a',
       ['longname'] =      'redhat8-zen2-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-2020a/redhat8-zen2-noaccel',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-2020a/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-2020a/redhat8-zen2-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2020a',
       ['longname'] =      'redhat8-skylake-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-2020a/redhat8-skylake-noaccel',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-2020a/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-2020a/redhat8-skylake-noaccel'
   },
   -- 2021b
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2021b',
       ['longname'] =      'redhat7-ivybridge-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-2021b/redhat7-ivybridge-noaccel',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-2021b/redhat7-x86_64,<USERROOT>/EBrepo_files/calcua-2021b/redhat7-ivybridge-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2021b',
       ['longname'] =      'redhat8-broadwell-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-2021b/redhat8-broadwell-noaccel',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-2021b/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-2021b/redhat8-broadwell-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2021b',
       ['longname'] =      'redhat8-zen2-arcturus',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-2021b/redhat8-zen2-arcturus',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-2021b/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-2021b/redhat8-zen2-arcturus'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2021b',
       ['longname'] =      'redhat8-zen2-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-2021b/redhat8-zen2-noaccel',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-2021b/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-2021b/redhat8-zen2-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2021b',
       ['longname'] =      'redhat8-skylake-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-2021b/redhat8-skylake-noaccel',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-2021b/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-2021b/redhat8-skylake-noaccel'
   },
   -- 3000a
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '3000a',
       ['longname'] =      'redhat7-x86_64',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-3000a/redhat7-x86_64',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-3000a/redhat7-x86_64'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '3000a',
       ['longname'] =      'redhat7-ivybridge',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-3000a/redhat7-ivybridge',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-3000a/redhat7-x86_64,<USERROOT>/EBrepo_files/calcua-3000a/redhat7-ivybridge'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '3000a',
       ['longname'] =      'redhat7-ivybridge-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-3000a/redhat7-ivybridge-noaccel',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-3000a/redhat7-x86_64,<USERROOT>/EBrepo_files/calcua-3000a/redhat7-ivybridge,<USERROOT>/EBrepo_files/calcua-3000a/redhat7-ivybridge-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '3000a',
       ['longname'] =      'redhat8-broadwell-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-3000a/redhat8-broadwell-noaccel',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-3000a/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-3000a/redhat8-broadwell,<USERROOT>/EBrepo_files/calcua-3000a/redhat8-broadwell-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '3000a',
       ['longname'] =      'redhat8-zen2-arcturus',
       ['own_repo'] =   '<USERROOT>/EBrepo_files/calcua-3000a/redhat8-zen2-arcturus',
       ['full_repo'] =  '<USERROOT>/EBrepo_files/calcua-3000a/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-3000a/redhat8-zen2,<USERROOT>/EBrepo_files/calcua-3000a/redhat8-zen2-arcturus'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '3000a',
       ['longname'] =      'redhat8-zen2-noaccel',
       ['own_repo'] =   '<USERROOT>/EBrepo_files/calcua-3000a/redhat8-zen2-noaccel',
       ['full_repo'] =  '<USERROOT>/EBrepo_files/calcua-3000a/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-3000a/redhat8-zen2,<USERROOT>/EBrepo_files/calcua-3000a/redhat8-zen2-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '3000a',
       ['longname'] =      'redhat8-skylake-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-3000a/redhat8-skylake-noaccel',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-3000a/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-3000a/redhat8-skylake,<USERROOT>/EBrepo_files/calcua-3000a/redhat8-skylake-noaccel'
   },
   -- 4000a
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '4000a',
       ['longname'] =      'redhat8-x86_64',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-4000a/redhat8-x86_64',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-4000a/redhat8-x86_64'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '4000a',
       ['longname'] =      'redhat8-broadwell',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-4000a/redhat8-broadwell',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-4000a/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-4000a/redhat8-broadwell'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '4000a',
       ['longname'] =      'redhat8-broadwell-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-4000a/redhat8-broadwell-noaccel',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-4000a/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-4000a/redhat8-broadwell,<USERROOT>/EBrepo_files/calcua-4000a/redhat8-broadwell-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '4000a',
       ['longname'] =      'redhat8-zen2-arcturus',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-4000a/redhat8-zen2-arcturus',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-4000a/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-4000a/redhat8-zen2,<USERROOT>/EBrepo_files/calcua-4000a/redhat8-zen2-arcturus'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '4000a',
       ['longname'] =      'redhat8-zen2-noaccel',
       ['own_repo'] =      '<USERROOT>/EBrepo_files/calcua-4000a/redhat8-zen2-noaccel',
       ['full_repo'] =     '<USERROOT>/EBrepo_files/calcua-4000a/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-4000a/redhat8-zen2,<USERROOT>/EBrepo_files/calcua-4000a/redhat8-zen2-noaccel'
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '4000a',
       ['longname'] =      'redhat8-skylake-noaccel',
       ['own_repo'] =   '<USERROOT>/EBrepo_files/calcua-4000a/redhat8-skylake-noaccel',
       ['full_repo'] =  '<USERROOT>/EBrepo_files/calcua-4000a/redhat8-x86_64,<USERROOT>/EBrepo_files/calcua-4000a/redhat8-skylake,<USERROOT>/EBrepo_files/calcua-4000a/redhat8-skylake-noaccel'
   },
   -- Cases that should print error messages.
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = 'system',
       ['longname'] =      'redhat7-broadwell-noaccel',
       ['own_repo'] =   nil, -- system for redhat7 exists only in an x86_64 version.
       ['full_repo'] =  nil
   },
   { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = 'system',
       ['longname'] =      'redhat8-zen2-arcturus',
       ['own_repo'] =      nil, -- system for redhat8 has specific CPU support but no GPU support.
       ['full_repo'] =     nil
    },
    { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '2020a',
       ['longname'] =      'redhat8-zen2',
       ['own_repo'] =      nil, -- 2L scheme so this level is not present.
       ['full_repo'] =     nil
    },
    { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = '4000a',
       ['longname'] =      'redhat7-ivybridge-noaccel',
       ['own_repo'] =      nil, -- No redhat7 software in 4000a.
       ['full_repo'] =     nil
    },
    { 
       ['stack_name'] =    'manual',
       ['stack_version'] = '',
       ['longname'] =      'redhat8-zen2-arcturus',
       ['own_repo'] =      nil, -- No modules for manual.
       ['full_repo'] =     nil
    },
    { 
       ['stack_name'] =    'calcua',
       ['stack_version'] = 'manual',
       ['longname'] =      'redhat8-zen2-arcturus',
       ['own_repo'] =      nil, -- No modules for manual.
       ['full_repo'] =     nil
    },
} 

for _,test in ipairs( tests )
do
    local hierarchy
    if ClusterMod_SystemProperties[test['stack_version']] == nil then
        -- Needed for manual.
        hierarchy = '*'
    else
        hierarchy =          ClusterMod_SystemProperties[test['stack_version']]['hierarchy']
    end
    local user_repo_dir =  get_user_EBrepo_dir(  test['longname'], test['stack_name'], test['stack_version'] )
    local user_repo_dirs = get_user_EBrepo_dirs( test['longname'], test['stack_name'], test['stack_version'] )
    local string_user_repo_dirs
    if user_repo_dirs == nil then
        string_user_repo_dirs = nil
    else
        string_user_repo_dirs = table.concat( user_repo_dirs, ',')
    end
    print( testresult( user_repo_dir == test['own_repo'] and string_user_repo_dirs == test['full_repo'] ) ..
           'User EasyConfig repository files of ' .. test['stack_name'] .. '/' .. test['stack_version'] ..
           ' (' .. hierarchy .. ') for arch ' .. test['longname'] .. 
           ' are in \n      ' .. ( user_repo_dir or 'nil' ) )
           
    if user_repo_dirs == nil then
        print(  '    Full hierarchy (lowest priority first):\n      nil' )
    else
        print(  '    Full hierarchy (lowest priority first):\n      ' ..
                table.concat( user_repo_dirs, '\n      ') )
    end
    if user_repo_dir ~= test['own_repo'] then
        print( '    Expected repo dir: ' .. ( test['own_repo'] or 'nil' )  )
    end
    if string_user_repo_dirs ~= test['full_repo'] then
        print( '    Expected full hierarchy: ' .. (test['full_repo'] or ''):gsub(',', ', ') )
    end
    print( '\n' )
         
end


-- -----------------------------------------------------------------------------
--
-- Testing get_optarch() longname, stack_name, stack_version )
--

print( colour_title .. '\nTesting get_optarch\n' .. colour_reset )

tests = {
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = 'Intel:march=core-avx2 -mtune=core-avx2',
    },
    {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-x86_64',
        ['expected']      = 'Intel:march=core-avx-i -mtune=core-avx-i',
   },
   {
        ['stack_name']    = 'calcua',
        ['stack_version'] = '2021b',
        ['longname']      = 'redhat8-broadwell',
        ['expected']      = nil,
   },
   {
        ['stack_name']    = 'calcua',
        ['stack_version'] = 'system',
        ['longname']      = 'redhat8-zen2-arcturus',
        ['expected']      = 'Intel:march=core-avx2 -mtune=core-avx2',
    },
}

for _,test in ipairs( tests )
do
    local got = get_optarch( test['longname'], test['stack_name'], test['stack_version'] )
    print( testresult( got == test['expected']  ) ..
           'OPTARCH for ' .. test['stack_name'] .. '/' .. test['stack_version'] .. ' for arch ' .. test['longname'] .. ' is \n  ' .. ( got or 'NIL' )  ..'\n' )
end




-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
--
-- Testing specific for the current cluster, so no way to check the results automatically
--

print( colour_title .. '\nTESTING CURRENT CLUSTER\n========================' .. colour_reset )

-- -----------------------------------------------------------------------------
--
-- Testing get_stack_generic_current
--

print( colour_title .. '\nTesting get_stack_generic_current function\n' .. colour_reset )

for stack,_ in pairs( ClusterMod_SystemTable ) do
       print( mssg_sysdep .. ' Generic for ' .. stack .. ' on the current node: ' .. get_stack_generic_current( stack ) )
end
              
-- -----------------------------------------------------------------------------
--
-- Testing get_stack_osarch_current
--

print( colour_title .. '\nTesting get_stack_osarch_current function\n' .. colour_reset )

for stack,_ in pairs( ClusterMod_SystemTable ) do
    local hierarchy = ClusterMod_SystemProperties[stack]['hierarchy'] 
    print( mssg_sysdep .. ' Architecture of the current node in the format for ' .. stack .. 
           ' (' .. hierarchy .. '): ' ..
           get_stack_osarch_current( stack ) )
end

-- -----------------------------------------------------------------------------
--
-- Testing get_stack_top with get_cluster_osarch
--

print( colour_title .. '\nTesting get_stack_top function with get_cluster_osarch\n' .. colour_reset )

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

for stack,_ in pairs( ClusterMod_SystemTable ) do
    local hierarchy = ClusterMod_SystemProperties[stack]['hierarchy'] 
    local current_osarch = get_cluster_osarch()
    print( mssg_sysdep .. ' Used architecture for ' .. current_osarch  .. 
           ' (this node) for ' .. stack .. ' (' .. hierarchy .. '): ' .. 
           ( get_stack_top( current_osarch, stack ) or '\27[31mPROBLEM, GOT NIL\27[0m' ) )
end
       

