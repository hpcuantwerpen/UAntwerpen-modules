#! /usr/bin/env lua

dofile( '../scripts/ClusterMod_tools/lmod_emulation.lua' )
dofile( '../etc/SystemDefinition.lua' )
dofile( '../LMOD/SitePackage_map_toolchain.lua' )

--
-- Testing map_toolchain
--

print( '\ntesting map_toolchain' )

for _, toolchain in ipairs( { '2020a', '2020b', '2020.01', '2023a', '2019b' } ) do
    print( 'Toolchain ' .. toolchain .. ' maps to ' .. map_toolchain(toolchain) )
end

--
-- Testing get_versionedfile
--

print( '\ntesting get_versionedfile' )

directory = 'testing-1'
filenameprefix = ''
filenamesuffix = '.lua'

tests = { 
    { ['arg'] = 'system',  ['expected'] = 'system'  },
    { ['arg'] = '2020a',   ['expected'] = '2020a'   },
    { ['arg'] = '2021.07', ['expected'] = '2021.07' },
    { ['arg'] = '2022b',   ['expected'] = '2022b'   },
    { ['arg'] = '2023.01', ['expected'] = '202300'  },
    { ['arg'] = '2019b',   ['expected'] = 'system'  },
    { ['arg'] = '2021a',   ['expected'] = '2020a'   },
    { ['arg'] = '2021b',   ['expected'] = '2021.07' },
}
for _, v in ipairs( tests ) do
    filename = get_versionedfile( v['arg'], directory, filenameprefix, filenamesuffix )
    print( 'Got ' .. filename .. ', expected ' .. directory .. '/' .. filenameprefix .. v['expected'] .. filenamesuffix )
end

directory = 'testing-2'
filenameprefix = 'file-'
filenamesuffix = '.lua'
for _, v in ipairs( tests ) do
    filename = get_versionedfile( v['arg'], directory, filenameprefix, filenamesuffix )
    print( 'Got ' .. filename .. ', expected ' .. directory .. '/' .. filenameprefix .. v['expected'] .. filenamesuffix )
end

