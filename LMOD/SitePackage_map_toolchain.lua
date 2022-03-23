-- -----------------------------------------------------------------------------
--
-- The following mapping is used to decide which numeric version is used when
-- looking for module versions etc.
--
-- local CalcUA_toolchain_map = {
--     ['2020a'] = '2020.01',
--     ['2020b'] = '2020.07',
--     ['2021a'] = '2021.01',
--     ['2021b'] = '2021.07',
--     ['2022a'] = '2022.01',
-- }

-- -----------------------------------------------------------------------------
--
-- map_toolchain
--
-- Tries to map the toolchain version to a yyyymm format to search for a
-- matching file versions of modules etc. The general rule is that 'a' maps
-- onto '01' and 'b' onto '07', but this can be overwritten by the
-- toolchain_map associative array.
--
-- The function takes one input argument.
--  1. Version of the toolchain
--
-- The function returns one output value
--  1. The toolchain mapped onto a yyyymm version
--
function map_toolchain( version )

    local map_version

    if version:match( '%d%d%d%d%d%d' ) then
        map_version = version
    elseif version:match( '%d%d%d%d.%d%d' ) then
        map_version = version:gsub( '%.', '')
    elseif version:match( '%d%d%d%d%l' ) then
        map_version = CalcUA_toolchain_map[version]
        if map_version == nil then
            if version:match( '%d%d%d%da' ) then
                map_version = version:match( '(%d%d%d%d)a' ) .. '01'
            elseif version:match( '%d%d%d%db' ) then
                map_version = version:match( '(%d%d%d%d)b' ) .. '07'
            end
        end
    else -- This will treat version == system or manual, or an illegal version
        map_version = CalcUA_toolchain_map[version]
    end

    return map_version

end


-- -----------------------------------------------------------------------------
--
-- function get_versionedfile
--
-- Find the package with the most recent version not newer than the given CalcUA stack
-- version.
--
-- Input arguments:
-- -   matching: The CalcUA stack version to match, in any of the possible formats
--     accepted by map_toolchain. 
-- -   directory: Directory in which the matching package/file should be found.
-- -   filenameprefix: The part of the file name before the version.
-- -   filennamesuffix: The part of the file name after the suffix,
--
--  Return value: The full name of the file, or nil if no file is found.
--
function get_versionedfile( matching, directory, filenameprefix, filenamesuffix )

    local lfs = require('lfs')

    -- Convert toolchain to number
    matching = map_toolchain( matching )

    --
    -- Get a list of versions of the file
    --
    
    local versions = {}
    -- Since - and . have a special meaning in patterns, we need to replace them 
    -- with %- and %. so that they become literals
    local pattern_prefix = filenameprefix:gsub( '%-', '%%-'):gsub( '%.', '%%.' )
    local pattern_suffix = filenamesuffix:gsub( '%-', '%%-'):gsub( '%.', '%%.' )
    local pattern = '^' .. pattern_prefix .. '(.+)' .. pattern_suffix .. '$'

    local status = pcall( lfs.dir, directory )
    if not status then
        return nil
    end

    for file in lfs.dir( directory ) do
        local versionstring = file:match( pattern )
        if versionstring ~= nil then
            table.insert( versions, versionstring )
        end
    end

    --
    -- Prepare the versions structure
    --
    
    function compare( arg1, arg2 )
        return ( map_toolchain( arg1 ) < map_toolchain( arg2 ) )
    end
    table.sort( versions, compare )
    table.insert( versions, 1, '1000.00' ) -- At the first position, no other element should be smaller than 200000 (system stack)

    --
    -- Do the search and return the resulg
    --
    
    local index = #versions
    while map_toolchain( versions[index] ) > matching
    do
        index = index - 1
    end

    local returnvalue
    if index == 1 then
        returnvalue = nil
    else
        returnvalue = string.gsub( directory .. '/' .. filenameprefix .. versions[index] .. filenamesuffix, '//', '/' )
    end

    return returnvalue

end



