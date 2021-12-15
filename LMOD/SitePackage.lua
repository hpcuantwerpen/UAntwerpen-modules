-- CalcUA Lmod customizations

require("strict")
local os = require("os")
local dbg  = require("Dbg"):dbg()
local hook = require("Hook")
require("sandbox")

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
-- function get_hostname
--
-- Gets the hostname from the system.
--
-- In the implementation, we call /bin/hostname rather than relying on environment
-- variables so that this is guaranteed to work, also on systems with the default
-- SLURM setup that copies the environment from the node where the job was
-- submitted and may not reset the HOSTNAME variable if no login shell is
-- used.
--
function get_hostname()

    local f = io.popen ("/bin/hostname")
    local hostname = f:read("*a") or ""
    f:close()

    -- Clean up: Remove new line at the end
    hostname =string.gsub(hostname, "\n$", "")

    return hostname

end

-- -----------------------------------------------------------------------------
--
-- Function get_user_prefix_EasyBuild
--
-- Returns the user prefix for the EasyBuild installation.
--
-- The value is taken from EBU_USER_PREFIX or if that one is not defined,
-- computed from the location of the home directory.
--
-- There is no trailing dash in the output.
--
function get_user_prefix_EasyBuild()

    local home_prefix = os.getenv( 'HOME' ) .. '/EasyBuild'
    home_prefix = home_prefix:gsub( '//', '/' ):gsub( '/$', '' )

    local ebu_user_prefix = os.getenv( 'EBU_USER_PREFIX' )

    if ebu_user_prefix == '' then
        -- EBU_USER_PREFIX is empty which indicates that there is no user
        -- installation, also not the default one.
        return nil
    else
        -- If EBU_USER_PREFIX is set, return that one and otherwise the
        -- default directory.
        return ( ebu_user_prefix or home_prefix )
    end

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
-- Register in the sandbox
--
sandbox_registration{
    ['get_hostname']              = get_hostname,
    ['get_user_prefix_EasyBuild'] = get_user_prefix_EasyBuild,
    ['get_motd']                  = get_motd,
    ['get_fortune']               = get_fortune,
}




