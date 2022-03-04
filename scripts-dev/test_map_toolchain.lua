#! /usr/bin/env lua

dofile( 'test_import_from_lua.lua' )
dofile( '../etc/SystemDefinition.lua' )
dofile( '../LMOD/SitePackage_map_toolchain.lua' )

--
-- Testing map_toolchain
--

print( '\ntesting map_toolchain' )

for _, toolchain in ipairs( { '2020a', '2020b', '2020.01', '2023a', '2019b' } ) do
    print( 'Toolchain ' .. toolchain .. ' maps to ' .. map_toolchain(toolchain) )
end
