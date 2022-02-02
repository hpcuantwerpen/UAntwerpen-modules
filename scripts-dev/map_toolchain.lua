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


for _, toolchain in ipairs( { '2020a', '2020b', '2020.01', '2023a', '2019b' } ) do
    print( 'Toolchain ' .. toolchain .. ' maps to ' .. map_toolchain(toolchain) )
end
