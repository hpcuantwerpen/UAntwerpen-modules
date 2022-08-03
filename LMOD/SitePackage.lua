-- CalcUA Lmod customizations

require( 'strict' )
local os   = require( 'os' )
local dbg  = require( 'Dbg' ):dbg()
local hook = require( 'Hook' )
require("sandbox")

local lmod_dir = os.getenv( 'LMOD_PACKAGE_PATH' )

--
-- Read the SoftwareStack.lua file with the basic configuration parameters.
-- TODO: Get the location of this file out of an environment variable...
--
local softwarestack = ( os.getenv( 'CLUSTERMOD_SOFTWARESTACK' ) or pathJoin( lmod_dir, '../../etc/SoftwareStack.lua' ) )
dofile( softwarestack )

--
-- Read the system definition
--
dofile( systemdefinition )

--
-- Include additional LUA code into SitePackage.lua
--
dofile( pathJoin( lmod_dir, 'SitePackage_helper.lua' ) )
dofile( pathJoin( lmod_dir, 'SitePackage_system_info.lua' ) )     -- This has to go in front of SitePackage_arch_hierarchy.lua!
dofile( pathJoin( lmod_dir, 'SitePackage_map_toolchain.lua' ) )
dofile( pathJoin( lmod_dir, 'SitePackage_arch_hierarchy.lua' ) )

-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
--
-- LMOD additional functions
--
-- These are put first so that they can be used in the hooks also.
--
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
--
-- function get_configuration
--
-- Returns a few configuration variables: The place of the system definition
-- and of the two repositories.
--
function get_configuration( )

    return repo_modules, repo_easybuild, systemdefinition

end



-- -----------------------------------------------------------------------------
--
-- function get_motd
--
-- Returns the message-of-the-day in the etc subdirectory of this repository,
-- or nil if the file is empty or not found.
--
function get_motd()

    local LMOD_root = os.getenv( 'LMOD_PACKAGE_PATH' )
    local motd_file = pathJoin( LMOD_root, '../etc/motd.txt' )

    -- Read the file in a single read statement
    local fp = io.open( motd_file, 'r' )
    if fp == nil then return nil end
    local motd = fp:read( '*all' )
    fp:close()

    -- Delete trailing white space.
    motd = motd:gsub( '%s*$', '' )

    -- Return nil if we had an empty file and otherwise return the motd
    if  #(motd) == 0 then
        return nil
    else
        return motd
    end

end


-- -----------------------------------------------------------------------------
--
-- function get_fortune
--
-- Returns a "fortune text" read from etc/CalcUA_fortune.txt
--
function get_fortune()

    local LMOD_root = os.getenv( 'LMOD_PACKAGE_PATH' )
    local fortune_file = pathJoin( LMOD_root, '../etc/CalcUA_fortune.txt' )

    -- Read the file in a single read statement
    local fp = io.open( fortune_file, 'r' )
    if fp == nil then return nil end
    local fortune = fp:read( '*all' )
    fp:close()

    -- Now split up in the blocks of text and delete leading and
    -- trailing whitespace in each block
    local separator = '====='
    local fortune_table = {}
    for str in string.gmatch( fortune, "([^" .. separator .. "]+)" ) do
        str = str:gsub( '^%s*', ''  ):gsub( '%s*$', '' )
        table.insert( fortune_table, str )
    end

    -- Select a text block (based on the time)
    -- Indices in LUA arrays start at 1.
    local fortune_number = os.time() % #(fortune_table) + 1

    return fortune_table[fortune_number] .. '\n'

end


-- -----------------------------------------------------------------------------
--
-- function is_interactive()
--
-- Input arguments: None
-- Output: True for an interactive shell, otherwise false.
--
-- NOTE: It uses os.execute to run tty. It looks like the first return
-- argument is true for a shell with attached tty and nil for one without
-- one. The third output argument is 0 for a shell with tty and nonzero
-- if no tty is attached to the shell.
--
function is_interactive()

    if os.execute( '/usr/bin/tty -s' ) then
        return true
    else
        return false
    end

end






-- -----------------------------------------------------------------------------
--
-- Register in the sandbox
--
sandbox_registration{
    ['get_configuration']             = get_configuration,
--    ['get_hostname']                  = get_hostname,
    ['get_clustername']               = get_clustername,                -- Defined in SitePackage_system_info
    ['get_motd']                      = get_motd,                       -- Defined in SitePackage
    ['get_fortune']                   = get_fortune,                    -- Defined in SitePackage
    ['get_user_prefix_EasyBuild']     = get_user_prefix_EasyBuild,      -- Defined in SitePackage_helper
    ['is_interactive']                = is_interactive,                 -- Defined in SitePackage
--    ['get_cluster_osarch']            = get_cluster_osarch,
--    ['get_clusterarch']               = get_clusterarch,
--    [ 'map_toolchain']                = map_toolchain,
    ['get_stack_osarch_current']      = get_stack_osarch_current,
    ['get_stack_matchingarch']        = get_stack_matchingarch,
    ['get_system_module_dirs']        = get_system_module_dirs,         -- Defined in SitePackage_arch_hierarchy
    ['get_user_module_dirs']          = get_user_module_dirs,           -- Defined in SitePackage_arch_hierarchy
    ['get_system_inframodule_dir']    = get_system_inframodule_dir,     -- Defined in SitePackage_arch_hierarchy
--    ['get_stack_top']                 = get_stack_top,
    ['is_Stack_SystemTable']          = is_Stack_SystemTable,           -- Defined in SitePackage_helper
}



-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
--
-- LMOD hooks
--
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------


local function site_name_hook()
    -- set the SiteName
    return "CALCUA"
end


local function packagebasename(t)
    -- Use the EBROOT variables in the module
    -- as base dir for the reverse map
    t.patDir = "^EBROOT.*"
end


-- -----------------------------------------------------------------------------
--
-- avail_hook
--
-- Code to rename directories in module avail
-- Based on "Providing Custom Labels for Avail" in the Lmod manual
-- Note that this requires the use of LMOD_AVAIL_STYLE, and in this case,
-- LMOD_AVAIL_STYLE=labeled:system to make the labeled style the default.
--

-- We need to avoid that EB_prefix is nil so give it some meaningless value if it would
-- be nil.
-- local EB_prefix = string.gsub( get_user_prefix_EasyBuild() or '/NONE', '%-', '%%-' )

local mapT =
{
    label = {
--        ['/testview$']                      = 'Activate environments',
        ['modules%-infrastructure/init']            = 'System initialisation',
        ['modules%-infrastructure/StyleModifiers']  = 'Modify the module display style',
        ['modules%-infrastructure/stack$']          = 'Software stacks',
        ['modules%-infrastructure/arch/']           = 'Available architectures for the software stack _STACK_',
        -- LMOD
        ['usr/share/lmod/lmod/modulefiles']         = 'LMOD modules',
        -- User-installed software
--        [ EB_prefix .. '/modules']          = 'EasyBuild managed user software for software stack _STACK_ on _PARTITION_',
     },
}


local function avail_hook(t)

    dbg.start( 'avail_hook' )

    --
    -- Use labels instead of directories (if selected)
    --

    local availStyle = masterTbl().availStyle
    local styleT     = mapT[availStyle]
    if (not availStyle or availStyle == "system" or styleT == nil) then
        io.stderr:write('Avail hook: style not found\n')
        return
    end

    local stack = os.getenv( 'CALCUA_STACK_NAME_VERSION' ) or 'unknown'
    local partition = 'CALCUA-' .. ( os.getenv( 'CALCUA_STACK_PARTITION' ) or 'X' )

    for directory, dirlabel in pairs(t) do
        for pattern, label in pairs(styleT) do
            if (directory:find(pattern)) then
                t[directory] = label:gsub( '_PARTITION_', partition ):gsub( '_STACK_', stack )
                break
            end
        end
    end

    dbg.fini()

end



-- -----------------------------------------------------------------------------
--
-- Hook registration
--

hook.register( 'SiteName',        site_name_hook)
hook.register( 'packagebasename', packagebasename)
hook.register( 'avail',           avail_hook )



