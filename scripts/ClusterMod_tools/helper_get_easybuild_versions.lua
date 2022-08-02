#! /usr/bin/env lua
--
-- Get a list of EasyBuild versions needed for the current node type
--

local lfs = require( 'lfs' )

local routine_name = 'helper_get_easybuild_version'

local script_called_dir = arg[0]:match( '(.*)/[^/]+' )
lfs.chdir( script_called_dir )
local repo_root = lfs.currentdir():match( '(.*)/scripts/ClusterMod_tools' )
local root_dir = repo_root:match( '(.*)/[^/]+' )

-- Note that pathJoin is not defined here....
local softwarestack = ( os.getenv( 'CLUSTERMOD_SOFTWARESTACK' ) or ( root_dir .. '/etc/SoftwareStack.lua' ) )
dofile( softwarestack )

dofile( systemdefinition )

dofile( repo_root .. '/LMOD/SitePackage_system_info.lua' )
-- dofile( repo_root .. '/LMOD/SitePackage_map_toolchain.lua' )


--
-- Actual code
--
local my_os = get_fullos()

local EBversion_table = {}

for stack_version, _ in pairs( ClusterMod_SystemTable ) do

    if ClusterMod_SystemTable[stack_version] ~= nil then
        -- Found a toolchain that should be installed for this OS, check if it needs
        -- EasyBuild and if so store the version of EasyBuild.

        if ClusterMod_SystemProperties[stack_version]['EasyBuild'] ~= nil then
            EBversion_table[ClusterMod_SystemProperties[stack_version]['EasyBuild']] = true
        end

    end

end

local EBversions = {}

for EBversion, _ in pairs( EBversion_table ) do
    table.insert( EBversions, EBversion )
end
table.sort( EBversions )

print( table.concat( EBversions, ' ' ) )
