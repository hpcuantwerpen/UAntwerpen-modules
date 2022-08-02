#! /usr/bin/env lua

local lfs = require( 'lfs' )

local routine_name = 'prepare_ClusterMod'
local stack_name = 'calcua'

if #arg ~= 1 then
    io.stderr:write( routine_name .. ': ERROR: One command line argument is expected: software stack configuration file.\n' )
    os.exit( 1 )
end

dofile( arg[1] )

dofile( systemdefinition )

dofile( repo_modules .. '/scripts/ClusterMod_tools/lmod_emulation.lua' )
dofile( repo_modules .. '/LMOD/SitePackage_helper.lua' )
dofile( repo_modules .. '/LMOD/SitePackage_map_toolchain.lua' )
dofile( repo_modules .. '/LMOD/SitePackage_arch_hierarchy.lua' )


--
-- Internal functions
--

function create_symlink( target, name )

    local lfs = require( 'lfs' )
    local debug = false
    
    --
    -- Note that we prefer to always re-create the link if it exists already.
    -- So far we know no way to figure out if the link is pointing to the right file,
    -- and we may run this script simply because some links have changed.
    --
    local name_attrs = lfs.symlinkattributes( name )
    if name_attrs == nil then
        -- This is a new file
        if debug then print( '\nCreating symlink: ' .. name .. ' -> ' .. target ) end
        lfs.link( target, name, true )
    elseif name_attrs.mode == 'link' then
        if name_attrs.target == nil then
            print( '\nWARNING create_symlink: lfs.symlinkattributes did not return a valid target, so re-creating symlink ' .. name .. ' -> ' .. target )
            os.remove( name )
            lfs.link( target, name, true )
        elseif name_attrs.target == target then
            if debug then print( '\nLink ' .. name .. ' exists and is pointing to the right target ' .. target ) end
        else
            if debug then print( '\nLink ' .. name .. ' exists but current target ' .. name_attrs.target .. ' is different, re-creating symlink ' .. name .. ' -> ' .. target ) end
            os.remove( name )
            lfs.link( target, name, true )
        end
    elseif name_attrs.mode == 'file' then
        -- Finding a file is somewhat unexpected but we can handle it:
        -- remove the file and create the link.
        if debug then print( '\nFile ' .. name .. ' exists, replacing with symlink ' .. name .. ' -> ' .. target ) end
        os.remove( name )
        lfs.link( target, name, true )
    else
        print( '\nWARNING create_symlink: ' .. name .. ' exists as a ' .. name_attrs.mode .. ', do not know how to handle this.' )
    end

end

-- ----------------------------------------------------------------------------
--
-- What happens in the script:
-- -   Build an overview of all architectures for all software stacks
-- -   Set up the infrastructure modules structure
--     -   Framework of calcua and arch modules
--     -   Directory for each stack and arch in the stack
-- -   Set up the EasyBuild modules structure
-- -   Set up the software directories
-- -   Set up the structure for the EasyBuild files repo
-- -   Other work:
--     -   Create sources subdirectory that will be used by EasyBuild.
--     -   Create (actually link) the directory with the display style modules.
--     -   Create (actually link) the initialisation module.
--     -   .modulerc.lua files for each stack with the cluster/ synonyms.
-- 
-- ----------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
--
-- -   Build an overview of all architectures for all software stacks
--     We'll also build a sorted list of stacks simply to show output in a
--     somewhat reasonable and predictable order.
--

local stack_list = {}
local SystemTable_osarch = {}

for stack_version,_ in pairs( ClusterMod_SystemTable )
do
    if stack_version ~= 'system' and stack_version ~= 'manual' then
        table.insert( stack_list, stack_version )
    end
end

table.sort( stack_list )

table.insert( stack_list, 1, 'system' )
table.insert( stack_list, 'manual' )

for _,stack_version in ipairs( stack_list )
do

    SystemTable_osarch[stack_version] = {}
    local OSArchTableWorker = {}

    for OS,_ in pairs( ClusterMod_SystemTable[stack_version] ) do

        for _,arch in ipairs( ClusterMod_SystemTable[stack_version][OS] ) do

            for _,subarch in ipairs( get_long_osarchs_reverse( stack_version, OS, arch ) ) do

                if OSArchTableWorker[subarch] == nil then
                    OSArchTableWorker[subarch] = true
                    table.insert( SystemTable_osarch[stack_version], subarch )
                end

            end

        end

    end

end -- for _,stack_version in ipairs( stack_list )

-- ----------------------------------------------------------------------------
--
-- -   Create the directories for infrastructure and easybuild modules, sofware
--     and EasyBuild repo files for each stack and architecture.
--

for _,stack_version in ipairs( stack_list )
do

    print( '\nSetting up or confirming the structure for calcua/' .. stack_version .. '.' )

    --
    -- Stack module
    --

    if stack_version ~=  'manual'
    then

        local stack_dir = pathJoin( installroot, 'modules-infrastructure/stack', ClusterMod_StackName )
        mkDir( stack_dir )

        local stack_modulefile = pathJoin( stack_dir, stack_version .. '.lua' )
        local link_target = get_versionedfile( stack_version,
            pathJoin( repo_modules, 'generic-modules/stack' ), '', '.lua' )

        print( '\n- Creating/confirming the ' .. ClusterMod_StackName .. '/' .. stack_version .. ' module ' .. stack_modulefile .. ',\n  linking to ' .. link_target .. '.' )        
        create_symlink( link_target, stack_modulefile )

    end

    --
    -- -   Now do the per arch directories and modules.
    --

    for _,osarch in ipairs( SystemTable_osarch[stack_version] ) 
    do

        print( '\n- Creating or confirming directories for ' .. osarch .. ':' )

        local SW_dir = pathJoin( installroot, get_system_SW_dir( osarch, stack_name, stack_version ) )
        print( '  - Software directory:     ' .. SW_dir )
        mkDir( SW_dir )
    
        if stack_version ~= 'manual'
        then

            local appl_modules = pathJoin( installroot, get_system_module_dir( osarch, stack_name, stack_version ) )
            print( '  - Application modules:    ' .. appl_modules )
            mkDir( appl_modules )
        
            local infra_modules = pathJoin( installroot, get_system_inframodule_dir( osarch, stack_name, stack_version ) )
            print( '  - Infrastructure modules: ' .. infra_modules )
            mkDir( infra_modules )
        
            local EBrepo_dir = pathJoin( installroot, 'mgmt', get_system_EBrepo_dir( osarch, stack_name, stack_version ) )
            print( '  - EBrepo_files directory: ' .. EBrepo_dir )
            mkDir( EBrepo_dir )  
            
            --
            -- Finally the arch module
            --

            local arch_dir = pathJoin( installroot, 'modules-infrastructure/arch', ClusterMod_StackName, stack_version, 'arch' )
            mkDir( arch_dir )
                        
            local arch_modulefile = pathJoin( arch_dir, osarch .. '.lua' )
            local link_target = get_versionedfile( stack_version,
                pathJoin( repo_modules, 'generic-modules/clusterarch' ), '', '.lua' )                

            print( '  - Creating/confirming the arch/' .. osarch .. ' module ' .. arch_modulefile .. ',\n    linking to ' .. link_target .. '.' )
            create_symlink( link_target, arch_modulefile )

        end -- if stack_version ~= manual


    end -- for _,osarch in ipairs( OSArchTable )


end -- for _,stack_version in ipairs( stack_list )


--
-- Install the ClusterMod-init module
--
local init_dir = pathJoin( installroot, 'modules-infrastructure/init', ClusterMod_ClusterName .. '-init' )
mkDir( init_dir )
local target_dir = pathJoin( repo_modules, 'generic-modules/ClusterMod-init' )
print( '\nInstalling the ' .. ClusterMod_ClusterName .. '-init module(s)' )
for file in lfs.dir( target_dir )
do
    if file:match( '.+%.lua' )
    then
        local init_modulefile = pathJoin( init_dir, file )
        local target_modulefile = pathJoin( target_dir, file )
        print( '- Creating/confirming the ' .. ClusterMod_ClusterName .. '-init/' .. file:gsub( '%.lua', '') .. ' module ' .. init_modulefile ..
               '\n  linking to ' .. target_modulefile .. '.' )
        create_symlink( target_modulefile, init_modulefile )
    end
end

--
-- Link the style modifier modules
--
local stylemod_dir = pathJoin( installroot, 'modules-infrastructure/', 'StyleModifiers' )
local target_dir = pathJoin( repo_modules, 'generic-modules/StyleModifiers' )
print( '\nInstalling the style modifier modules ' .. stylemod_dir .. ',\nlinking to ' .. target_dir )
create_symlink( target_dir, stylemod_dir )

--
-- Create the sources subdirectory for EasyBuild
--

local sources_dir = pathJoin( installroot, 'sources' )
print( '\nCreating the sources directory ' .. sources_dir )
mkDir( sources_dir )

print()

-- TODO:
-- .modulerc.lua files with synonyms????



