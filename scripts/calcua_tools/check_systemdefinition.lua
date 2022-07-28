#! /usr/bin/env lua

local lfs = require( 'lfs' )

local routine_name = 'check_systemdefinition'

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

local test_number = 0

local number_warnings = 0
local number_errors = 0

--
-- Preparation: Build a list of CPU architecytures in the node types and in general.
--

local node_cpu_list = {} -- All CPU types that are found directly in the node types

for _,node_long_osarch in ipairs( CalcUA_NodeTypes )
do
    node_cpu_list[extract_cpu(node_long_osarch)] = true
end

local full_cpu_list = {} -- All CPU types that are found directly in the node types or 
                         -- can be derived from them via any of the tables in CalcUA_reduce_cpu
                         -- or are found in CalcUA_SystemTable
                         -- or are found in CalcUA_reduce_top_arch

for _,reduce_cpu in pairs( CalcUA_reduce_cpu )
do

    for cpu,_ in pairs( node_cpu_list )
    do
    
        full_cpu_list[cpu] = true
        local w_cpu = cpu
        while reduce_cpu[w_cpu] ~= nil
        do
            w_cpu = reduce_cpu[w_cpu]
            full_cpu_list[w_cpu] = true
        end
    
    end -- for cpu,_ in pairs( node_cpu_list )

end -- for _,reduce_cpu in pairs( CalcUA_reduce_cpu )

-- Gather from CalcUA_SystemTable
for stack_version,system_table in pairs( CalcUA_SystemTable )
do
    for osversion,cpu_list in pairs( system_table )
    do
        for _,arch in ipairs( cpu_list)
        do
            use_cpu = extract_cpu_from_arch( arch )
            if use_cpu ~= nil then full_cpu_list[use_cpu] = true end
        end -- for _,arch in ipairs( cpu_list)    
    end -- for osversion,cpulist in pairs( system_table )
end -- for stack_version,system_table in pairs( CalcUA_SystemTable )

-- Gather from CalcUA_reduce_top_arch
for stack_version,reduce_top_arch in pairs( CalcUA_reduce_top_arch )
do
    for from_arch,to_arch in ipairs( reduce_top_arch )
    do 
        local use_cpu = extract_accel( from_arch )
        if use_cpu ~= nil then full_cpu_list[use_cpu] =  true end
        local use_cpu = extract_accel( to_arch )
        if use_cpu ~= nil then full_cpu_list[use_cpu] =  true end
    end -- for from_arch,to_arch in ipairs( CalcUA_NodeTypes )
end -- for stack_version,reduc_top_arch in pairs( CalcUA_reduce_top_arch )


--
-- Preparation: Build a list of accelerator architecytures in the node types and in general.
--

-- First gather accelerator types from CalcUA_NodeTypes and CalcUA_reduce_top_arch
local full_accel_list = {}
full_accel_list['noaccel'] = true

-- Gather accelerator types from CalcUA_NodeTypes
for _,node_type in ipairs( CalcUA_NodeTypes )
do 
    local use_accel = extract_accel( node_type )
    if use_accel ~= nil then full_accel_list[use_accel] =  true end
end -- for _,node_type in ipairs( CalcUA_NodeTypes )

-- Gather from CalcUA_SystemTable
for stack_version,system_table in pairs( CalcUA_SystemTable )
do
    for osversion,cpu_list in pairs( system_table )
    do
        for _,arch in ipairs( cpu_list)
        do
            use_accel = extract_accel_from_arch( arch )
            if use_accel ~= nil then full_accel_list[use_accel] = true end
        end -- for _,arch in ipairs( cpu_list)    
    end -- for osversion,cpulist in pairs( system_table )
end -- for stack_version,system_table in pairs( CalcUA_SystemTable )

-- Gather accelerator types from CalcUA_reduce_top_arch
for stack_version,reduce_top_arch in pairs( CalcUA_reduce_top_arch )
do
    for from_arch,to_arch in ipairs( reduce_top_arch )
    do 
        local use_accel = extract_accel( from_arch )
        if use_accel ~= nil then full_accel_list[use_accel] =  true end
        local use_accel = extract_accel( to_arch )
        if use_accel ~= nil then full_accel_list[use_accel] =  true end
    end -- for from_arch,to_arch in ipairs( CalcUA_NodeTypes )
end -- for stack_version,reduc_top_arch in pairs( CalcUA_reduce_top_arch )


--
-- - Check: CalcUA_def_cpu in system definition
--   TODO: Might be moved to SitePackage_arch_hierachy?
--

test_number = test_number + 1
io.stdout:write( 'Test ' .. test_number .. ': Is every CPU type defined and declared generic or not (CalcUA_def_cpu structure)? ' )

number_warnings = 0
number_errors = 0

for cpu,_ in pairs( full_cpu_list )
do

    if CalcUA_def_cpu[cpu] == nil then
        number_errors = number_errors + 1
        io.stdout:write( '\nERROR: cpu type ' .. cpu .. ' not found in CalcUA_def_cpu in the system definition.' )
    elseif CalcUA_def_cpu[cpu] ~= true and CalcUA_def_cpu[cpu] ~= false then
        number_errors = number_errors + 1
        io.stdout:write( '\nERROR: cpu type ' .. cpu .. ' in CalcUA_def_cpu (system definition) does not have a boolean value.' )
    end
    
end -- for cpu,_ in pairs( full_cpu_list )

if number_errors == 0 then
    io.stdout:write( 'PASSED\n' )
else
    io.stdout:write( '\nTest ' .. test_number .. ': Is every CPU type defined and declared generic or not (CalcUA_def_cpu structure) generated ' .. number_errors .. ' error(s).\n' )
end


--
-- - Check: CalcUA_map_cpu_to_gen in system definition
--

test_number = test_number + 1
io.stdout:write( 'Test ' .. test_number .. ': Does every non-generic CPU type map to a generic one in all cases (CalcUA_map_cpu_to_gen structure)? ' )

number_warnings = 0
number_errors = 0

for stack_version,map_cpu_to_gen in pairs( CalcUA_map_cpu_to_gen )
do

    for cpu,_ in pairs( full_cpu_list )
    do

        if map_cpu_to_gen[cpu] == nil and not( CalcUA_def_cpu[cpu] ) then
            number_warnings = number_errors + 1
            io.stdout:write( '\nWARNING: Non-generic cpu type ' .. cpu .. ' not found in CalcUA_map_cpu_to_gen[' .. stack_version .. '] in the system definition.' )
        end
        
    end -- for cpu,_ in pairs( full_cpu_list )

end -- for stack_version,map_cpu_to_gen in pairs( CalcUA_map_cpu_to_gen )

if number_warnings == 0 then
    io.stdout:write( 'PASSED\n' )
else
    io.stdout:write( '\nTest ' .. test_number .. ': Does every non-generic CPU type map to a generic one in all cases (CalcUA_map_cpu_to_gen structure) generated ' .. number_warnings .. ' warning(s).\n' )
end


--
-- - Check: CalcUA_reduce_cpu in system definition
--

test_number = test_number + 1
io.stdout:write( 'Test ' .. test_number .. ': Does every non-generic CPU type map to a more generic one in all cases (CalcUA_reduce_cpu structure)? ' )

number_warnings = 0
number_errors = 0

for stack_version,reduce_cpu in pairs( CalcUA_reduce_cpu )
do

    for cpu,_ in pairs( full_cpu_list )
    do

        if reduce_cpu[cpu] == nil and not( CalcUA_def_cpu[cpu] ) then
            number_warnings = number_errors + 1
            io.stdout:write( '\nWARNING: Non-generic cpu type ' .. cpu .. ' not found in CalcUA_reduce_cpu[' .. stack_version .. '] in the system definition.' )
        end
        
    end -- for cpu,_ in pairs( full_cpu_list )

end -- for stack_version,reduce_cpu in pairs( CalcUA_reduce_cpu )

if number_warnings == 0 then
    io.stdout:write( 'PASSED\n' )
else
    io.stdout:write( '\nTest ' .. test_number .. ': Does every non-generic CPU type map to a more generic one in all cases (CalcUA_reduce_cpu structure) generated ' .. number_warnings .. ' warning(s).\n' )
end


--
-- - Check: map_cpu_long_to_short in SitePackage_arch_hierachy
--

test_number = test_number + 1
io.stdout:write( 'Test ' .. test_number .. ': Does every CPU type have a short equivalent (table map_cpu_long_to_short)? ' )

number_warnings = 0
number_errors = 0

for cpu,_ in pairs( full_cpu_list )
do

    if map_cpu_long_to_short[cpu] == nil then
        number_errors = number_errors + 1
        io.stdout:write( '\nERROR: cpu type ' .. cpu .. ' not found in map_cpu_long_to_short in SitePackage_arch_hierarchy.' )
    end
    
end -- for cpu,_ in pairs( full_cpu_list )

if number_errors == 0 then
    io.stdout:write( 'PASSED\n' )
else
    io.stdout:write( '\nTest ' .. test_number .. ': Does every CPU type have a short equivalent (table map_cpu_long_to_short) generated ' .. number_errors .. ' error().\n' )
end


--
-- - Check: map_accel_long_to_short in SitePackage_arch_hierachy
--   This test is stricter than what is really needed as for some accelerators we may never 
--   need the short name. But it ensures a complete definition and compatible LMOD code.
--

test_number = test_number + 1
io.stdout:write( 'Test ' .. test_number .. ': Does every allerator type have a short equivalent (table map_accel_long_to_short)? ' )

number_warnings = 0
number_errors = 0

for accel,_ in pairs( full_accel_list )
do

    if map_accel_long_to_short[accel] == nil then
        number_errors = number_errors + 1
        io.stdout:write( '\nERROR: Accelereator type ' .. accel .. ' not found in map_accel_long_to_short in SitePackage_arch_hierarchy.' )
    end
    
end -- for accel,_ in pairs( full_accel_list )

if number_errors == 0 then
    io.stdout:write( 'PASSED\n' )
else
    io.stdout:write( '\nTest ' .. test_number .. ': Does every allerator type have a short equivalent (table map_accel_long_to_short) generated ' .. number_errors .. ' error().\n' )
end


--
-- - Check: Does every OS have a short equivalent in map_os_long_to_short?
--

test_number = test_number + 1
io.stdout:write( 'Test ' .. test_number .. ': Does every OS have a short equivalent (table map_os_long_to_short)? ' )

number_warnings = 0
number_errors = 0

-- Gather a list of OSes used in CalcUA_SystemTable. These are stripped from version numbers.
local is_OS = {}

for stack_version,system_table in pairs( CalcUA_SystemTable )
do
    for osversion,_ in pairs( system_table )
    do
        local os = osversion:match( '^([^%d]+)%d' )
        is_OS[os] = true
    end
end

-- Now check if all OSes have a short name.
for os,_ in pairs( is_OS ) 
do
    if map_os_long_to_short[os] == nil then
        number_errors = number_errors + 1
        io.stdout:write( '\nERROR: OS ' .. os .. ' not found in map_os_long_to_short in SitePackage_arch_hierarchy.' )
    end -- if map_os_long_to_short[os] == nil
end -- for os,_ in pairs( is_OS )

if number_warnings == 0 and number_errors == 0 then
    io.stdout:write( 'PASSED\n' )
else
    io.stdout:write( '\nTest ' .. test_number .. ': Does every OS have a short equivalent (table map_os_long_to_short) generated ' .. number_warnings .. ' warning(s) and ' .. number_errors .. ' error(s).\n' )
end


--
-- - Check if the CalcUA_SystemProperties structure contains all required information
--

test_number = test_number + 1
io.stdout:write( 'Test ' .. test_number .. ': Checking CalcUA_SystemProperties in the system definition. ' )

number_warnings = 0
number_errors = 0

for stack_version,_ in pairs( CalcUA_SystemTable )
do

    if CalcUA_SystemProperties == nil then

        number_errors = number_errors + 1
        io.stdout:write( '\nERROR: No entry found in CalcUA_SystemProperties for stack ' .. stack_version )
    
    else

        if stack_version ~= 'manual' then       
            if CalcUA_SystemProperties[stack_version]['EasyBuild'] == nil then
                number_errors = number_errors + 1
                io.stdout:write( '\nERROR: Failed to find the EasyBuild version for stack ' .. stack_version )            
            elseif CalcUA_SystemProperties[stack_version]['EasyBuild'] ~= CalcUA_SystemProperties[stack_version]['EasyBuild']:match( '%d+%.%d+%.%d+' )  then
                number_warnings = number_warnings + 1
                io.stdout:write( '\nWARNING: Suspicious EasyBuild version ' .. CalcUA_SystemProperties[stack_version]['EasyBuild'] .. ' for stack ' .. stack_version )
            end
        end -- if stack_version ~= 'manual'

        if CalcUA_SystemProperties[stack_version]['hierarchy'] == nil then 
            number_errors = number_errors + 1
            io.stdout:write( '\nERROR: Failed to find the hierarchy (2L or 3L) for stack ' .. stack_version )            
        elseif CalcUA_SystemProperties[stack_version]['hierarchy'] ~= '2L' and CalcUA_SystemProperties[stack_version]['hierarchy'] ~= '3L' then
            number_errors = number_errors + 1
            io.stdout:write( '\nERROR: ' .. CalcUA_SystemProperties[stack_version]['hierarchy'] .. ' is an invalid hierarchy for stack ' .. stack_version .. ' (should be 2L or 3L)')            
        end

    end -- if CalcUA_SystemProperties == nil then

end -- for stack_version,_ in CalcUA_SystemTable

if number_warnings == 0 and number_errors == 0 then
    io.stdout:write( 'PASSED\n' )
else
    io.stdout:write( '\nTest ' .. test_number .. ': Checking CalcUA_SystemProperties in the system definition generated ' .. number_warnings .. ' warning(s) and ' .. number_errors .. ' error(s).\n' )
end


--
-- - Check: Checking CalcUA_ClusterMap
--

test_number = test_number + 1
io.stdout:write( 'Test ' .. test_number .. ': Check of CalcUA_ClusterMap ' )

number_warnings = 0
number_errors = 0

for stack_version,cluster_map in pairs( CalcUA_ClusterMap )
do

    if CalcUA_SystemTable[stack_version] == nil then
        number_errors = number_errors + 1
        io.stdout:write( '\nERROR: Stack version ' .. stack_version .. ' of CalcUA_ClusterMap is not defined in CalcUA_SystemTable.' )
    else

        -- Build the list of top architectures for all node types in the cluster for this stack version
        is_supported_cluster_arch = {}
        for _,node_type in ipairs( CalcUA_NodeTypes )
        do
            local actual_osarch = get_calcua_matchingarch( node_type, stack_version, stack_version )
            if actual_osarch ~=  nil then -- Test is needed as some node types may not be supported by all stack versions
                is_supported_cluster_arch[actual_osarch] = true
            end
        end

        -- Now run over the architectures used in CalcUA_ClusterMap[stack_version] = cluster_map
        for alias,requested_arch in pairs( cluster_map )
        do
            if not is_supported_cluster_arch[requested_arch] then
                number_errors = number_errors + 1
                io.stdout:write( '\nERROR: CalcUA_ClusterMap: Alias ' .. alias .. ' for stack version ' .. stack_version ..
                                 ' has an illegal value (' .. requested_arch .. ').' )
            end
        end -- for alias,requested_arch in pairs( cluster_map )

    end -- if CalcUA_SystemTable[stack_version] == nil

end  -- for stack_version,cluster_map in pairs( CalcUA_ClusterMap )

if number_warnings == 0 and number_errors == 0 then
    io.stdout:write( 'PASSED\n' )
else
    io.stdout:write( '\nTest ' .. test_number .. ': Check of CalcUA_ClusterMap generated ' .. number_warnings .. ' warning(s) and ' .. number_errors .. ' error(s).\n' )
end


--
-- - Check: Is each node type supported by at least 1 software stack besides system
--   and manual?
--

test_number = test_number + 1
io.stdout:write( 'Test ' .. test_number .. ': Is every node type supported by software stacks? ' )

number_warnings = 0
number_errors = 0

for _,node_long_osarch in ipairs( CalcUA_NodeTypes )
do

    local supported_stack_list = {}
    local supported_by_system = false
    local supported_by_manual = false
    
    local node_os = extract_os( node_long_osarch )
    
    for stack_version,_ in pairs( CalcUA_SystemTable )
    do

        local node_used_long_osarch = get_calcua_matchingarch( node_long_osarch, stack_version, stack_version )

        if stack_version == 'manual' then
            supported_by_manual = ( node_used_long_osarch ~=  nil )
        elseif stack_version == 'system' then
            supported_by_system = ( node_used_long_osarch ~=  nil )
        else
            if node_used_long_osarch ~= nil then
                table.insert( supported_stack_list, stack_version )
            end
        end

    end -- for stack_version,_ in pairs( CalcUA_SystemTable )

    if not supported_by_manual then
        number_warnings = number_warnings + 1
        io.stdout:write( '\nWARNING: Node type ' .. node_long_osarch .. ' is not supported by the manual software stack (but that is not a hard requirement).' )
    end

    if not supported_by_system then
        number_errors = number_errors + 1
        io.stdout:write( '\nERROR: Note type ' .. node_long_osarch .. ' is not supported by the system software stack.')
    end

    if #supported_stack_list == 0 then
        number_errors = number_errors + 1
        io.stdout:write( '\nERROR: Note type ' .. node_long_osarch .. ' is not supported by any of the regular software stacks.' )
    end

end -- for _,node_long_osarch in ipairs( CalcUA_NodeTypes )

if number_warnings == 0 and number_errors == 0 then
    io.stdout:write( 'PASSED\n' )
else
    io.stdout:write( '\nTest ' .. test_number .. ': Is every node type supported by software stacks generated ' .. number_warnings .. ' warning(s) and ' .. number_errors .. ' error(s).\n' )
end

--
-- - Check: Are the system modules consistent for subarchitectures in regular toolchains?
--

test_number = test_number + 1
io.stdout:write( 'Test ' .. test_number .. ': Are the system modules consistent for subarchitectures? ' )

number_warnings = 0
number_errors = 0

for stack_version,_ in pairs( CalcUA_SystemTable )
do

    if stack_version ~=  'manual' and stack_version ~= 'system' then

        for _,node_type in ipairs( CalcUA_NodeTypes )
        do

            -- Scheme:
            -- Node type
            --   +- Actual architecture for calcua/yyy.mm:                                           osarch_regular
            --   +- Matching arch for system modules for the actual architecture:                    osarch_system     modules: full_system_dirs
            --      +- Subarchitecture under consideration:                                          subarch_regular
            --      +- Matching arch for system modules for the subarchitecture under consideration: subarch_system    modules: system_dirs

            local osarch_regular = get_calcua_matchingarch( node_type, stack_version, stack_version )

            if osarch_regular ~= nil then
                -- Architecture supported by this stack
                local osarch_system  = get_calcua_matchingarch( osarch_regular, stack_version, 'system' )
                local hierarchy = CalcUA_SystemProperties[stack_version] -- Hierarchy of the regular software stack.

                local full_system_dirs = get_system_module_dirs( osarch_system, 'calcua', 'system' )

                if full_system_dirs == nil then 
                    -- Could not determine module dirs for system in this stack, which is an error.

                    number_errors = number_errors + 1
                    io.stdout:write( '\nERROR: Could not find system modules for calcua/' .. stack_version .. ' for node type ' .. node_type  )

                else -- if full_system_dirs == nil
                    -- Found system modules for this software stack, now compare with those for subarchs of long_osarch_regular.

                    local use_os =   extract_os(   osarch_regular )
                    local use_arch = extract_arch( osarch_regular )
                    local subarchs = get_long_osarchs_reverse( stack_version, use_os, use_arch )

                    local is_system_module_dir = {}
                    for _,system_module_dir in ipairs( full_system_dirs ) do is_system_module_dir[system_module_dir] = true end

                    local function test_subarch( subarch_regular )

                        local subarch_system = get_calcua_matchingarch( subarch_regular, stack_version, 'system' ) -- Corresponding system arch for arch/subarchs[2]

                        if subarch_system == nil then
                            number_errors = number_errors + 1
                            io.stdout:write( '\nERROR: node type ' .. node_type .. ' in stack calcua/' .. stack_version ..
                                            ' uses the actual architecture ' .. osarch_regular .. 
                                            ' and actual architecture for calcua/system modules ' .. osarch_system .. 
                                            ' but no corresponding architecture for calcua/system modules is found for subarch ' .. subarch_regular )
                        else
                            local system_dirs = get_calcua_matchingarch(  subarch_system, stack_version, 'system' )      -- Corresponding module dirs in system
                            if system_dirs == nil then
                                number_errors = number_errors + 1
                                io.stdout:write( '\nERROR: node type ' .. node_type .. ' in stack calcua/' .. stack_version ..
                                                ' uses the actual architecture ' .. osarch_regular .. 
                                                ' and actual architecture for calcua/system modules ' .. osarch_system .. 
                                                ' but no system modules are found for subarch ' .. subarch_regular .. 
                                                ' with for calcua/system the corresponding architecture ' .. subarch_system )
                            else
                                local OK = true
                                for dir,_ in ipairs( system_dirs ) do OK = OK and is_sytem_module_dir( dir ) end
                                if not OK then
                                    io.stdout:write( '\nERROR: node type ' .. node_type .. ' in stack calcua/' .. stack_version ..
                                                ' uses the actual architecture ' .. osarch_regular .. 
                                                ' and actual architecture for calcua/system modules ' .. osarch_system ..
                                                ' , subarch ' .. subarch_regular .. ' uses corresponding architecture ' .. subarch_system ..
                                                ' for calcua/system modules, but the module directories of both calcua/system stacks are inconsistent:' ..
                                                '\n   * full stack: ' .. table.concat( full_system_dirs, ', ' ) ..
                                                '\n   * subarch: ' .. table.concat( system_dirs, ', ' ) )
                                end -- if not OK
                            end -- if system_dirs == nil
                        end -- if subarch_system == nil

                    end -- Definition function test_subarch

                    if hierarchy == '3L' then 
                        -- Need to check the middle level which is subarchs[2]
                        test_subarch( subarchs[2] )
                    end -- if hierarchy == '3L'
                    
                    -- Always check the generic level.
                    test_subarch( subarchs[1] )


                end -- if full_system_dirs == nil

            end -- if long_osarch_regular ~= nil then

        end -- for _,node_type in ipairs( CalcUA_NodeType )

    end -- if stack_version ˜=  'manual' and stack_version ~= 'system' then

end -- for stack_version,_ in pairs( CalcUA_SystemTable )

if number_warnings == 0 and number_errors == 0 then
    io.stdout:write( 'PASSED\n' )
else
    io.stdout:write( '\nTest ' .. test_number .. ': Are the system modules consistent for subarchitectures generated ' .. number_warnings .. ' warning(s) and ' .. number_errors .. ' error(s).\n' )
end


print( '\n' )


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
        
            if node_used_long_osarch == nil then
                print( '  * Stack ' .. stack_version .. ' is not supported on this node type.' )
            else
                print( '  * Stack ' .. stack_version .. ' is offered through architecture ' ..  
                       node_used_long_osarch .. '.' )
            end
        
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

