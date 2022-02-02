-- -----------------------------------------------------------------------------
--
-- The following mapping is used to decide which numeric version is used when
-- looking for module versions etc.
--
local toolchain_map = {
    ['2020a'] = '2020.01',
    ['2020b'] = '2020.07',
    ['2021a'] = '2021.01',
    ['2021b'] = '2021.07',
    ['2022a'] = '2022.01',
}

-- -----------------------------------------------------------------------------
--
-- map_toolchain
--
-- Tries to map the toolchain version to a yyyy.mm format to search for a
-- matching file versions of modules etc. The general rule is that 'a' maps
-- onto '.01' and 'b' onto '.07', but this can be overwritten by the
-- toolchain_map associative array.
--
-- The function takes one input argument.
--  1. Version of the toolchain
--
-- The function returns one output value
--  1. The toolchain mapped onto a yyyy.mm version
--
function map_toolchain( version )

    local map_version

    if version:match( '%d%d%d%d.%d%d' ) then
        map_version = version
    elseif version:match( '%d%d%d%d%l' ) then
        map_version = toolchain_map[version]
        if map_version == nil then
            if version:match( '%d%d%d%da' ) then
                map_version = version:match( '(%d%d%d%d)a' ) .. '.01'
            elseif version:match( '%d%d%d%db' ) then
                map_version = version:match( '(%d%d%d%d)b' ) .. '.07'
            end
        end
    else
        map_version = nil
    end

    return map_version

end



