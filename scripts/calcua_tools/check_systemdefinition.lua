#! /usr/bin/env lua

local lfs = require( 'lfs' )

local routine_name = 'check_clusternode'

if #arg ~= 1 then
    io.stderr:write( routine_name .. ': ERROR: One command line argument is expected: path to the system definition file.\n' )
    os.exit( 1 )
end

local systemdefinition_file = arg[1]
if systemdefinition_file:find( '/' ) ~= 1 then
    -- Not an absolute path, it does not start with a slash.
    systemdefinition_file = lfs.currentdir() .. '/' .. systemdefinition_file
end

local script_called_dir = arg[0]:match( '(.*)/[^/]+' )
lfs.chdir( script_called_dir )
local repo_root = lfs.currentdir():match( '(.*)/scripts/calcua_tools' )
local root_dir = repo_root:match( '(.*)/[^/]+' )

dofile( repo_root .. '/scripts/calcua_tools/lmod_emulation.lua' )
dofile( systemdefinition_file )
dofile( repo_root .. '/LMOD/SitePackage_helper.lua' )
dofile( repo_root .. '/LMOD/SitePackage_system_info.lua' )
dofile( repo_root .. '/LMOD/SitePackage_map_toolchain.lua' )
dofile( repo_root .. '/LMOD/SitePackage_arch_hierarchy.lua' )

-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
--
-- Checks of the system definition file
--
-- -----------------------------------------------------------------------------


print( '\n1. Checks of the file' )
print( '=====================\n' )
print( 'Checking the system definition file ' .. systemdefinition_file .. '.' )
print( 'These checks are by no means a guarantee that the file is correct and consistent but at least some problems can be detected.\n')

-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
--
-- Analysis of available stacks and architectures in the stack
--
-- -----------------------------------------------------------------------------


print( '2. Available stacks and supported architectures' )
print( '===============================================\n' )

-- -----------------------------------------------------------------------------
--
-- Make a sorted list of stack versions. system goes first, manual goes last.
--

local stack_list = {}

for stack_version,_ in pairs( CalcUA_SystemTable )
do
    if stack_version ~= 'system' and stack_version ~= 'manual' then
        table.insert( stack_list, stack_version )
    end
end

table.sort( stack_list )

table.insert( stack_list, 1, 'system' )
table.insert( stack_list, 'manual' )

print( '- Stacks supported by this system definition (including system and manual):\n  * ' ..
       table.concat( stack_list, '\n  * ') )


-- -----------------------------------------------------------------------------
--
-- Make a list of architectures and subarchitectures that are needed for each
-- version of the software stack, including system and manual.
--

local SystemTable_long_osarch = {}

for _,stack_version in ipairs( stack_list )
do

    SystemTable_long_osarch[stack_version] = {}
    local OSArchTableWorker = {}

    for OS,_ in pairs( CalcUA_SystemTable[stack_version] ) do

        for _,arch in ipairs( CalcUA_SystemTable[stack_version][OS] ) do

            for _,subarch in ipairs( get_long_osarchs_reverse( stack_version, OS, arch ) ) do

                if OSArchTableWorker[subarch] == nil then
                    OSArchTableWorker[subarch] = true
                    table.insert( SystemTable_long_osarch[stack_version], subarch )
                end

            end

        end

    end

    print( '- Detected the following OS-arch combinations for ' .. stack_version  ..  ':\n  * ' .. 
           table.concat( SystemTable_long_osarch[stack_version], '\n  * ') )
    
end


-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
--
-- Analysis of node types, stacks and architectures for each typ
--
-- -----------------------------------------------------------------------------

print( '\n' )
print( '3. Available node types with their stacks and supported architectures' )
print( '=====================================================================\n' )


for _,node_long_osarch in ipairs( CalcUA_NodeTypes )
do

    print( '- Node type: ' .. node_long_osarch ) 
    
    local node_os = extract_os( node_long_osarch )
    
    for _,stack_version in ipairs( stack_list )
    do

        if CalcUA_SystemTable[stack_version][node_os] == nil then
        
            print( '  * Stack ' .. stack_version .. ' is not supported on this node type.' )
            
        else
        
            -- local node_used_long_osarch = get_calcua_top( node_long_osarch, stack_version )
            local node_used_long_osarch = get_calcua_matchingarch( node_long_osarch, stack_version, stack_version )
        
            print( '  * Stack ' .. stack_version .. ' is offered through architecture ' ..  
                   node_used_long_osarch .. '.' )
        
        
        
        
        end -- else-part if CalcUA_SystemTable[stack_version][node_os] == nil

    end -- for _,stack_version in ipairs( stack_list )

end -- for _,node_long_osarch in ipairs( CalcUA_NodeTypes )


-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
--
-- Directories for each stack and each arch module
--
-- -----------------------------------------------------------------------------

print( '\n' )
print( '4. Relevant directories per stack and arch module in the stack' )
print( '==============================================================\n' )

for _,stack_version in ipairs( stack_list )
do

    local hierarchy = CalcUA_SystemProperties[stack_version]['hierarchy']
        
    if stack_version == 'manual' then 
        print( '- Directory structure for stack ' .. stack_version .. ' (' .. hierarchy .. '):' )
    else
        local easybuild_version = CalcUA_SystemProperties[stack_version]['EasyBuild']
        print( '- Directory structure for stack ' .. stack_version .. 
               ' (' .. hierarchy .. ' with EasyBuild ' .. easybuild_version .. '):' )
    end
    
    for _,long_osarch in ipairs( SystemTable_long_osarch[stack_version] )
    do
        
        if stack_version == 'manual' then
            print( '  * Architecture ' .. long_osarch .. ':' )
        else
            print( '  * module arch/' .. long_osarch .. ':' )
        end
        
        -- Check if there is an cluster/* alternative name for the architecture
        local alternatives = {}
        if CalcUA_ClusterMap[stack_version] ~= nil then
            for name,w_long_osarch in pairs( CalcUA_ClusterMap[stack_version] ) do
                if long_osarch == w_long_osarch then
                    table.insert( alternatives, 'cluster/' .. name )
                end
            end
        end
        
        if #alternatives == 0 then
            print( '    + No cluster/* alternative names found.' )
        else
            print( '    + Found cluster/* alternatives: ' .. table.concat( alternatives, ', ' ) )
        end
        
        -- Check if there is an node/* alternative name for the architecture
        alternatives = {}
        for _,node_type in ipairs( CalcUA_NodeTypes )
        do
            local use_long_osarch = get_calcua_matchingarch( node_type, stack_version, stack_version )
            if use_long_osarch == long_osarch then
                table.insert( alternatives, 'node/' .. node_type )
            end 
        end  -- for _,node_types = ipairs( CalcUA_NodeTypes )
        
        if #alternatives == 0 then
            print( '    + No node/* alternative names found.' )
        else
            print( '    + Found node/* alterantives: ' .. table.concat( alternatives, ', ' ) )
        end
        
        
        -- Top module directory
        if stack_version == 'manual' then
            print( '    + No module directory for this stack' )
        else
            print( '    + System-wide modules in ' .. get_system_module_dir( long_osarch, 'calcua', stack_version ) )
        end
        
        -- SW directory
        print( '    + System-wide software in ' .. get_system_SW_dir( long_osarch, 'calcua', stack_version ) )
        
        -- EBrepo_files directory
        if stack_version == 'manual' then
            print( '    + No EBrepo_files directory for this stack' )
        else
            print( '    + System-wide EasyBuild repository for installed EasyConfigs (ebrepo_files) in ' .. 
                   get_system_EBrepo_dir( long_osarch, 'calcua', stack_version ) )
        end
        
        -- Construct the MODULEPATH of system modules.       
        if stack_version == 'manual' then
        
            print( '    + No MODULEPATH as there are no modules.' )
        
        else
        
            local moduledirs = {} 
            
            -- First build in reverse order (which actually corresponds to the order of prepend_path
            -- calls in the module file)

            local long_osarch_system = get_calcua_matchingarch( long_osarch, stack_version, 'system' )
            local system_dirs = get_system_module_dirs( long_osarch_system, 'calcua', 'system' )
            if system_dirs == nil then
                io.stderr.write( 'No system modules found for ' .. stack_version .. '. This points to an error in the module system or cluster definition.\n' )
            else
                for _,system_dir in ipairs( system_dirs ) do
                    table.insert( moduledirs, system_dir )
                end
            end
            
            if stack_version ~= 'system' then 
                local stack_dirs = get_system_module_dirs( long_osarch, 'calcua', stack_version )
                if stack_dirs == nil then
                    io.stderr.write( 'No regular modules found for ' .. stack_version .. '. This points to an error in the module system or cluster definition.\n' )
                else
                    for _,stack_dir in ipairs( stack_dirs ) do
                        table.insert( moduledirs, stack_dir )
                    end
                end
            end -- if stack_version ~= 'system'
        
            local inframodule_dir = get_system_inframodule_dir( long_osarch, 'calcua', stack_version )
            if inframodule_dir == nil then
                io.stderr.write( 'No infrastructure modules found for ' .. stack_version .. '. This points to an error in the module system or cluster definition.\n' )
            else
                table.insert( moduledirs, inframodule_dir )
            end
            
            -- Now turn around the order.
            
            local w_moduledirs = {}
            for _,mdir in ipairs( moduledirs ) do
                table.insert( w_moduledirs, 1, mdir )
            end

            print( '    + System-wide module directories added to MODULEPATH):\n      x ' .. table.concat( w_moduledirs, '\n      x ' ) )

        end -- else-part if stack_version == 'manual' then

        
        

    end -- for long_osarch,_ in pairs( SystemTable_long_osarch[stack_version] )

end -- for _,stack_version in ipairs( stack_list )

print()

