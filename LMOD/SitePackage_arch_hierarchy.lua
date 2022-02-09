-- -----------------------------------------------------------------------------
--
-- The following mapping is used to define generic versions of specific
-- architectures.
--
-- NOTE: Current restrictions of the implementastion
--   * OS version numbers are integers and OS names only include regular
--     characters. If not , the conversion function between long and short names
--     may fail.
--

map_arch_redhat8 = {
    ['zen2-noaccel']      = 'x86_64',
    ['zen2-ampere']       = 'x86_64',
    ['zen2-arcturus']     = 'x86_64',
    ['broadwell-noaccel'] = 'x86_64',
    ['broadwell-P5000']   = 'x86_64',
    ['broadwell-pascal']  = 'x86_64',
    ['skylake-noaccel']   = 'x86_64',
    ['skylake-aurora1']   = 'x86_64',
    ['ivybridge-noaccel'] = 'x86_64',
    ['x86_64']            = nil,
}

map_arch_redhat8_alt = {
    ['zen2-noaccel']      = 'zen2',
    ['zen2-ampere']       = 'zen2',
    ['zen2-arcturus']     = 'zen2',
    ['zen2']              = 'x86_64',
    ['broadwell-noaccel'] = 'broadwell',
    ['broadwell-P5000']   = 'broadwell',
    ['broadwell-pascal']  = 'broadwell',
    ['broadwell']         = 'x86_64',
    ['skylake-noaccel']   = 'skylake',
    ['skylake-aurora1']   = 'skylake',
    ['skylake']           = 'x86_64',
    ['ivybridge-noaccel'] = 'x86_64',
    ['x86_64']            = nil,
}

map_os_arch = {
    ['redhat8'] = map_arch_redhat8,
}

map_os_long_to_short = {
    ['redhat'] = 'RH',
}

map_cpu_long_to_short = {
    ['x86_64']    = 'x86_64',
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
--
-- get_long_osarchs
--
-- Input arguments:
--   * osname: Name (with version) of the OS (currently only redhat8)
--   * archname: Architecture, e.g., zen2-noaccel or x86_64.
--
-- Output: A table with the chain of architectures, each a string with two or
-- three dash-separated entities: OS (+version), base CPU architecture and
-- accelerator architecture, using the long names.
--
-- The order is from the least generic to the most generic one.
--
function get_long_osarchs( osname, archname )

    result = {}

    while archname ~= nil
    do

        table.insert( result, osname .. '-' .. archname )
        archname = map_os_arch[osname][archname]

    end

    return result

end


-- -----------------------------------------------------------------------------
--
-- Function get_long_osarchs_reverse
--
-- Input arguments:
--   * osname: Name (with version) of the OS (currently only redhat8)
--   * archname: Architecture, e.g., zen2-noaccel or x86_64.
--
-- Output: A table with the chain of architectures, each a string with two or
-- three dash-separated entities: OS (+version), base CPU architecture and
-- accelerator architecture, using the long names.
--
-- The order is from the most generic to the least generic one.
--
function get_long_osarchs_reverse( osname, archname )

    result = {}

    while archname ~= nil
    do

        table.insert( result, 1, osname .. '-' .. archname )
        archname = map_os_arch[osname][archname]

    end

    return result

end


-- -----------------------------------------------------------------------------
--
-- Function map_long_to_short( longname )
--
-- Input arguments: 1
--   * longname: The full os-and-architecture string in long format
--
-- Return arguments: 1
--   * The full os-and-architecture string in short format
--
function map_long_to_short( longname )

    function string.split( self, delimiter )
        local result = {}
        for match in (self .. delimiter):gmatch( "(.-)" .. delimiter ) do
            table.insert( result, match );
        end
        return result;
    end

    local elements = longname:split( '-' )

    local returnlist = {}

    -- Process the OS part
    local long_os, version = elements[1]:match( '(%a+)(%d+)' )
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
-- Function map_short_to_long( shortname )
--
-- Input arguments: 1
--   * shortname: The full os-and-architecture string in short format
--
-- Return arguments: 1
--   * The full os-and-architecture string in long format
--
function map_short_to_long( shortname )

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

    local elements = shortname:split( '-' )

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
-- Function get_system_module_dir( longname, stack_name, stack_version )
--
-- Input argument: 3
--   * The long os-and-architecture name
--   * Stack name
--   * Stack version
--
-- Return argument: 1
--   * Directory, starting from the installation root.
--
function get_system_module_dir( longname, stack_name, stack_version )

    return ''

end
