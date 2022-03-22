-- -----------------------------------------------------------------------------
--
-- Helper functions and data structures for SitePackage meant
-- to avoid recomputing stuff too often during a single call
-- to Lmod.
--

--
-- Build a table with the keys from CalcUA_map_arch_hierarchy sorted
--
CalcUA_sorted_archmap_keys = {}

for key in pairs( CalcUA_map_arch_hierarchy )
do
    table.insert( CalcUA_sorted_archmap_keys, key )
end
table.sort( CalcUA_sorted_archmap_keys )

function get_matching_archmap_key( version )

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

