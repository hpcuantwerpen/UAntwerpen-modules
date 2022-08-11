-- -----------------------------------------------------------------------------
--
-- Helper functions and data structures for SitePackage meant
-- to avoid recomputing stuff too often during a single call
-- to Lmod.
--

--
-- Build a table with the keys from ClusterMod_map_arch_hierarchy sorted
--
ClusterMod_sorted_archmap_keys = nil

function get_matching_archmap_key( version )

    if ClusterMod_sorted_archmap_keys == nil then
        ClusterMod_sorted_archmap_keys = {}
        for key in pairs( ClusterMod_map_arch_hierarchy )
        do
            table.insert( ClusterMod_sorted_archmap_keys, key )
        end
        table.sort( ClusterMod_sorted_archmap_keys )
    end

    if version < ClusterMod_sorted_archmap_keys[1]
    then
        return nil
    end

    local index = #ClusterMod_sorted_archmap_keys

    while ClusterMod_sorted_archmap_keys[index] > version
    do
        index = index - 1
    end

    return ClusterMod_sorted_archmap_keys[index]

end

--
-- Build a table with the keys from ClusterMod_map_cpu_to_gen sorted
--

ClusterMod_sorted_cputogen_keys = nil

function get_matching_cputogen_key( version )

    if ClusterMod_sorted_cputogen_keys == nil then
        ClusterMod_sorted_cputogen_keys = {}
        for key in pairs( ClusterMod_map_cpu_to_gen )
        do
            table.insert( ClusterMod_sorted_cputogen_keys, key )
        end
        table.sort( ClusterMod_sorted_cputogen_keys )       
    end

    if version < ClusterMod_sorted_cputogen_keys[1]
    then
        return nil
    end

    local index = #ClusterMod_sorted_cputogen_keys

    while ClusterMod_sorted_cputogen_keys[index] > version
    do
        index = index - 1
    end

    return ClusterMod_sorted_cputogen_keys[index]

end

--
-- Build a table with the keys from ClusterMod_reduce_cpu sorted
--
ClusterMod_sorted_reducecpu_keys = nil

function get_matching_reducecpu_key( version )

    if ClusterMod_sorted_reducecpu_keys == nil then
        ClusterMod_sorted_reducecpu_keys = {}
        for key in pairs( ClusterMod_reduce_cpu )
        do
            table.insert( ClusterMod_sorted_reducecpu_keys, key )
        end
        table.sort( ClusterMod_sorted_reducecpu_keys )
    end

    if version < ClusterMod_sorted_reducecpu_keys[1]
    then
        return nil
    end

    local index = #ClusterMod_sorted_reducecpu_keys

    while ClusterMod_sorted_reducecpu_keys[index] > version
    do
        index = index - 1
    end

    return ClusterMod_sorted_reducecpu_keys[index]

end

--
-- Build a table with the keys from ClusterMod_reduce_top_arch
--
ClusterMod_sorted_toparchreduction_keys = nil

function get_matching_toparchreduction_key( version )

    if ClusterMod_sorted_toparchreduction_keys == nil then
        ClusterMod_sorted_toparchreduction_keys = {}
        for key in pairs( ClusterMod_reduce_top_arch )
        do
            table.insert( ClusterMod_sorted_toparchreduction_keys, key )
        end
        table.sort( ClusterMod_sorted_toparchreduction_keys )
    end

    if version < ClusterMod_sorted_toparchreduction_keys[1]
    then
        return nil
    end

    local index = #ClusterMod_sorted_toparchreduction_keys

    while ClusterMod_sorted_toparchreduction_keys[index] > version
    do
        index = index - 1
    end

    return ClusterMod_sorted_toparchreduction_keys[index]

end

--
-- Table to cache supported archs and subarchs for each stack, filled in as
-- needed.
--

ClusterMod_cache_subarchs = nil
ClusterMod_cache_subosarchs = nil


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


