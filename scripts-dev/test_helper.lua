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

dofile( 'test_import_from_lua.lua' )
dofile( '../LMOD/SitePackage_helper.lua' )

--
-- Testing get_matching_archmap_key
--

print( '\ntesting get_matching_archmap_key' )

local test_key

test_key = '199900'
if get_matching_archmap_key( test_key ) ~= nil then
    print( 'get_matching_archmap_key( ' .. test_key .. ') did not return nil' )
else
    print( 'get_matching_archmap_key( ' .. test_key .. ') returned nil as expected' )
end

for _, test_key in ipairs( {'200000', '202001', '202100', '202101', '202301'} )
do
    print( 'get_matching_archmap_key( ' .. test_key .. ') returned ' .. get_matching_archmap_key( test_key ) )
end
