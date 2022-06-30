#! /usr/bin/env lua

CalcUA_map_arch_hierarchy = {
    -- We start with a 2-level map 
    ['200000'] = {
        ['zen2-noaccel']      = 'x86_64',
        ['zen2-ampere']       = 'x86_64',
        ['zen2-arcturus']     = 'x86_64',
        ['broadwell-noaccel'] = 'x86_64',
        ['broadwell-P5000']   = 'x86_64',
        ['broadwell-pascal']  = 'x86_64',
        ['skylake-noaccel']   = 'x86_64',
        ['skylake-aurora1']   = 'x86_64',
        ['ivybridge-noaccel'] = 'x86_64',
        ['x86_64']            = nil,    
    },
    ['202100'] = {
        ['zen2-noaccel']      = 'x86_64',
        ['zen2-ampere']       = 'x86_64',
        ['zen2-arcturus']     = 'x86_64',
        ['broadwell-noaccel'] = 'x86_64',
        ['broadwell-P5000']   = 'x86_64',
        ['broadwell-pascal']  = 'x86_64',
        ['skylake-noaccel']   = 'x86_64',
        ['skylake-aurora1']   = 'x86_64',
        ['ivybridge-noaccel'] = 'x86_64',
        ['x86_64']            = nil,    
    }
}

CalcUA_map_cpu_to_gen = {
    ['200000'] = {
        ['zen3']      = 'x86_64',
        ['zen2']      = 'x86_64',
        ['skylake']   = 'x86_64',
        ['broadwell'] = 'x86_64',
        ['ivybridge'] = 'x86_64',
        ['x86_64']    = nil,
    },
    ['202100'] = {
        ['zen3']      = 'x86_64',
        ['zen2']      = 'x86_64',
        ['skylake']   = 'x86_64',
        ['broadwell'] = 'x86_64',
        ['ivybridge'] = 'x86_64',
        ['x86_64']    = nil,
    },
}

CalcUA_reduce_cpu = {
    ['200000'] = {
        ['zen3']      = 'zen2',
        ['zen2']      = 'broadwell',
        ['broadwell'] = 'ivybridge',
        ['ivybridge'] = 'x86_64',
        ['x86_64']    = nil,
    },
    ['202100'] = {
        ['zen3']      = 'zen2',
        ['zen2']      = 'broadwell',
        ['broadwell'] = 'ivybridge',
        ['ivybridge'] = 'x86_64',
        ['x86_64']    = nil,
    },
}

CalcUA_reduce_top_arch = {
    ['200000'] = {
        ['zen3-noaccel']      = 'zen2-noaccel',
        ['zen2-ampere']       = 'zen2-noaccel',
        ['zen2-arcturus']     = 'zen2-noaccel',
        ['zen2-noaccel']      = 'broadwell-noaccel',
        ['skylake-aurora1']   = 'skylake-noaccel',
        ['skylake-noaccel']   = 'broadwell-noaccel',
        ['broadwell-noaccel'] = 'ivybridge-noaccel',
        ['broadwell-P5000']   = 'broadwell-noaccel',
        ['broadwell-pascal']  = 'broadwell-noaccel',
        ['ivybridge-noaccel'] = 'x86_64',
        ['x86_64']            = nil,
    },
    ['202100'] = {
        ['zen3-noaccel']      = 'zen2-noaccel',
        ['zen2-ampere']       = 'zen2-noaccel',
        ['zen2-arcturus']     = 'zen2-noaccel',
        ['zen2-noaccel']      = 'broadwell-noaccel',
        ['skylake-aurora1']   = 'skylake-noaccel',
        ['skylake-noaccel']   = 'broadwell-noaccel',
        ['broadwell-noaccel'] = 'ivybridge-noaccel',
        ['broadwell-P5000']   = 'broadwell-noaccel',
        ['broadwell-pascal']  = 'broadwell-noaccel',
        ['ivybridge-noaccel'] = 'x86_64',
        ['x86_64']            = nil,
    },
}



-- dofile( 'test_import_from_lua.lua' )
dofile( '../LMOD/SitePackage_helper.lua' )

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
-- Testing get_matching_archmap_key
--

print( colour_title .. '\ntesting get_matching_archmap_key' .. colour_reset )

tests = {
    {
        ['testkey']  = '1999900',
        ['expected'] = nil,
    },
    {
        ['testkey']  = '200000',
        ['expected'] = '200000',
    },
    {
        ['testkey']  = '202000',
        ['expected'] = '200000',
    },
    {
        ['testkey']  = '202100',
        ['expected'] = '202100',
    },
    {
        ['testkey']  = '202101',
        ['expected'] = '202100',
    },
    {
        ['testkey']  = '202301',
        ['expected'] = '202100',
    },
}

for _,testcase in ipairs( tests )
do
    local testkey =  testcase['testkey']
    local expected = testcase['expected']
    local got =      get_matching_archmap_key( testkey )
    print( testresult( got == expected ) .. 
           'get_matching_archmap_key( ' .. testkey .. ') returned ' .. ( got or 'nil' ) .. 
           ', expected ' .. ( expected or 'nil' ) .. '.' ) 
end

--
-- Testing get_matching_cputogen_key
--

print( colour_title .. '\nTesting get_matching_cputogen_key' .. colour_reset )

-- Same tests as previous function.

for _,testcase in ipairs( tests )
do
    local testkey =  testcase['testkey']
    local expected = testcase['expected']
    local got =      get_matching_cputogen_key( testkey )
    print( testresult( got == expected ) .. 
           'get_matching_cputogen_key( ' .. testkey .. ') returned ' .. ( got or 'nil' ) .. 
           ', expected ' .. ( expected or 'nil' ) .. '.' ) 
end

--
-- Testing get_matching_reducecpu_key
--

print( colour_title .. '\nTesting get_matching_reducecpu_key' .. colour_reset )

-- Same tests as previous function.

for _,testcase in ipairs( tests )
do
    local testkey =  testcase['testkey']
    local expected = testcase['expected']
    local got =      get_matching_reducecpu_key( testkey )
    print( testresult( got == expected ) .. 
           'get_matching_reducecpu_key( ' .. testkey .. ') returned ' .. ( got or 'nil' ) .. 
           ', expected ' .. ( expected or 'nil' ) .. '.' ) 
end


--
-- Testing get_matching_toparchreduction_key
--

print( colour_title .. '\nTesting get_matching_toparchreduction_key' .. colour_reset )

-- Same tests as previous function.

for _,testcase in ipairs( tests )
do
    local testkey =  testcase['testkey']
    local expected = testcase['expected']
    local got =      get_matching_toparchreduction_key( testkey )
    print( testresult( got == expected ) .. 
           'get_matching_toparchreduction_key( ' .. testkey .. ') returned ' .. ( got or 'nil' ) .. 
           ', expected ' .. ( expected or 'nil' ) .. '.' ) 
end


