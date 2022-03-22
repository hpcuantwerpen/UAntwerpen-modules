#! /usr/bin/env lua
--
-- Map a toolchain version onto a yyyymm version
--
-- Input: One command line argument:
--   * stack_version
--
-- Output: Prints the matching yyyymm version using the map_toolchain function
--

local lfs = require( 'lfs' )

local routine_name = 'helper_get_generic_current'
local stack_name = 'calcua'

if #arg ~= 1 then
    io.stderr:write( routine_name .. ': ERROR: One command line argument is expected: the version of the calcua stack.\n' )
    os.exit( 1 )
end

local stack_version = arg[1]

local script_called_dir = arg[0]:match( '(.*)/[^/]+' )
lfs.chdir( script_called_dir )
local repo_root = lfs.currentdir():match( '(.*)/scripts/calcua_tools' )
local root_dir = repo_root:match( '(.*)/[^/]+' )

dofile( repo_root .. '/etc/SystemDefinition.lua' )
dofile( repo_root .. '/LMOD/SitePackage_map_toolchain.lua' )


if CalcUA_SystemTable[stack_version] == nil then
    io.stderr:write( routine_name .. ': ERROR: The stack version ' .. stack_version .. ' is not recognized as a valid stack.\n' ..
                     'Maybe CalcUA_SystemTable in etc/SystemDefinition.lua needs updating?\n' )
    os.exit( 1 )
end

--
-- Actual code
--
print( map_toolchain( stack_version ) )
