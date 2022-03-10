#! /usr/bin/env lua

dofile( 'lmod_emulation.lua' )
dofile( '../../etc/SystemDefinition.lua' )
dofile( '../../LMOD/SitePackage_helper.lua' )
dofile( '../../LMOD/SitePackage_map_toolchain.lua' )
dofile( '../../LMOD/SitePackage_arch_hierarchy.lua' )

routine_name = 'create_calcua_stack_dirs'
stack_name = 'calcua'

if #arg ~= 2 then
    io.stderr:write( routine_name .. ': ERROR: Two command line argument is expected: the version of the calcua stack and the root of the installation.\n' )
    os.exit( 1 )
end

stack_version = arg[1]
root_dir = arg[2]

if CalcUA_SystemTable[stack_version] == nil then
    io.stderr:write( routine_name .. ': ERROR: The stack version ' .. stack_version .. ' is not recognized as a valid stack.\n' ..
                     'Maybe CalcUA_SystemTable in etc/SystemDefinition.lua needs updating?\n' )
    os.exit( 1 )
end

--
-- Gather all dependent architectures
--

print( 'Computing all OS-arch combinations needed for ' .. stack_name .. '/' .. stack_version .. '...' )

OSArchTable = {}
OSArchTableWorker = {}

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


for _,longname in ipairs( OSArchTable ) do

    print( '\nCreating directories for ' .. longname .. ':' )

    appl_modules = pathJoin( root_dir, get_system_module_dir( longname, stack_name, stack_version ) )
    print( 'Application modules: ', appl_modules )
    mkDir( appl_modules )


end