#! /usr/bin/env lua
--
-- Get a list of EasyBuild versions needed for the current node type
--

local lfs = require( 'lfs' )

local routine_name = 'helper_get_clustername'

local script_called_dir = arg[0]:match( '(.*)/[^/]+' )
lfs.chdir( script_called_dir )
local repo_root = lfs.currentdir():match( '(.*)/scripts/ClusterMod_tools' )
local root_dir = repo_root:match( '(.*)/[^/]+' )

-- Note that pathJoin is not defined here....
local softwarestack = ( os.getenv( 'CLUSTERMOD_SOFTWARESTACK' ) or ( root_dir .. '/etc/SoftwareStack.lua' ) )
dofile( softwarestack )

dofile( systemdefinition )

--
-- Actual code
--

print( ClusterMod_ClusterName )
