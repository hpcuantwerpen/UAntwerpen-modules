-- -----------------------------------------------------------------------------
--
-- Helper functions and data structures for SitePackage meant
-- to avoid recomputing stuff too often during a single call
-- to Lmod.
--

--
-- Build a table with the keys from ClusterMod_map_arch_hierarchy sorted
--
CalcUA_sorted_archmap_keys = nil

function get_matching_archmap_key( version )

    if CalcUA_sorted_archmap_keys == nil then
        CalcUA_sorted_archmap_keys = {}
        for key in pairs( ClusterMod_map_arch_hierarchy )
        do
            table.insert( CalcUA_sorted_archmap_keys, key )
        end
        table.sort( CalcUA_sorted_archmap_keys )
    end

    if version < CalcUA_sorted_archmap_keys[1]
    then
        return nil
    end

    local index = #CalcUA_sorted_archmap_keys

    while CalcUA_sorted_archmap_keys[index] > version
    do
        index = index - 1
    end

    return CalcUA_sorted_archmap_keys[index]

end

--
-- Build a table with the keys from ClusterMod_map_cpu_to_gen sorted
--

CalcUA_sorted_cputogen_keys = nil

function get_matching_cputogen_key( version )

    if CalcUA_sorted_cputogen_keys == nil then
        CalcUA_sorted_cputogen_keys = {}
        for key in pairs( ClusterMod_map_cpu_to_gen )
        do
            table.insert( CalcUA_sorted_cputogen_keys, key )
        end
        table.sort( CalcUA_sorted_cputogen_keys )       
    end

    if version < CalcUA_sorted_cputogen_keys[1]
    then
        return nil
    end

    local index = #CalcUA_sorted_cputogen_keys

    while CalcUA_sorted_cputogen_keys[index] > version
    do
        index = index - 1
    end

    return CalcUA_sorted_cputogen_keys[index]

end

--
-- Build a table with the keys from ClusterMod_reduce_cpu sorted
--
CalcUA_sorted_reducecpu_keys = nil

function get_matching_reducecpu_key( version )

    if CalcUA_sorted_reducecpu_keys == nil then
        CalcUA_sorted_reducecpu_keys = {}
        for key in pairs( ClusterMod_reduce_cpu )
        do
            table.insert( CalcUA_sorted_reducecpu_keys, key )
        end
        table.sort( CalcUA_sorted_reducecpu_keys )
    end

    if version < CalcUA_sorted_reducecpu_keys[1]
    then
        return nil
    end

    local index = #CalcUA_sorted_reducecpu_keys

    while CalcUA_sorted_reducecpu_keys[index] > version
    do
        index = index - 1
    end

    return CalcUA_sorted_reducecpu_keys[index]

end

--
-- Build a table with the keys from ClusterMod_reduce_top_arch
--
CalcUA_sorted_toparchreduction_keys = nil

function get_matching_toparchreduction_key( version )

    if CalcUA_sorted_toparchreduction_keys == nil then
        CalcUA_sorted_toparchreduction_keys = {}
        for key in pairs( ClusterMod_reduce_top_arch )
        do
            table.insert( CalcUA_sorted_toparchreduction_keys, key )
        end
        table.sort( CalcUA_sorted_toparchreduction_keys )
    end

    if version < CalcUA_sorted_toparchreduction_keys[1]
    then
        return nil
    end

    local index = #CalcUA_sorted_toparchreduction_keys

    while CalcUA_sorted_toparchreduction_keys[index] > version
    do
        index = index - 1
    end

    return CalcUA_sorted_toparchreduction_keys[index]

end

--
-- Table to cache supported archs and subarchs for each stack, filled in as
-- needed.
--

CalcUA_cache_subarchs = nil
CalcUA_cache_subosarchs = nil


-- -----------------------------------------------------------------------------
--
-- Functions to check data structures
--

function is_Stack_SystemTable( stack_version )

    return ( ClusterMod_SystemTable[stack_version] ~= nil )

end


-- -----------------------------------------------------------------------------
--
-- mkDir( dirname )
--
-- Helper function to create a directory if the directory does not already exist
--

function mkDir( dirname )

    local lfs = require( 'lfs' )

    local build_dir = ''
    if dirname:sub( 1, 1 ) == '/' then
        build_dir = '/'
    end

    for str in dirname:split( '/' ) do

        if str ~= '' then

            build_dir = pathJoin( build_dir, str )
            -- print( build_dir )

            if not isDir( build_dir ) then

                -- print( build_dir .. ' not found, creating...' )

                if not lfs.mkdir( build_dir ) then
                    io.stderr:write( 'ERROR: Failed to create the directory ' .. build_dir )
                    return false
                end

            end

        end

    end

    return true

end

-- -----------------------------------------------------------------------------
--
-- Function get_user_prefix_EasyBuild
--
-- Returns the user prefix for the EasyBuild installation.
--
-- The value is taken from EBU_USER_PREFIX or if that one is not defined,
-- computed from the location of the home directory.
--
-- There is no trailing dash in the output.
--
function get_user_prefix_EasyBuild()

    local default_prefix = os.getenv( 'VSC_DATA' ) .. '/EasyBuild'
    default_prefix = default_prefix:gsub( '//', '/' ):gsub( '/$', '' )

    local ebu_user_prefix = os.getenv( 'EBU_USER_PREFIX' )

    if ebu_user_prefix == '' then
        -- EBU_USER_PREFIX is empty which indicates that there is no user
        -- installation, also not the default one.
        return nil
    else
        -- If EBU_USER_PREFIX is set, return that one and otherwise the
        -- default directory.
        return ( ebu_user_prefix or default_prefix )
    end

end
