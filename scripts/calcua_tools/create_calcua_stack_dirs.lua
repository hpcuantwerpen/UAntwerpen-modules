#! /usr/bin/env lua

dofile( 'lmod_emulation.lua' )
dofile( '../../etc/SystemDefinition.lua' )
dofile( '../../LMOD/SitePackage_helper.lua' )
dofile( '../../LMOD/SitePackage_map_toolchain.lua' )
dofile( '../../LMOD/SitePackage_arch_hierarchy.lua' )

local routine_name = 'create_calcua_stack_dirs'
local stack_name = 'calcua'

if #arg ~= 2 then
    io.stderr:write( routine_name .. ': ERROR: Two command line argument is expected: the version of the calcua stack and the root of the installation.\n' )
    os.exit( 1 )
end

local stack_version = arg[1]
local root_dir = arg[2]

if CalcUA_SystemTable[stack_version] == nil then
    io.stderr:write( routine_name .. ': ERROR: The stack version ' .. stack_version .. ' is not recognized as a valid stack.\n' ..
                     'Maybe CalcUA_SystemTable in etc/SystemDefinition.lua needs updating?\n' )
    os.exit( 1 )
end

--
-- Gather all dependent architectures
--

print( 'Computing all OS-arch combinations needed for ' .. stack_name .. '/' .. stack_version .. '...' )

local OSArchTable = {}
local OSArchTableWorker = {}

for OS,_ in pairs( CalcUA_SystemTable[stack_version] ) do

    for _,arch in ipairs( CalcUA_SystemTable[stack_version][OS] ) do

        for _,subarch in ipairs( get_long_osarchs_reverse( stack_version, OS, arch ) ) do

            if OSArchTableWorker[subarch] == nil then
                OSArchTableWorker[subarch] = true
                table.insert( OSArchTable, subarch )
            end

        end

    end

end

print( 'Detected the following OS-arch combination:\n' .. table.concat( OSArchTable, '\n') )


--
-- Create directories
--
-- -   First the directories that EasyBuild will write in
--

for _,longname in ipairs( OSArchTable ) do

    print( '\nCreating directories for ' .. longname .. ':' )

    local appl_modules = pathJoin( root_dir, get_system_module_dir( longname, stack_name, stack_version ) )
    print( 'Application modules:    ' .. appl_modules )
    mkDir( appl_modules )

    local infra_modules = pathJoin( root_dir, get_system_inframodule_dir( longname, stack_name, stack_version ) )
    print( 'Infrastructure modules: ' .. infra_modules )
    mkDir( infra_modules )

    local SW_dir = pathJoin( root_dir, get_system_SW_dir( longname, stack_name, stack_version ) )
    print( 'Software directory:     ' .. SW_dir )
    mkDir( SW_dir )

    local EBrepo_dir = pathJoin( root_dir, 'mgmt', get_system_EBrepo_dir( longname, stack_name, stack_version ) )
    print( 'EBrepo_files directory: ' .. EBrepo_dir )
    mkDir( EBrepo_dir )

end

--
-- -   Now the directories for the actual modules
--
--     *   Software stack module
--

local stack_dir = pathJoin( root_dir, 'modules-infrastructure/stack/calcua' )
mkDir( stack_dir )

-- TODO: Link to the right version of UAntwerpen-modules/generic-modules/calcua

--
--    *    Architecture modules
--

local arch_dir = pathJoin( root_dir, 'modules-infrastructure/arch/calcua', stack_version )

mkDir( pathJoin( arch_dir, 'arch' ) )

for _,longname in ipairs( OSArchTable ) do

    local link_name = pathJoin( arch_dir, 'arch', longname )
    -- TODO: Link the module to the right version of UAntwerpen-modules/generic-modules/clusterarch

end

--
--    *    Cluster modules (architecture modules with cluster name)
--

local arch_dir = pathJoin( root_dir, 'modules-infrastructure/arch/calcua', stack_version )

mkDir( pathJoin( arch_dir, 'cluster' ) )

for cluster,_ in ipairs( CalcUA_ClusterMap[stack_version] ) do

    local link_name = pathJoin( arch_dir, 'cluster', cluster )
    -- TODO: Link the module to the right version of UAntwerpen-modules/generic-modules/clusterarch

end

