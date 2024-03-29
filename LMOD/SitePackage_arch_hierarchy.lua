-- -----------------------------------------------------------------------------
--
-- The following mapping is used to define generic versions of specific
-- architectures.
--
-- NOTE: Current restrictions of the implementation
--   * OS version numbers are integers and OS names only include regular
--     characters. If not , the conversion function between long and short names
--     may fail.
--

map_os_long_to_short = {
    ['redhat'] = 'RH',
}

map_cpu_long_to_short = {
    ['x86_64']      = 'x86_64',
    ['zen3']        = 'zen3',
    ['zen2']        = 'zen2',
--    ['sandybridge'] = 'SNB',
    ['ivybridge']   = 'IVB',
    ['broadwell']   = 'BRW',
    ['skylake']     = 'SKLX',
}

map_accel_long_to_short = {
    ['noaccel']  = 'host',
    ['P5000']    = 'NVGP61GL',
    ['pascal']   = 'NVCC60',
    ['ampere']   = 'NVCC80',
    ['arcturus'] = 'GFX908',
    ['aurora1']  = 'NEC1',
}


-- -----------------------------------------------------------------------------
--
-- Functions to work with long or short full names
--
-- extract_os( name )    : Extract the first part of the osarch string, the OS
-- extract_cpu( name )   : Extract the second part of the osarch string, the CPU
-- extract_accel( name ) : Extract the third part of the osarch, the accelerator, 
--                         or nil if not present
-- extract_arch( name )  : Extract CPU + accelerator
-- extract_cpu_from_arch( name )  : Extract the CPU part from the arch string.
-- extract_accel_from_arch( name) : Extract the accelerator part from the arch string

function extract_os( name )

    return name:match( '([^-]+)-' )

end

function extract_cpu( name )

    return name:match( '[^-]+-([^-]+)' )

end

function extract_accel( name )

    return name:match( '[^-]+-[^-]+-(.*)' )

end

function extract_arch( name )

    return name:match( '[^-]+-(.*)' )

end

function extract_cpu_from_arch( name )

    return name:match( '([^-]+)' )

end

function extract_accel_from_arch( name )

    return name:match( '[^-]+-(.*)' )

end




-- -----------------------------------------------------------------------------
--
-- Function to populate a stack version in the cache to quickly test if
-- an os-architecture string is supported in a software stack.
--
-- The function has 1 input argument:
--   1. The version of the stack, can be manual or system.
--

function populate_cache_subosarchs( stack_version )

    if ClusterMod_cache_subosarchs ~= nil and ClusterMod_cache_subosarchs[stack_version] ~= nil then
        return -- Already populated so we do nothing.
    end
    
    if ClusterMod_SystemTable[stack_version] == nil then
        return  -- Illegal value for stack_version but for now we simply return and do nothing.
    end

    if ClusterMod_cache_subosarchs == nil then
        ClusterMod_cache_subosarchs = {}
    end
    
    if ClusterMod_cache_subosarchs[stack_version] == nil then
        ClusterMod_cache_subosarchs[stack_version] = {}
    end

    local matching_key = get_matching_cputogen_key( stack_version )

    for OS,_ in pairs( ClusterMod_SystemTable[stack_version] )
    do

        for _,arch in ipairs( ClusterMod_SystemTable[stack_version][OS] )
        do
            local CPU = extract_cpu_from_arch( arch )
            local accel = extract_accel_from_arch( arch )
            
            local osarch = OS .. '-' .. arch
            ClusterMod_cache_subosarchs[stack_version][osarch] = true
            
            if arch ~= CPU and ClusterMod_SystemProperties[stack_version]['hierarchy'] == '3L' then
                osarch = OS .. '-' .. CPU
                ClusterMod_cache_subosarchs[stack_version][osarch] = true
            end
                
            if ClusterMod_map_cpu_to_gen[matching_key][CPU] ~= nil then
                osarch = OS .. '-' .. ClusterMod_map_cpu_to_gen[matching_key][CPU]
                ClusterMod_cache_subosarchs[stack_version][osarch] = true
            end            
            
        end -- for _,arch in ipairs( ClusterMod_SystemTable[stack_version][OS] )
        
    end -- for OS,_ in pairs( ClusterMod_SystemTable[stack_version] )
    
    -- DEBUG CODE
    -- print( 'DEBUG: populate_cache_subosarchs: found following architectures for ' .. stack_version .. ':' )
    -- for key,_ in pairs( ClusterMod_cache_subosarchs[stack_version] ) do print( '  ' .. key ) end
    -- print( 'DEBUG: end output' )
    
end


-- -----------------------------------------------------------------------------
--
-- Function to populate a stack version in the cache to quickly test if
-- an architecture string is supported in a software stack and OS.
--
-- The function has 1 input argument:
--   1. The version of the stack, can be manual or system.
--

function populate_cache_subarchs( stack_version, os_version )

    if ClusterMod_cache_subarchs ~= nil and ClusterMod_cache_subarchs[stack_version] ~= nil 
       and ClusterMod_cache_subarchs[stack_version[os_version]] ~=  nil then
        return -- Already populated so we do nothing.
    end
    
    if ClusterMod_SystemTable[stack_version] == nil then
        return  -- Illegal value for stack_version but for now we simply return and do nothing.
    end

    if ClusterMod_SystemTable[stack_version][os_version] == nil then
        return  -- Illegal value for os_version for this stack_version, but for now we simply return and do nothing..
    end

    if ClusterMod_cache_subarchs == nil then
        ClusterMod_cache_subarchs = {}
    end
    
    if ClusterMod_cache_subarchs[stack_version] == nil then
        ClusterMod_cache_subarchs[stack_version] = {}
    end

    if ClusterMod_cache_subarchs[stack_version][os_version] == nil then
        ClusterMod_cache_subarchs[stack_version][os_version] = {}
    end

    local matching_key = get_matching_cputogen_key( stack_version )

    for _,arch in ipairs( ClusterMod_SystemTable[stack_version][os_version] )
    do
        local CPU = extract_cpu_from_arch( arch )
        local accel = extract_accel_from_arch( arch )
        
        ClusterMod_cache_subarchs[stack_version][os_version][arch] = true
        
        if arch ~= CPU and ClusterMod_SystemProperties[stack_version]['hierarchy'] == '3L' then
            ClusterMod_cache_subarchs[stack_version][os_version][CPU] = true
        end
            
        if ClusterMod_map_cpu_to_gen[matching_key][CPU] ~= nil then
            local gencpu = ClusterMod_map_cpu_to_gen[matching_key][CPU]
            ClusterMod_cache_subarchs[stack_version][os_version][gencpu] = true
        end            
        
    end -- for _,arch in ipairs( ClusterMod_SystemTable[stack_version][OS] )
   
    -- -- DEBUG CODE
    -- print( 'DEBUG: populate_cache_subarchs: found following architectures for ' .. stack_version .. ' and OS ' .. os_version .. ':' )
    -- for key,_ in pairs( ClusterMod_cache_subarchs[stack_version][os_version] ) do print( '  ' .. key ) end
    -- print( 'DEBUG: end output' )
    
end


-- -----------------------------------------------------------------------------
--
-- get_osarchs
--
-- Input arguments:
--   * stack_version: Version of the software stack (or `system` for the
--     software installed against the system or in manual mode).
--     The routine also accpets versions in yyyymm format.
--   * os: Name (with version) of the OS (currently only redhat8)
--   * arch: Architecture, e.g., zen2-noaccel or x86_64.
--
-- Output: A table with the chain of architectures, each a string with two or
-- three dash-separated entities: OS (+version), base CPU architecture and
-- accelerator architecture, using the long names.
--
-- The order is from the least generic to the most generic one.
--
function get_osarchs( stack_version, os, arch )

    local result = {}
    local version = map_toolchain( stack_version )

    if version == nil then
        -- This is actually an error as we do not recognize the
        -- version of the stack.
        return nil
    end

    local matching_version = get_matching_cputogen_key( stack_version )

    if ClusterMod_SystemProperties[stack_version]['hierarchy'] == '3L' then
        local cpu = extract_cpu_from_arch( arch )
        local gencpu = ClusterMod_map_cpu_to_gen[matching_version][cpu]
        table.insert( result, os .. '-' .. arch )
        if cpu ~= arch then
            table.insert( result, os .. '-' .. cpu )
        end
        if gencpu ~= nil then
            table.insert( result, os .. '-' .. gencpu )
        end
    else
        local cpu = extract_cpu_from_arch( arch )
        local gencpu = ClusterMod_map_cpu_to_gen[matching_version][cpu]
        table.insert( result, os .. '-' .. arch )
        if gencpu ~= nil then
            table.insert( result, os .. '-' .. gencpu )
        end
    end

    return result

end


-- -----------------------------------------------------------------------------
--
-- Function get_osarchs_reverse( stack_version, os, arch )
--
-- Input arguments:
--   * stack_version: Version of the software stack (or `system` for the
--     software installed against the system or or 'manual' for  manual mode).
--     It must be a valid software stack version defined in ClusterMod_SystemTable
--     etc. in etc/SystemDefinition.lua
--   * os: Name (with version) of the OS
--   * arch: Architecture, e.g., zen2-noaccel or x86_64.
--
-- Output: A table with the chain of architectures, each a string with two or
-- three dash-separated entities: OS (+version), base CPU architecture and
-- accelerator architecture, using the long names.
--
-- The order is from the most generic to the least generic one.
--
function get_osarchs_reverse( stack_version, os, arch )

    local result = {}
    local version = map_toolchain( stack_version )

    if version == nil then
        -- This is actually an error as we do not recognize the
        -- version of the stack.
        return nil
    end

    local matching_version = get_matching_cputogen_key( stack_version )

    if ClusterMod_SystemProperties[stack_version]['hierarchy'] == '3L' then
        local cpu = extract_cpu_from_arch( arch )
        local gencpu = ClusterMod_map_cpu_to_gen[matching_version][cpu]
        if gencpu ~= nil then
            table.insert( result, os .. '-' .. gencpu )
        end
        if cpu ~= arch then
            table.insert( result, os .. '-' .. cpu )
        end
        table.insert( result, os .. '-' .. arch )
    else
        local cpu = extract_cpu_from_arch( arch )
        local gencpu = ClusterMod_map_cpu_to_gen[matching_version][cpu]
        if gencpu ~= nil then
            table.insert( result, os .. '-' .. gencpu )
        end
        table.insert( result, os .. '-' .. arch )
    end

    return result

end

-- -----------------------------------------------------------------------------
--
-- Function map_long_to_short( osarch )
--
-- Input arguments: 1
--   * osarch: The full os-and-architecture string in long format
--
-- Return arguments: 1
--   * The full os-and-architecture string in short format
--
function map_long_to_short( osarch )

    function string.easysplit( self, delimiter )
        local result = {}
        for match in (self .. delimiter):gmatch( "(.-)" .. delimiter ) do
            table.insert( result, match );
        end
        return result;
    end

    local elements = osarch:easysplit( '-' )

    local returnlist = {}

    -- Process the OS part
    local os
    local version
    os, version = elements[1]:match( '(%a+)(%d+)' )
    table.insert( returnlist, map_os_long_to_short[os] .. version )

    -- Process the CPU part
    table.insert( returnlist, map_cpu_long_to_short[elements[2]] )

    -- Process the accelerator part (if present)
    if #elements == 3 then
        table.insert( returnlist, map_accel_long_to_short[elements[3]] )
    end

    return table.concat( returnlist, '-' )

end


-- -----------------------------------------------------------------------------
--
-- Function map_short_to_long( short_osarch )
--
-- Input arguments: 1
--   * short_osarch: The full os-and-architecture string in short format
--
-- Return arguments: 1
--   * The full os-and-architecture string in long format
--
function map_short_to_long( short_osarch )

    -- Create the reverse tables

    local map_os_short_to_long = {}
    for k, v in pairs( map_os_long_to_short ) do
        map_os_short_to_long[v] = k
    end

    local map_cpu_short_to_long = {}
    for k, v in pairs( map_cpu_long_to_short ) do
        map_cpu_short_to_long[v] = k
    end

    local map_accel_short_to_long = {}
    for k, v in pairs( map_accel_long_to_short ) do
        map_accel_short_to_long[v] = k
    end

    -- Helper function to split strings
    function string.split( self, delimiter )
        local result = {}
        for match in (self .. delimiter):gmatch( "(.-)" .. delimiter ) do
            table.insert( result, match );
        end
        return result;
    end

    -- Main block of the function

    local elements = short_osarch:split( '-' )

    local returnlist = {}

    -- Process the OS part
    local short_os, version = elements[1]:match( '(%a+)(%d+)' )
    table.insert( returnlist, map_os_short_to_long[short_os] .. version )

    -- Process the CPU part
    table.insert( returnlist, map_cpu_short_to_long[elements[2]] )

    -- Process the accelerator part (if present)
    if #elements == 3 then
        table.insert( returnlist, map_accel_short_to_long[elements[3]] )
    end

    return table.concat( returnlist, '-' )

end

-- -----------------------------------------------------------------------------
--
-- Function get_stack_generic( osarch, stack_version )
--
-- Input arguments:
--   * osarch: osarch string in the long format
--   * stack_version: Version of the calcua stack, can be system.
--
-- Output: The most generic architecture for the current node.
--
function get_stack_generic( osarch, stack_version )

    local os = extract_os( osarch )
    local cpu = extract_cpu( osarch )

    local matching_version = get_matching_cputogen_key( stack_version )

    local osgeneric = ClusterMod_map_cpu_to_gen[matching_version][cpu]
    if osgeneric == nil then
        osgeneric = os .. '-' .. cpu
    else
        osgeneric = os .. '-' .. osgeneric
    end

    return osgeneric

end

-- -----------------------------------------------------------------------------
--
-- Function get_stack_generic_current( stack_version )
--
-- Input argument:
--   * stack_version: Version of the calcua stack, can be system.
--
-- Output: The most generic architecture for the current node.
--
function get_stack_generic_current( stack_version )

    local osarch = get_cluster_osarch()

    return get_stack_generic( osarch, stack_version )

end

-- -----------------------------------------------------------------------------
--
-- Function get_stack_osarch_current( stack_version )
--
-- Input argument:
--   * stack_version: Version of the calcua stack, can be system.
--
-- Output: The architecture of the current node with long names.
--

function get_stack_osarch_current( stack_version )

    local d1, d2, d3

    local hierarchy_type = ClusterMod_SystemProperties[stack_version]['hierarchy']
    if hierarchy_type == nil then
        LmodError( 'Likely an error in ClusterMod_SystemProperties in etc/SystemDefinition.lua, no hierarchy entry found for stack ' .. stack_version )
    end

    local current_osarch = get_cluster_osarch()

    return current_osarch

end



-- -----------------------------------------------------------------------------
--
-- Function get_stack_top( osarch, stack_version )
--
-- Input arguments:
--   * osarch: os and architecture with long names and in a format 
--     compatible with the indicated version of the software stack (so respecting
--     the hierarchy types 2L or 3L).
--   * stack_version: Version of the calcua stack, can be system.
--
-- Output: The most specific os-architecture for the current node in the indicated
-- version of the CalcUA software stacks, or nil if there is no support for the 
-- calcua stack for osarch.
--

function get_stack_top( osarch, stack_version )

    --
    -- -  Some initialisations ot use the data structures of etc/SystemDefinition.lua
    --
    local numversion = map_toolchain( stack_version )
    local matching_version = get_matching_toparchreduction_key( stack_version )

    local use_arch = extract_arch( osarch )
    local use_os   = extract_os( osarch )

    --
    -- -  Build a table that helps to quickly detect if an architecture is
    --    available as a top architecture or generic architecture for the software stack. 
    -- 
    local stack_os_archs = {}
    if ClusterMod_SystemTable[stack_version][use_os] == nil then
        return nil -- There is no support for this stack on this OS.
    end
    for index,value in ipairs( ClusterMod_SystemTable[stack_version][use_os] ) do
        stack_os_archs[value] = true
        local level_p1 = ClusterMod_map_arch_hierarchy[matching_version][value]
        while level_p1 ~= nil do
            stack_os_archs[level_p1] = true
            level_p1 = ClusterMod_map_arch_hierarchy[matching_version][level_p1]
        end 
    end

    --
    -- -  Now walk down the ClusterMod_reduce_top_arch searching for an
    --    architecture supported by the software stack.
    --
    while stack_os_archs[use_arch] == nil and ClusterMod_reduce_top_arch[matching_version][use_arch] ~= nil do
        use_arch = ClusterMod_reduce_top_arch[matching_version][use_arch]
    end

    --
    -- -  Now check if we have found something and produce the answer.
    --
    if stack_os_archs[use_arch] == true then
        return use_os .. '-' .. use_arch
    else
        return nil
    end

end


-- -----------------------------------------------------------------------------
--
-- Function get_stack_matchingarch( osarch, reduce_stack_version, 
--                                   stack_version )
--
-- Input arguments:
--   * osarch: os and architecture with long names. The name could be
--     incompatible with the software stack, i.e., we could get a middle
--     level name for a 3L scheme while looking in a 2L scheme. This happens,
--     e.g., when looking for a system module for an arch module for the
--     middle level in a 3L scheme for a different stack.
--   * reduce_stack_version: Version of the calcua stack to use for the 
--     mapping rules when we need to reduce the architecture.
--   * stack_version: Version of the calcua stack for which the returned
--     arch should be valid. Can be system.
--
-- Output: The most specific os-architecture for the osarch in the indicated
-- version of the CalcUA software stacks, or nil if there is no support for the 
-- calcua stack for osarch.
--
-- Cases to consider:
--   * osarch is os + generic CPU type: No reduction rules are applied.
--     Return nil if we find no way to generate this osarch from the
--     architectures in stack_version in the matching system table.
--   * osarch is a os + CPU name: 
--       * If stack_version is a 2L scheme and reduce_stack_version is a 3L 
--         scheme, then we are in a difficult case. From the use cases it can 
--         be that in fact osarch is generated from a reduction of 
--         
--   * osarch is a os + CPU + accelerator name: We use the top-level
--     reduction rules of reduce_stack_version as given by ClusterMod_reduce_top_arch
--     until we find a match in all archs that can be generated for the stack 
--     stack_version.
--

function get_stack_matchingarch( osarch, reduce_stack_version, stack_version )

    --
    -- -  Some initialisations ot use the data structures of etc/SystemDefinition.lua
    --

    local stack_hierarchy =        ClusterMod_SystemProperties[stack_version]['hierarchy']
    local reduce_stack_hierarchy = ClusterMod_SystemProperties[reduce_stack_version]['hierarchy']

    local num_stack_version =         map_toolchain( stack_version )
    local num_reduced_stack_version = map_toolchain( reduce_stack_version )

    local use_os =    extract_os( osarch )
    local use_cpu =   extract_cpu( osarch )
    local use_accel = extract_accel( osarch )
    local use_arch =  extract_arch( osarch )

    populate_cache_subarchs( stack_version, use_os )
    if reduce_stack_version ~= stack_version then
        populate_cache_subarchs( reduce_stack_version, use_os )
    end

    --
    -- - Check if the OS use_os is even supported by reduce_stack_version.
    --    If not, we'll return nil (or could produce an error)
    --
    if ClusterMod_SystemTable[reduce_stack_version][use_os] == nil then
        return nil
    end

    --
    -- -  Distinguish between the three cases
    --

    if use_accel ~= nil then

        --
        -- osarch is a top level name in 2L or 3L
        --
        -- Now walk down the ClusterMod_reduce_top_arch searching for an
        -- architecture supported by the software stack.

        local matching_version = get_matching_toparchreduction_key( num_reduced_stack_version )

        while use_arch ~= nil and ClusterMod_cache_subarchs[stack_version][use_os][use_arch] == nil 
              and ClusterMod_reduce_top_arch[matching_version][use_arch] ~= nil 
        do
            use_arch = ClusterMod_reduce_top_arch[matching_version][use_arch]
        end

    elseif not ClusterMod_def_cpu[use_cpu] then
    
        --
        -- osarch is a middle level name so reduce_stack_version should be 3L
        --
        -- Note that use_arch == use_cpu in this case.
        --

        if reduce_stack_hierarchy == '3L' then

            if stack_hierarchy == '2L' then
                -- First map to a generic architecture, but otherwise the code
                -- for 2L and 3L is identical.
                local matchingversion = get_matching_cputogen_key( num_reduced_stack_version )
                use_arch = ClusterMod_map_cpu_to_gen[matchingversion][use_arch]
            end

            local matching_version = get_matching_reducecpu_key( num_reduced_stack_version )

            while use_arch ~= nil and ClusterMod_cache_subarchs[stack_version][use_os][use_arch] == nil 
                  and ClusterMod_reduce_cpu[matching_version][use_arch] ~= nil 
            do
                use_arch = ClusterMod_reduce_cpu[matching_version][use_arch]
            end    

        else -- This should not happen, this is an error condition.

            use_arch = nil
        
        end

    else

        --
        -- osarch is a bottom/generic level name
        --
        -- Note that use_arch == use_cpu in this case.
        --
        -- walk down the CPU reduction chain until we find a match.
        --

        local matching_version = get_matching_reducecpu_key( num_reduced_stack_version )

        while use_arch ~= nil and ClusterMod_cache_subarchs[stack_version][use_os][use_arch] == nil 
              and ClusterMod_reduce_cpu[matching_version][use_arch] ~= nil 
        do
            use_arch = ClusterMod_reduce_cpu[matching_version][use_arch]
        end

    end -- Distinguish between the level in the hierarchy of osarch.

    --
    -- -  Now check if we have found something and produce the answer.
    --
    
    if use_arch == nil then
        return nil
    elseif ClusterMod_cache_subarchs[stack_version][use_os][use_arch] == true then
        return use_os .. '-' .. use_arch
    else
        return nil
    end

end


-- -----------------------------------------------------------------------------
--
-- Function get_stack_EasyBuild_version( stack_version )
--
-- Input argument:
--   * stack_version: Version of the calcua stack, can be system. 
--
-- Returns the version of EasyBuild for the stack as defined in the
-- ClusterMod_SystemProperties structure.
--

function get_stack_EasyBuild_version( stack_version )

    if ClusterMod_SystemProperties[stack_version] == nil then
        return nil
    else
        return ClusterMod_SystemProperties[stack_version]['EasyBuild']
    end

end


-- -----------------------------------------------------------------------------
--
-- Function get_stack_subarchs( osarch, stack_version )
--
-- Input arguments:
--   * osarch: os and architecture with long names and in a format 
--     compatible with the indicated version of the software stack (so respecting
--     the hierarchy types 2L or 3L).
--   * stack_version: Version of the calcua stack, can be system.
--
-- Output: A list containing the given osarch and its subarchs in
-- the hierarchy of the naming scheme for the stack. So the list can
-- be at most 3 elements long. The most generic one is at the front of
-- the list.
--
-- The function could be made a bit shorter but that would not improve
-- readability at all.
--

function get_stack_subarchs( osarch, stack_version )

    local result = {}

    local osgeneric = get_stack_generic( osarch, stack_version )

    if osarch == osgeneric then

        -- The function was called with osarch pointing to the
        -- generic level of a 2L or 3L hierarchy, so only one element
        -- in the return list.
        table.insert( result, osgeneric )

    else
        -- We did not call the function with osarch pointing to the 
        -- generic level of the software stack so we need to continue.

        if ClusterMod_SystemProperties[stack_version]['hierarchy'] == '3L' then
            
            -- 3L software hierarchy

            if extract_cpu( osarch ) == extract_arch( osarch ) then

                -- osarch has only two compoonents so it must be the middle level
                -- in a 3L hierarchy. The result has two elements: the middle level
                -- and generic level.
                table.insert( result, osgeneric )
                table.insert( result, osarch )

            else
                
                -- osarch has three components so it must be the top level in a
                -- 3L hierarchy. The result has three elements: the given top level
                -- architecture, the middle level obtained from omitting the accelerator
                -- part, and the generic level.
                table.insert( result, osgeneric )
                table.insert( result, extract_os( osarch ) .. '-' .. extract_cpu( osarch ))
                table.insert( result, osarch )

            end

        else

            -- 2L software hierarchy, so unless the function was called with wrong arguments
            -- (we will not check for it) osarch must be a top level architecture, and
            -- the result consists of this top level architecture and the corresponding generic
            -- one.
            table.insert( result, osgeneric )
            table.insert( result, osarch )

        end

    end

    return result

end


-- -----------------------------------------------------------------------------
--
-- Function get_system_inframodule_dir( osarch, stack_name, stack_version )
--
-- Input argument: 3
--   * The long os-and-architecture name
--   * Stack name, can be system or manual
--   * Stack version, not used when the stack name is system of manual
--
-- Return argument: 1
--   * Absolute path of the module directory 
--     (in the modules-infrastructure/infrastructure section) corresponding to 
--     the given stack.
-- Note `system` in the name does not denote the `system` stack but the whole
-- system installation, versus the user installation.
--

function get_system_inframodule_dir( osarch, stack_name, stack_version )

    local use_version    -- Processed stack_version
    local prefix = 'modules-infrastructure/infrastructure'

    if stack_name == 'manual' or stack_version == 'manual' then
        -- No infrastructure modules for this stack
        return nil
    elseif stack_name == ClusterMod_StackName then
        use_version = stack_version
    elseif ( stack_name == 'system' ) then
        use_version = stack_name
    else
        -- Error condition, not known how to treat this stack
        io.stderr:write( 'LMOD/SitePackage_arch_hierarchy: get_system_module_dir: Illegal input arguments\n' )
        return nil
    end

    return pathJoin( get_system_install_root(), prefix, stack_name, stack_version, 'arch', osarch )

end


-- -----------------------------------------------------------------------------
--
-- Function get_system_module_dir( osarch, stack_name, stack_version )
-- Function get_system_module_dirs( osarch, stack_name, stack_version )
-- Function get_user_module_dir( osarch, stack_name, stack_version )
-- Function get_user_module_dirs( osarch, stack_name, stack_version )
--
-- Input argument: 3
--   * The long os-and-architecture name
--   * Stack name, can be system or manual
--   * Stack version, not used when the stack name is system of manual
--
-- Return argument: 1
--   * get_system_module_dir: Module directory in the system installation for the
--     given architecture and stack. Absolute paths.
--   * get_system_module_dirs: All regular modular directories in the system
--     installation for the given architecture and stack, and relevant
--     subarchitectures, with the most generic architecture first.
--   * get_user_module_dir: As get_system_module_dir, but then for the user 
--     installation .
--   * get_user_module_dirs: As get_system_module_dirs, but now for the user
--     installation.
--
-- Note `system` in the name does not denote the `system` stack but the whole
-- system installation, versus the user installation.
--

--
-- First to functions that will also be used by the corresponding EBrepo functions to ensure
-- that the repository directories and module directories correspond.
--
function get_module_dir_worker( osarch, stack_name, stack_version, module_prefix, routine_name, dir_generator )

    local use_version    -- Processed stack_version
    local prefix

    if stack_name == 'manual' or stack_version == 'manual' then
        -- No EasyBuild modules for manually installed software
        return nil
    elseif stack_name == ClusterMod_StackName then
        use_version = stack_version
    elseif ( stack_name == 'system' ) then
        use_version = stack_name
    else
        -- Error condition, not known how to treat this stack
        LmodError( 'LMOD/SitePackage_arch_hierarchy: ' .. routine_name .. ': Illegal input arguments\n' )
        return nil -- Return value is only useful for the test code as otherwise LmodError stops executing the module code.
    end

    -- Check if the input osarch is valid in the cluster definition.
    populate_cache_subosarchs( use_version )
    if ClusterMod_cache_subosarchs[use_version][osarch] ~= true then
        LmodError( 'LMOD/SitePackage_arch_hierarchy: ' .. routine_name .. ': ' .. (osarch or 'nil') .. 
                   ' is not a valid architecture for stack ' .. stack_name .. '/' .. stack_version )
        return nil -- Return value is only useful for the test code as otherwise LmodError stops executing the module code.
    end

    return dir_generator( osarch, use_version, module_prefix )

end

function get_module_dirs_worker( osarch, stack_name, stack_version, module_prefix, routine_name, dir_generator )

    local use_version    -- Processed stack_version
    local result
    local all_archs
    local prefix

    if stack_name == 'manual' or stack_version == 'manual' then
        -- No EasyBuild modules for manually installed software
        return nil
    elseif stack_name == ClusterMod_StackName then
        use_version = stack_version
    elseif ( stack_name == 'system' ) or ( stack_name == 'manual' ) then
        use_version = stack_name
    else
        -- Error condition, not known how to treat this stack
        io.stderr:write( 'LMOD/SitePackage_arch_hierarchy: ' .. routine_name .. ': Illegal input arguments\n' )
        return nil
    end

    -- Check if the input osarch is valid in the cluster definition.
    populate_cache_subosarchs( use_version )
    if ClusterMod_cache_subosarchs[use_version][osarch] ~= true then
        LmodError( 'LMOD/SitePackage_arch_hierarchy: ' .. routine_name .. ': ' .. (osarch or 'nil') .. 
                   ' is not a valid architecture for stack ' .. stack_name .. '/' .. stack_version )
        return nil -- Return value is only useful for the test code as otherwise LmodError stops executing the module code.
    end

    result = {}
    for index, os_arch_accel in ipairs( get_stack_subarchs( osarch, use_version ) )
    do
        table.insert( result, dir_generator( os_arch_accel, use_version, module_prefix ) )
    end

    return result

end


function get_module_dir_generator( osarch, stack_version, module_prefix )

    -- Worker function without any error control. The error control is done
    -- by get_system_module_dir and get_system_module_dirs.

    local prefix

    if stack_version == 'system' or stack_version == 'manual' then
        prefix = module_prefix .. '/' .. stack_version .. '/'
    else
        prefix = module_prefix .. '/' .. ClusterMod_StackName  .. '-' .. stack_version .. '/'
    end

    return prefix .. osarch

end


function get_system_module_dir( osarch, stack_name, stack_version )

    local prefix = pathJoin( get_system_install_root(), 'modules-easybuild' )

    return get_module_dir_worker( osarch, stack_name, stack_version, prefix, 'get_system_module_dir', get_module_dir_generator )

end


function get_system_module_dirs( osarch, stack_name, stack_version )

    local prefix = pathJoin( get_system_install_root(), 'modules-easybuild' )

    return get_module_dirs_worker( osarch, stack_name, stack_version, prefix, 'get_system_module_dirs', get_module_dir_generator )

end

function get_user_module_dir( osarch, stack_name, stack_version )

    local prefix = pathJoin( get_user_install_root(), 'modules-easybuild-user' )

    return get_module_dir_worker( osarch, stack_name, stack_version, prefix, 'get_user_module_dir', get_module_dir_generator )

end


function get_user_module_dirs( osarch, stack_name, stack_version )

    local prefix = pathJoin( get_user_install_root(), 'modules-easybuild-user' )

    return get_module_dirs_worker( osarch, stack_name, stack_version, prefix, 'get_user_module_dirs', get_module_dir_generator )

end


-- -----------------------------------------------------------------------------
--
-- Function get_system_EBrepo_dir( osarch, stack_name, stack_version )
-- Function get_system_EBrepo_dirs( osarch, stack_name, stack_version )
-- Function get_user_EBrepo_dir( osarch, stack_name, stack_version )
-- Function get_user_EBrepo_dirs( osarch, stack_name, stack_version )
-- Function get_systen_infra_EBrepo_dir( osarch, stack_name, stack_version )
--
-- Input argument: 3
--   * The long os-and-architecture name
--   * Stack name, can be system or manual
--   * Stack version, not used when the stack name is system of manual
--
-- Return argument: 1
--   * get_system_EBrepo_dir: subdirectory in the EBrepo_files subdirectory
--     for installed system EasyConfigs for the corresponding architecture in 
--     for the given architecture and stack (name/version)
--   * get_system_EBrepo_dirs: All relevant subdirectories in the EBrepo_files
--     subdirectory for installed system EasyConfigs for the corresponding
--     architecture and parent architectures for the given architecture
--     and stack (name/version), with the most generic one first.
--   * get_user_EBrepo_dir: subdirectory in the EBrepo_files subdirectory
--     for installed user EasyConfigs for the corresponding architecture in 
--     for the given architecture and stack (name/version)
--   * get_user_EBrepo_dirs: All relevant subdirectories in the EBrepo_files
--     subdirectory for installed user EasyConfigs for the corresponding
--     architecture and parent architectures for the given architecture
--     and stack (name/version), with the most generic one first.
--

function get_EBrepo_dir_generator( osarch, stack_version, dir_prefix )

    -- Worker function without full error control. The error control is done
    -- by get_system_module_dir_worker and get_system_module_dirs_worker.

    local prefix

    if stack_version == 'manual' then
        -- This function should actually not be called in this case, but just in case,
        -- though it will likely produce an error message later on.
        return nil 
    elseif stack_version == 'system' then
        return pathJoin( dir_prefix, 'EBfiles_repo/system', osarch )
    else
        return pathJoin( dir_prefix, 'EBfiles_repo',  ClusterMod_StackName .. '-' .. stack_version, osarch )
    end

end


function get_system_EBrepo_dir( osarch, stack_name, stack_version )

    local dir_prefix = pathJoin( get_system_install_root(), 'mgmt' )

    return get_module_dir_worker( osarch, stack_name, stack_version, dir_prefix, 'get_system_EBrepo_dir', get_EBrepo_dir_generator )

end


function get_system_EBrepo_dirs( osarch, stack_name, stack_version )

    local dir_prefix = pathJoin( get_system_install_root(), 'mgmt' )

    return get_module_dirs_worker( osarch, stack_name, stack_version, dir_prefix, 'get_system_EBrepo_dir', get_EBrepo_dir_generator )

end


function get_user_EBrepo_dir( osarch, stack_name, stack_version )

    local dir_prefix = get_user_install_root()

    return get_module_dir_worker( osarch, stack_name, stack_version, dir_prefix, 'get_user_EBrepo_dir', get_EBrepo_dir_generator )

end


function get_user_EBrepo_dirs( osarch, stack_name, stack_version )

    local dir_prefix = get_user_install_root()

    return get_module_dirs_worker( osarch, stack_name, stack_version, dir_prefix, 'get_user_EBrepo_dir', get_EBrepo_dir_generator )

end

function get_infra_EBrepo_dir_generator( osarch, stack_version, dir_prefix )

    -- Worker function without full error control. The error control is done
    -- by get_system_module_dir_worker and get_system_module_dirs_worker.

    local prefix

    if stack_version == 'manual' then
        -- This function should actually not be called in this case, but just in case,
        -- though it will likely produce an error message later on.
        return nil 
    elseif stack_version == 'system' then
        return pathJoin( dir_prefix, 'EBfiles_repo_infrastructure/system', osarch )
    else
        return pathJoin( dir_prefix, 'EBfiles_repo_infrastructure',  ClusterMod_StackName .. '-' .. stack_version, osarch )
    end

end


function get_system_infra_EBrepo_dir( osarch, stack_name, stack_version )

    local dir_prefix = pathJoin( get_system_install_root(), 'mgmt' )

    return get_module_dir_worker( osarch, stack_name, stack_version, dir_prefix, 'get_system_Einfra_Brepo_dir', get_infra_EBrepo_dir_generator )

end



-- -----------------------------------------------------------------------------
--
-- Function get_system_SW_dir( osarch, stack_name, stack_version )
-- Function get_user_SW_dir( osarch, stack_name, stack_version )
--
-- Input argument: 3
--   * The long os-and-architecture name
--   * Stack name, can be system or manual
--   * Stack version, not used when the stack name is system of manual
--
-- Return argument: 1
--   * Software directory in the SW directory relative to respectively the
--     system and user installation root, corresponding to the given stack.
-- Note `system` in the name does not denote the `system` stack but the whole
-- system installation, versus the user installation.
--

function get_SW_dir_worker( osarch, stack_name, stack_version, dir_prefix )

    local use_version    -- Processed stack_version
    local prefix

    if stack_name == 'manual' or stack_version == 'manual' then
        use_version = 'manual'
    elseif stack_name == ClusterMod_StackName then
        use_version = stack_version
    elseif ( stack_name == 'system' ) then
        use_version = stack_name
    else
        -- Error condition, not known how to treat this stack
        io.stderr:write( 'LMOD/SitePackage_arch_hierarchy: get_system_module_dir: Illegal input arguments\n' )
        return nil
    end

    local postfix = map_long_to_short( osarch )
    if use_version == 'manual' then
        return pathJoin( dir_prefix, 'SW/MNL', postfix )
    elseif use_version == 'system' then
        return pathJoin( dir_prefix, 'SW', use_version, postfix )
    else
        return pathJoin( dir_prefix, 'SW', ClusterMod_StackName .. '-' .. use_version, postfix )
    end

end


function get_system_SW_dir( osarch, stack_name, stack_version )

    local dir_prefix = get_system_install_root()

    return get_SW_dir_worker( osarch, stack_name, stack_version, dir_prefix )

end


function get_user_SW_dir( osarch, stack_name, stack_version )

    local dir_prefix = get_user_install_root()

    return get_SW_dir_worker( osarch, stack_name, stack_version, dir_prefix )

end


-- -----------------------------------------------------------------------------
--
-- Function get_optarch( osarch, stack_name, stack_version )
--
-- Input argument: 3
--   * The long os-and-architecture name
--   * Stack name, can be system or manual
--   * Stack version, not used when the stack name is system of manual
--
-- Return argument: 1
--   * String to use for the optarch argument of EasyBuild, or nil if no optarch
--     argument is needed for the architecture.
--

function get_optarch( osarch, stack_name, stack_version )

    local arch = extract_arch( osarch )
    local map_version = map_toolchain( stack_version )

    local matching_key = get_matching_optarch_key( map_version )

    if matching_key == nil then    
        return nil
    else
        return ClusterMod_optarch[matching_key][arch]
    end

end

