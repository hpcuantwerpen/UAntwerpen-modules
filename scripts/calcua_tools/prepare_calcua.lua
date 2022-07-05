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

