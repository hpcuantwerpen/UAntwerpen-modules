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
    ['x86_64']    = 'x86_64',
    ['zen3']      = 'zen3',
    ['zen2']      = 'zen2',
    ['ivybridge'] = 'IVB',
    ['broadwell'] = 'BRW',
    ['skylake']   = 'SKLX',
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
-- -----------------------------------------------------------------------------
--
-- Functions to work with long or short full names
--
-- extract_os( name )    : Extract the first part, the OS
-- extract_cpu( name )   : Extract the second part, the CPU
-- extract_accel( name ) : Extract the third part, the accelerator, or nil if not
--                         present
-- extract_arch( name )  : Extract CPU + accelerator
-- extract_cpu_from_arch( name ) : Extract the CPU part from the arch string.

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


-- -----------------------------------------------------------------------------
--
-- get_long_osarchs
--
-- Input arguments:
--   * stack_version: Version of the software stack (or `system` for the
--     software installed against the system or in manual mode).
--     The routine also accpets versions in yyyymm format.
--   * long_os: Name (with version) of the OS (currently only redhat8)
--   * long_arch: Architecture, e.g., zen2-noaccel or x86_64.
--
-- Output: A table with the chain of architectures, each a string with two or
-- three dash-separated entities: OS (+version), base CPU architecture and
-- accelerator architecture, using the long names.
--
-- The order is from the least generic to the most generic one.
--
function get_long_osarchs( stack_version, long_os, long_arch )

    local result = {}
    local version = map_toolchain( stack_version )

    if version == nil then
        -- This is actually an error as we do not recognize the
        -- version of the stack.
        return nil
    end

    local matching_version = get_matching_cputogen_key( stack_version )

    if CalcUA_SystemProperties[stack_version]['hierarchy'] == '3L' then
        local cpu = extract_cpu_from_arch( long_arch )
        local gencpu = CalcUA_map_cpu_to_gen[matching_version][cpu]
        table.insert( result, long_os .. '-' .. long_arch )
        if cpu ~= long_arch then
            table.insert( result, long_os .. '-' .. cpu )
        end
        if gencpu ~= nil then
            table.insert( result, long_os .. '-' .. gencpu )
        end
    else
        local cpu = extract_cpu_from_arch( long_arch )
        local gencpu = CalcUA_map_cpu_to_gen[matching_version][cpu]
        table.insert( result, long_os .. '-' .. long_arch )
        if gencpu ~= nil then
            table.insert( result, long_os .. '-' .. gencpu )
        end
    end

    return result

end


-- -----------------------------------------------------------------------------
--
-- Function get_long_osarchs_reverse( stack_version, long_os, long_arch )
--
-- Input arguments:
--   * stack_version: Version of the software stack (or `system` for the
--     software installed against the system or or 'manual' for  manual mode).
--     It must be a valid software stack version defined in CalcUA_SystemTable
--     etc. in etc/SystemDefinition.lua
--   * long_os: Name (with version) of the OS
--   * long_arch: Architecture, e.g., zen2-noaccel or x86_64.
--
-- Output: A table with the chain of architectures, each a string with two or
-- three dash-separated entities: OS (+version), base CPU architecture and
-- accelerator architecture, using the long names.
--
-- The order is from the most generic to the least generic one.
--
function get_long_osarchs_reverse( stack_version, long_os, long_arch )

    local result = {}
    local version = map_toolchain( stack_version )

    if version == nil then
        -- This is actually an error as we do not recognize the
        -- version of the stack.
        return nil
    end

    local matching_version = get_matching_cputogen_key( stack_version )

    if CalcUA_SystemProperties[stack_version]['hierarchy'] == '3L' then
        local cpu = extract_cpu_from_arch( long_arch )
        local gencpu = CalcUA_map_cpu_to_gen[matching_version][cpu]
        if gencpu ~= nil then
            table.insert( result, long_os .. '-' .. gencpu )
        end
        if cpu ~= long_arch then
            table.insert( result, long_os .. '-' .. cpu )
        end
        table.insert( result, long_os .. '-' .. long_arch )
    else
        local cpu = extract_cpu_from_arch( long_arch )
        local gencpu = CalcUA_map_cpu_to_gen[matching_version][cpu]
        if gencpu ~= nil then
            table.insert( result, long_os .. '-' .. gencpu )
        end
        table.insert( result, long_os .. '-' .. long_arch )
    end

    return result

end

-- -----------------------------------------------------------------------------
--
-- Function map_long_to_short( long_osarch )
--
-- Input arguments: 1
--   * long_osarch: The full os-and-architecture string in long format
--
-- Return arguments: 1
--   * The full os-and-architecture string in short format
--
function map_long_to_short( long_osarch )

    function string.easysplit( self, delimiter )
        local result = {}
        for match in (self .. delimiter):gmatch( "(.-)" .. delimiter ) do
            table.insert( result, match );
        end
        return result;
    end

    local elements = long_osarch:easysplit( '-' )

    local returnlist = {}

    -- Process the OS part
    local long_os
    local version
    long_os, version = elements[1]:match( '(%a+)(%d+)' )
    table.insert( returnlist, map_os_long_to_short[long_os] .. version )

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
-- Function get_calcua_generic( long_osarch, stack_version )
--
-- Input arguments:
--   * long_osarch: long_osarch string in the long format
--   * stack_version: Version of the calcua stack, can be system.
--
-- Output: The most generic architecture for the current node.
--
function get_calcua_generic( long_osarch, stack_version )

    local long_os = extract_os( long_osarch )
    local long_cpu = extract_cpu( long_osarch )

    local matching_version = get_matching_cputogen_key( stack_version )

    local long_osgeneric = CalcUA_map_cpu_to_gen[matching_version][long_cpu]
    if long_osgeneric == nil then
        long_osgeneric = long_os .. '-' .. long_cpu
    else
        long_osgeneric = long_os .. '-' .. long_osgeneric
    end

    return long_osgeneric

end

-- -----------------------------------------------------------------------------
--
-- Function get_calcua_generic_current( stack_version )
--
-- Input argument:
--   * stack_version: Version of the calcua stack, can be system.
--
-- Output: The most generic architecture for the current node.
--
function get_calcua_generic_current( stack_version )

    local long_osarch = get_cluster_longosarch()

    return get_calcua_generic( long_osarch, stack_version )

end

-- -----------------------------------------------------------------------------
--
-- Function get_calcua_longosarch_current( stack_version )
--
-- Input argument:
--   * stack_version: Version of the calcua stack, can be system.
--
-- Output: The architecture of the current node with long names.
--

function get_calcua_longosarch_current( stack_version )

    local d1, d2, d3

    local hierarchy_type = CalcUA_SystemProperties[stack_version]['hierarchy']
    if hierarchy_type == nil then
        LmodError( 'Likely an error in CalcUA_SystemProperties in etc/SystemDefinition.lua, no hierarchy entry found for stack ' .. stack_version )
    end

    local current_osarch = get_cluster_longosarch()

    return current_osarch

end



-- -----------------------------------------------------------------------------
--
-- Function get_calcua_top( long_osarch, stack_version )
--
-- Input arguments:
--   * long_osarch: os and architecture with long names and in a format 
--     compatible with the indicated version of the software stack (so respecting
--     the hierarchy types 2L or 3L).
--   * stack_version: Version of the calcua stack, can be system.
--
-- Output: The most specific os-architecture for the current node in the indicated
-- version of the CalcUA software stacks, or nil if there is no support for the 
-- calcua stack for long_osarch.
--

function get_calcua_top( long_osarch, stack_version )

    --
    -- -  Some initialisations ot use the data structures of etc/SystemDefinition.lua
    --
    local numversion = map_toolchain( stack_version )
    local matching_version = get_matching_toparchreduction_key( stack_version )

    local use_arch = extract_arch( long_osarch )
    local use_os   = extract_os( long_osarch )

    --
    -- -  Build a table that helps to quickly detect if an architecture is
    --    available as a top architecture or generic architecture for the software stack. 
    -- 
    local stack_os_archs = {}
    if CalcUA_SystemTable[stack_version][use_os] == nil then
        return nil -- There is no support for this stack on this OS.
    end
    for index,value in ipairs( CalcUA_SystemTable[stack_version][use_os] ) do
        stack_os_archs[value] = true
        local level_p1 = CalcUA_map_arch_hierarchy[matching_version][value]
        while level_p1 ~= nil do
            stack_os_archs[level_p1] = true
            level_p1 = CalcUA_map_arch_hierarchy[matching_version][level_p1]
        end 
    end

    --
    -- -  Now walk down the CalcUA_reduce_top_arch searching for an
    --    architecture supported by the software stack.
    --
    while stack_os_archs[use_arch] == nil and CalcUA_reduce_top_arch[matching_version][use_arch] ~= nil do
        use_arch = CalcUA_reduce_top_arch[matching_version][use_arch]
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
-- Function get_calcua_subarchs( long_osarch, stack_version )
--
-- Input arguments:
--   * long_osarch: os and architecture with long names and in a format 
--     compatible with the indicated version of the software stack (so respecting
--     the hierarchy types 2L or 3L).
--   * stack_version: Version of the calcua stack, can be system.
--
-- Output: A list containing the given long_osarch and its subarchs in
-- the hierarchy of the naming scheme for the stack. So the list can
-- be at most 3 elements long. The most generic one is at the front of
-- the list.
--
-- The function could be made a bit shorter but that would not improve
-- readability at all.
--

function get_calcua_subarchs( long_osarch, stack_version )

    local result = {}

    local long_osgeneric = get_calcua_generic( long_osarch, stack_version )

    if long_osarch == long_osgeneric then

        -- The function was called with long_osarch pointing to the
        -- generic level of a 2L or 3L hierarchy, so only one element
        -- in the return list.
        table.insert( result, long_osgeneric )

    else
        -- We did not call the function with long_osarch pointing to the 
        -- generic level of the software stack so we need to continue.

        if CalcUA_SystemProperties[stack_version]['hierarchy'] == '3L' then
            
            -- 3L software hierarchy

            if extract_cpu( long_osarch ) == extract_arch( long_osarch ) then

                -- long_osarch has only two compoonents so it must be the middle level
                -- in a 3L hierarchy. The result has two elements: the middle level
                -- and generic level.
                table.insert( result, long_osgeneric )
                table.insert( result, long_osarch )

            else
                
                -- long_osarch has three components so it must be the top level in a
                -- 3L hierarchy. The result has three elements: the given top level
                -- architecture, the middle level obtained from omitting the accelerator
                -- part, and the generic level.
                table.insert( result, long_osgeneric )
                table.insert( result, extract_os( long_osarch ) .. '-' .. extract_cpu( long_osarch ))
                table.insert( result, long_osarch )

            end

        else

            -- 2L software hierarchy, so unless the function was called with wrong arguments
            -- (we will not check for it) long_osarch must be a top level architecture, and
            -- the result consists of this top level architecture and the corresponding generic
            -- one.
            table.insert( result, long_osgeneric )
            table.insert( result, long_osarch )

        end

    end

    return result

end


-- -----------------------------------------------------------------------------
--
-- Function get_system_module_dir( long_osarch, stack_name, stack_version )
-- Function get_system_module_dirs( long_osarch, stack_name, stack_version )
--
-- Input argument: 3
--   * The long os-and-architecture name
--   * Stack name, can be system or manual
--   * Stack version, not used when the stack name is system of manual
--
-- Return argument: 1
--   * get_system_module_dir: Module directory in the modules-easybuild directory
--     corresponding to the given stack.
--   * get_system_module_dirs: Directories, starting from the installation root,
--     with the most generic one first.
--
-- Note `system` in the name does not denote the `system` stack but the whole
-- system installation, versus the user installation.
--

function get_system_module_dir_worker( long_osarch, stack_version )

    -- Worker function without any error control. The error control is done
    -- by get_system_module_dir and get_system_module_dirs.

    if stack_version == 'system' or stack_version == 'manual' then
        prefix = 'modules-easybuild/' .. stack_version .. '/'
    else
        prefix = 'modules-easybuild/CalcUA-' .. stack_version .. '/'
    end

    return prefix .. long_osarch

end

function get_system_module_dir( long_osarch, stack_name, stack_version )

    local use_version    -- Processed stack_version
    local prefix

    if stack_name == 'manual' or stack_version == 'manual' then
        -- No EasyBuild modules for manually installed software
        return nil
    elseif stack_name == 'calcua' then
        use_version = stack_version
    elseif ( stack_name == 'system' ) then
        use_version = stack_name
    else
        -- Error condition, not known how to treat this stack
        LmodError( 'LMOD/SitePackage_arch_hierarchy: get_system_module_dir: Illegal input arguments\n' )
        return nil -- Return value is only useful for the test code as otherwise LmodError stops executing the module code.
    end

    -- TODO: Check if long_osarch is valid for stack_name/stack_version to 
    -- improve robustness of the system.

    return get_system_module_dir_worker( long_osarch, use_version )

end

function get_system_module_dirs( long_osarch, stack_name, stack_version )

    local use_version    -- Processed stack_version
    local result
    local all_archs
    local prefix

    if stack_name == 'manual' or stack_version == 'manual' then
        -- No EasyBuild modules for manually installed software
        return nil
    elseif stack_name == 'calcua' then
        use_version = stack_version
    elseif ( stack_name == 'system' ) or ( stack_name == 'manual' ) then
        use_version = stack_name
    else
        -- Error condition, not known how to treat this stack
        io.stderr:write( 'LMOD/SitePackage_arch_hierarchy: get_system_module_dirs: Illegal input arguments\n' )
        return nil
    end

    -- TODO: Check if long_osarch is valid for stack_name/stack_version to 
    -- improve robustness of the system.

    result = {}
    for index, os_arch_accel in ipairs( get_calcua_subarchs( long_osarch, use_version ) )
    do
        table.insert( result, get_system_module_dir_worker( os_arch_accel, use_version ) )
    end

    return result

end


-- -----------------------------------------------------------------------------
--
-- Function get_system_inframodule_dir( long_osarch, stack_name, stack_version )
--
-- Input argument: 3
--   * The long os-and-architecture name
--   * Stack name, can be system or manual
--   * Stack version, not used when the stack name is system of manual
--
-- Return argument: 1
--   * Module directory in the modules-infrastructure/infrastructure directory
--     corresponding to the given stack.
-- Note `system` in the name does not denote the `system` stack but the whole
-- system installation, versus the user installation.
--

function get_system_inframodule_dir( long_osarch, stack_name, stack_version )

    local use_version    -- Processed stack_version
    local prefix

    if stack_name == 'manual' or stack_version == 'manual' then
        -- No infrastructure modules for this stack
        return nil
    elseif stack_name == 'calcua' then
        use_version = stack_version
    elseif ( stack_name == 'system' ) then
        use_version = stack_name
    else
        -- Error condition, not known how to treat this stack
        io.stderr:write( 'LMOD/SitePackage_arch_hierarchy: get_system_module_dir: Illegal input arguments\n' )
        return nil
    end

    if use_version == 'system' then
        prefix = 'modules-infrastructure/infrastructure/' .. use_version .. '/'
    else
        prefix = 'modules-infrastructure/infrastructure/CalcUA-' .. use_version .. '/'
    end

    return prefix .. long_osarch

end

-- -----------------------------------------------------------------------------
--
-- Function get_system_SW_dir( long_osarch, stack_name, stack_version )
--
-- Input argument: 3
--   * The long os-and-architecture name
--   * Stack name, can be system or manual
--   * Stack version, not used when the stack name is system of manual
--
-- Return argument: 1
--   * Software directory in the SW directory (starting from the SW level)
--     corresponding to the given stack.
-- Note `system` in the name does not denote the `system` stack but the whole
-- system installation, versus the user installation.
--

function get_system_SW_dir( long_osarch, stack_name, stack_version )

    local use_version    -- Processed stack_version
    local prefix

    if stack_name == 'manual' or stack_version == 'manual' then
        use_version = 'manual'
    elseif stack_name == 'calcua' then
        use_version = stack_version
    elseif ( stack_name == 'system' ) then
        use_version = stack_name
    else
        -- Error condition, not known how to treat this stack
        io.stderr:write( 'LMOD/SitePackage_arch_hierarchy: get_system_module_dir: Illegal input arguments\n' )
        return nil
    end

    if use_version == 'manual' then
        prefix = 'SW/MNL/'
    elseif use_version == 'system' then
        prefix = 'SW/' .. use_version .. '/'
    else
        prefix = 'SW/CalcUA-' .. use_version .. '/'
    end

    return prefix .. map_long_to_short( long_osarch )

end


-- -----------------------------------------------------------------------------
--
-- Function get_system_EBrepo_dir( long_osarch, stack_name, stack_version )
--
-- Input argument: 3
--   * The long os-and-architecture name
--   * Stack name, can be system or manual
--   * Stack version, not used when the stack name is system of manual
--
-- Return argument: 1
--   * Module directory in the EBrepo_files directory
--     corresponding to the given stack (starting from the EBrepo_files level)
-- Note `system` in the name does not denote the `system` stack but the whole
-- system installation, versus the user installation.
--

function get_system_EBrepo_dir( long_osarch, stack_name, stack_version )

    local use_version    -- Processed stack_version
    local prefix

    if stack_name == 'manual' or stack_version == 'manual' then
        -- No EBrepo directory for this stack
        return nil
    elseif stack_name == 'calcua' then
        use_version = stack_version
    elseif ( stack_name == 'system' ) then
        use_version = stack_name
    else
        -- Error condition, not known how to treat this stack
        io.stderr:write( 'LMOD/SitePackage_arch_hierarchy: get_system_module_dir: Illegal input arguments\n' )
        return nil
    end

    if use_version == 'system' then
        prefix = 'EBrepo_files/system/'
    else
        prefix = 'EBrepo_files/CalcUA-' .. use_version .. '/'
    end

    return prefix .. long_osarch

end


