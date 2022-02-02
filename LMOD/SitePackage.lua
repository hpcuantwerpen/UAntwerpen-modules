-- CalcUA Lmod customizations

require( 'strict' )
local os   = require( 'os' )
local dbg  = require( 'Dbg' ):dbg()
local hook = require( 'Hook' )
require("sandbox")

local lmod_dir = os.getenv( 'LMOD_PACKAGE_PATH' )
dofile( pathJoin( lmod_dir, 'SitePackage_map_toolchain.lua' ) )

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
-- get_cpu_info
--
-- Get information about the host. The function returns 1 value:
--  1. The CPU type in the form <vendpr_id>_<family>_<model>
--     Values observed are:
--      * AuthenticAMD_23_49: zen2/rome
--      * GenuineIntel_6_62:  Ivy Bridge
--      * GenuineIntel_6_79:  Broadwell
--      * GenuineIntel_6_85:  Skylake and Cascade Lake
--
-- This function is not currently exported to module files.
--
function get_cpu_info()

    local f = io.popen( '/usr/bin/cat /proc/cpuinfo | /usr/bin/egrep "vendor_id|cpu family|model" -m 3' )
    local cpuinfo = f:read('*a') or ''
    f:close()

    -- Subsitutions:
    --  * The first three gsubs remove the first part of each line
    --  * The fourth gsub removes the newline at the end
    --  * the fifth gsub replaces the remaining two newlines with underscores.
    local cpustring = cpuinfo:gsub( 'vendor_id%s+:%s', '' ):gsub( 'cpu family%s+:%s', '' ):gsub( 'model%s+:%s', '' ):gsub( '\n$', '' ):gsub( '\n', '_' )

    return cpustring

end


-- -----------------------------------------------------------------------------
--
-- get_os_info
--
-- Get information about the host. The function returns 2 values:
--  1. The name of the OS
--  2. The version of the OS
--
-- This function is not currently exported to module files.
--
function get_os_info()

    f = io.popen( 'cat /etc/os-release | egrep "^NAME=|^VERSION_ID="' )
    local osinfo = f:read('*a') or ''
    f:close()

    -- Get the name of the OS by looking for the NAME line in the data read from /etc/os-release
    _, _, osname = osinfo:find( 'NAME="([%w%s]+)"' )
    local osname = osname:gsub( '%s', '_' )

    -- Get the version of the OS (where we assume that it can be a major.minor as in SLES)
    local osversion
    _, _, osversion = osinfo:find( 'VERSION_ID="([%d%p]+)"' )

    return osname, osversion

end


-- -----------------------------------------------------------------------------
--
-- get_accelerator_info
--
-- Get information about the host. The function returns 1 value:
--  1. The type of the accelerator:
--      * AMD_MI100    (vaughan AMD Instinct nodes)
--      * NVIDIA_GP100 (leibniz Pascal nodes)
--      * NVIDIA_GP104 (leibniz visualization node)
--      * NVIDIA_GA100 (vaughan Ampere node)
--      * NEC_aurora1  (leibniz Aurora node)
--
-- This function is not currently exported to module files.
--
function get_accelerator_info()

    -- Search for the accelerators in the output of lscpci
    f = io.popen( '/usr/sbin/lspci | /usr/bin/egrep "MI100|GA100|GP104|GP100|NEC" -m 1' )
    local accelinfo = f:read('*a') or ''
    f:close()

    -- Process the output to extract the specific accelerator.
    local accelerator = nil
    if     accelinfo:find( 'MI100' ) then accelerator = 'AMD_MI100'
    elseif accelinfo:find( 'GP100' ) then accelerator = 'NVIDIA_GP100'
    elseif accelinfo:find( 'GP104' ) then accelerator = 'NVIDIA_GP104'
    elseif accelinfo:find( 'GA100' ) then accelerator = 'NVIDIA_GA100'
    elseif accelinfo:find( 'NEC' )   then accelerator = 'NEC_aurora1'
    end

    return accelerator

end


-- -----------------------------------------------------------------------------
--
-- Data structures for mapping CPU, OS and accelerator to the names that are
-- actually used in the modules
--
local cpustring_to_longtarget = {
    AuthenticAMD_23_49 = 'zen2',
    GenuineIntel_6_62  = 'ivybridge',
    GenuineIntel_6_79  = 'broadwell',
    GenuineIntel_6_85  = 'skylake',
}

local cpustring_to_shorttarget = {
    AuthenticAMD_23_49 = 'zen2',
    GenuineIntel_6_62  = 'IVB',
    GenuineIntel_6_79  = 'BRW',
    GenuineIntel_6_85  = 'SKLX',
}

local osname_to_longos = {
    CentOS_Linux = 'redhat',
}

local osname_to_shortos = {
    CentOS_Linux = 'RH',
}

local accelerator_to_longacc = {
    AMD_MI100    = 'arcturus',
    NVIDIA_GA100 = 'ampere',
    NVIDIA_GP100 = 'pascal',
    NVIDIA_GP104 = 'quadro',
    NEC_aurora1  = 'aurora1',
}

local accelerator_to_shortacc = {
    AMD_MI100    = 'GFX908',
    NVIDIA_GA100 = 'NVCC80',
    NVIDIA_GP100 = 'NVCC60',
    NVIDIA_GP104 = 'NVCC61GL',
    NEC_aurora1  = 'NEC1',
}


-- -----------------------------------------------------------------------------
--
-- get_clusterarch
--
-- Returns the cluster architecture for use in the clusterarch modules in
-- different ways.
--
-- The function returns 4 values:
--  1. Short minimal name, i.e., no `-host` is added for nodes without
--     accelerator.
--  2. Long minimal name, i.e., no `-noaccel` is added for nodes without
--     accelerator.
--  3. Short name, with `-host` added for nodes without accelerator
--  4. Long name, with `-noaccel` added for nodes without accelerator
-- e.g., `RH8-zen2, redhat8-zen2, RH8-zen2-host, redhat8-zen2-noaccel` or
-- `RH8-SKLX-NEC1, redhat8-skylake-aurora1, RH8-SKLX-NEC1, redhat8-skylake-aurora1`
--
function get_clusterarch()

    local cpustring         = get_cpu_info()
    local osname, osversion = get_os_info()
    local accelerator       = get_accelerator_info()

    if cpustring == nil then
        io.stderr:write( 'SitePackage.lua get_clusterarch/get_host_info: Failed to determine the CPU type.\n' )
        return nil, nil
    end

    if osname == nil then
        io.stderr:write( 'SitePackage.lua get_clusterarch/get_host_info: Failed to determine the OS name.\n' )
        return nil, nil
    end

    if osversion == nil then
        io.stderr:write( 'SitePackage.lua get_clusterarch/get_host_info: Failed to determine the OS version.\n' )
        return nil, nil
    end

    if cpustring_to_longtarget[cpustring] == nil then
        io.stderr:write( 'SitePackage.lua get_clusterarch/get_host_info: The target ' .. cpustring .. ' is unknown.\n' )
        return nil, nil
    end

    if osname_to_longos[osname] == nil then
        io.stderr:write( 'SitePackage.lua get_clusterarch/get_host_info: The OS name ' .. osname .. ' is unknown.\n' )
        return nil, nil
    end

    if accelerator ~= nil and accelerator_to_longacc[accelerator] == nil then
        io.stderr:write( 'SitePackage.lua get_clusterarch/get_host_info: The accelerator ' .. accelerator .. ' is unknown.\n' )
        return nil, nil
    end

    local clusterarch_short_minimal = osname_to_shortos[osname] .. osversion  .. '-' ..
                                      cpustring_to_shorttarget[cpustring]
    local clusterarch_long_minimal  = osname_to_longos[osname] .. osversion .. '-' ..
                                      cpustring_to_longtarget[cpustring]
    local clusterarch_short
    local clusterarch_long

    if accelerator == nil then
        clusterarch_short = clusterarch_short_minimal .. '-host'
        clusterarch_long  = clusterarch_long_minimal  .. '-noaccel'
    else
        clusterarch_short_minimal = clusterarch_short_minimal .. '-' .. accelerator_to_shortacc[accelerator]
        clusterarch_long_minimal  = clusterarch_long_minimal  .. '-' .. accelerator_to_longacc[accelerator]
        clusterarch_short = clusterarch_short_minimal
        clusterarch_long  = clusterarch_long_minimal
    end

    return clusterarch_short_minimal, clusterarch_long_minimal, clusterarch_short, clusterarch_long

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
    ['get_clusterarch']           = get_clusterarch,
    [ 'map_toolchain']            = map_toolchain,
}




