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

function get_matching_key( version )

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

