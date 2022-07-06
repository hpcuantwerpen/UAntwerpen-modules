#! /usr/bin/env lua

local lfs = require( 'lfs' )

local routine_name = 'prepare_calcua'
local stack_name = 'calcua'

if #arg ~= 1 then
    io.stderr:write( routine_name .. ': ERROR: One command line argument is expected: software stack configuration file.\n' )
    os.exit( 1 )
end

dofile( arg[1] )

dofile( systemdefinition )

dofile( repo_modules .. '/scripts/calcua_tools/lmod_emulation.lua' )
dofile( repo_modules .. '/LMOD/SitePackage_helper.lua' )
dofile( repo_modules .. '/LMOD/SitePackage_map_toolchain.lua' )
dofile( repo_modules .. '/LMOD/SitePackage_arch_hierarchy.lua' )


--
-- Internal functions
--

function create_symlink( target, name )

    local lfs = require( 'lfs' )
    
    --
    -- Note that we prefer to always re-create the link if it exists already.
    -- So far we know no way to figure out if the link is pointing to the right file,
    -- and we may run this script simply because some links have changed.
    --
    local name_attrs = lfs.symlinkattributes( name )
    if name_attrs == nil then
        -- This is a new file
        print( '\nCreating symlink: ' .. target .. ' -> ' .. name )
        lfs.link( target, name, true )
    elseif name_attrs.mode == 'link' then
        if name_attrs.target == nil then
            print( '\nLink ' .. name .. ' exists but cannot determine the target, so re-creating symlink ' .. target .. ' -> ' .. name )
            os.remove( name )
            lfs.link( target, name, true )
        elseif name_attrs.target == target then
            print( '\nLink ' .. name .. ' exists and is pointing to the right target ' .. target )
        else
            print( '\nLink ' .. name .. ' exists but current target ' .. name_attrs.target .. ' is different, re-creating symlink ' .. target .. ' -> ' .. name )
            os.remove( name )
            lfs.link( target, name, true )
        end
    elseif name_attrs == 'file' then
        -- Finding a file is somewhat unexpected but we can handle it:
        -- remove the file and create the link.
        print( '\nFile ' .. name .. ' exists, replacing with symlink ' .. target .. ' -> ' .. name )
        os.remove( name )
        lfs.link( target, name, true )
    else
        print( '\n' .. name .. ' exists as a ' .. name_attrs.mode .. ', do not know how to handle this.' )
    end

end

-- ----------------------------------------------------------------------------
--
-- What happens in the script:
-- -   Build an overview of all architectures for all software stacks
-- -   Set up the infrastructure modules structure
-- -   Set up the EasyBuild modules structure
-- -   Set up the software directories
-- -   Set up the structure for the EasyBuild files repo
-- -   Other work:
--     -   Create sources subdirectory that will be used by EasyBuild.
-- 