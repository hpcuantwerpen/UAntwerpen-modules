#! /usr/bin/env lua

local lfs = require( 'lfs' )

local routine_name = 'prepare_ClusterMod_stack'

if #arg ~= 1 then
    io.stderr:write( routine_name .. ': ERROR: One command line argument is expected: the version of the stack.\n' )
    os.exit( 1 )
end

local stack_version = arg[1]

local script_called_dir = arg[0]:match( '(.*)/[^/]+' )
lfs.chdir( script_called_dir )
local repo_root = lfs.currentdir():match( '(.*)/scripts/ClusterMod_tools' )
local root_dir = repo_root:match( '(.*)/[^/]+' )

dofile( repo_root .. '/scripts/ClusterMod_tools/lmod_emulation.lua' )
dofile( repo_root .. '/etc/SystemDefinition.lua' )
dofile( repo_root .. '/LMOD/SitePackage_helper.lua' )
dofile( repo_root .. '/LMOD/SitePackage_map_toolchain.lua' )
dofile( repo_root .. '/LMOD/SitePackage_arch_hierarchy.lua' )

if ClusterMod_SystemTable[stack_version] == nil then
    io.stderr:write( routine_name .. ': ERROR: The stack version ' .. stack_version .. ' is not recognized as a valid stack.\n' ..
                     'Maybe ClusterMod_SystemTable in etc/SystemDefinition.lua needs updating?\n' )
    os.exit( 1 )
end

--
-- Internal functions
--

function create_symlink( target, name )

    local lfs = require( 'lfs' )
    
    --
    -- Note that we prefer to always re-create the link if it exists already.
    -- So far we know no way to figure out if the link is pointing to the right file,
    -- and we may run this script simply because some links have changed.
    --
    local name_attrs = lfs.symlinkattributes( name )
    if name_attrs == nil then
        -- This is a new file
        print( '\nCreating symlink: ' .. target .. ' -> ' .. name )
        lfs.link( target, name, true )
    elseif name_attrs.mode == 'link' then
        if name_attrs.target == nil then
            print( '\nLink ' .. name .. ' exists but cannot determine the target, so re-creating symlink ' .. target .. ' -> ' .. name )
            os.remove( name )
            lfs.link( target, name, true )
        elseif name_attrs.target == target then
            print( '\nLink ' .. name .. ' exists and is pointing to the right target ' .. target )
        else
            print( '\nLink ' .. name .. ' exists but current target ' .. name_attrs.target .. ' is different, re-creating symlink ' .. target .. ' -> ' .. name )
            os.remove( name )
            lfs.link( target, name, true )
        end
    elseif name_attrs == 'file' then
        -- Finding a file is somewhat unexpected but we can handle it:
        -- remove the file and create the link.
        print( '\nFile ' .. name .. ' exists, replacing with symlink ' .. target .. ' -> ' .. name )
        os.remove( name )
        lfs.link( target, name, true )
    else
        print( '\n' .. name .. ' exists as a ' .. name_attrs.mode .. ', do not know how to handle this.' )
    end

end


--
-- Gather all dependent architectures
--

print( 'Computing all OS-arch combinations needed for ' .. ClusterMod_StackName .. '/' .. stack_version .. '...' )

local OSArchTable = {}
local OSArchTableWorker = {}

for OS,_ in pairs( ClusterMod_SystemTable[stack_version] ) do

    for _,arch in ipairs( ClusterMod_SystemTable[stack_version][OS] ) do

        for _,subarch in ipairs( get_osarchs_reverse( stack_version, OS, arch ) ) do

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

    local appl_modules = pathJoin( root_dir, get_system_module_dir( longname, ClusterMod_StackName, stack_version ) )
    print( 'Application modules:    ' .. appl_modules )
    mkDir( appl_modules )

    local infra_modules = pathJoin( root_dir, get_system_inframodule_dir( longname, ClusterMod_StackName, stack_version ) )
    print( 'Infrastructure modules: ' .. infra_modules )
    mkDir( infra_modules )

    local SW_dir = pathJoin( root_dir, get_system_SW_dir( longname, ClusterMod_StackName, stack_version ) )
    print( 'Software directory:     ' .. SW_dir )
    mkDir( SW_dir )

    local EBrepo_dir = pathJoin( root_dir, 'mgmt', get_system_EBrepo_dir( longname, ClusterMod_StackName, stack_version ) )
    print( 'EBrepo_files directory: ' .. EBrepo_dir )
    mkDir( EBrepo_dir )

end

--
-- -   Now the directories for the actual modules
--
--     *   Software stack module
--

local stack_dir = pathJoin( root_dir, 'modules-infrastructure/stack', ClusterMod_StackName )
mkDir( stack_dir )

local link_target = get_versionedfile( stack_version,
    pathJoin( root_dir, 'UAntwerpen-modules/generic-modules', ClusterMod_StackName ),
    '', '.lua' )    
create_symlink( link_target, pathJoin( stack_dir, stack_version .. '.lua' ) )

--
--    *    Architecture modules
--

local arch_dir = pathJoin( root_dir, 'modules-infrastructure/arch', ClusterMod_StackName, stack_version )

mkDir( pathJoin( arch_dir, 'arch' ) )

local link_target = get_versionedfile( stack_version,
    pathJoin( root_dir, 'UAntwerpen-modules/generic-modules/clusterarch' ),
    '', '.lua' )

for _,longname in ipairs( OSArchTable ) do

    local link_name = pathJoin( arch_dir, 'arch', longname .. '.lua' )
    create_symlink( link_target, link_name )

end

--
--    *    Create a .modulerc.lua with synonyms for the arch modules
--

print( '\nCreating ' .. pathJoin( arch_dir, '.modulerc.lua' ) .. '...' )

local f = io.open( pathJoin( arch_dir, '.modulerc.lua' ), 'w' )

for cluster,arch in pairs( ClusterMod_ClusterMap[stack_version] ) do
    f:write( 'module_version( \'arch/' .. arch .. '\' , \'' .. cluster .. '\' )\n' )
end

f:close()


