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
    Rocky_Linux  = 'redhat',
}

local osname_to_shortos = {
    CentOS_Linux = 'RH',
    Rocky_Linux  = 'RH',
}

local accelerator_to_longacc = {
    AMD_MI100    = 'arcturus',
    NVIDIA_GA100 = 'ampere',
    NVIDIA_GP100 = 'pascal',
    NVIDIA_GP104 = 'P5000',
    NEC_aurora1  = 'aurora1',
}

local accelerator_to_shortacc = {
    AMD_MI100    = 'GFX908',
    NVIDIA_GA100 = 'NVCC80',
    NVIDIA_GP100 = 'NVCC60',
    NVIDIA_GP104 = 'NVCC61GL',
    NEC_aurora1  = 'NEC1',
}

--
-- Data structures determining how to extract the OS version (whether we want the
-- major verison only or major.minor)
--
-- Note:
-- -   CentOS only reports the major version in VERSION_ID in /etc/os-releases
-- -   Rocky Linux on the other hand reports a major.minor version in VERSION_ID in
--     /etc/os-releases.
-- In the following table, we indicate if we want major or major.minor for the OS.
-- The keys of the table are the names of the OS as found in the NAME field of 
-- /etc/os-releases.
local os_version_type = {
    CentOS_Linux = 'major',
    Rocky_Linux  = 'major',
}


-- -----------------------------------------------------------------------------
--
-- function get_hostname()
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
-- get_cpu_info()
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
-- get_os_info()
--
-- Get information about the host. The function returns 2 values:
--  1. The name of the OS
--  2. The version of the OS
--
-- This function is not currently exported to module files.
--
function get_os_info()

    local d1
    local d2

    local f = io.popen( 'cat /etc/os-release | egrep "^NAME=|^VERSION_ID="' )
    local osinfo = f:read('*a') or ''
    f:close()

    -- Get the name of the OS by looking for the NAME line in the data read from /etc/os-release
    local osname
    d1, d2, osname = osinfo:find( 'NAME="([%w%s]+)"' )
    osname = osname:gsub( '%s', '_' )

    -- Get the version of the OS (where we take into account that for some OSes
    -- we may want major.minor versions as even minor versions differ significantly
    -- and can cause compatibility problems.
    local osversion
    if os_version_type[osname] == 'major' then
        d1, d2, osversion = osinfo:find( 'VERSION_ID="([%d]+)[%d%p]*"' )
    else
        d1, d2, osversion = osinfo:find( 'VERSION_ID="([%d%p]+)"' )
    end

    return osname, osversion

end


-- -----------------------------------------------------------------------------
--
-- get_accelerator_info()
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
    local f = io.popen( '/usr/sbin/lspci | /usr/bin/egrep "MI100|GA100|GP104|GP100|NEC" -m 1' )
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
-- get_cluster_longosarch
--
-- Returns the cluster architecture for use in the clusterarch modules in the
-- long os-cpu-acclerator format, e.g., redhat2-zen2-noaccel.
--
function get_cluster_longosarch()

    local cpustring         = get_cpu_info()
    local osname, osversion = get_os_info()
    local accelerator       = get_accelerator_info()

    if cpustring == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_cluster_longosarch/get_cpu_info: Failed to determine the CPU type.\n' )
        return nil, nil
    end

    if osname == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_cluster_longosarch/get_os_info: Failed to determine the OS name.\n' )
        return nil, nil
    end

    if osversion == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_cluster_longosarch/get_os_info: Failed to determine the OS version.\n' )
        return nil, nil
    end

    if cpustring_to_longtarget[cpustring] == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_cluster_longosarch: The target ' .. cpustring .. ' is unknown.\n' )
        return nil, nil
    end

    if osname_to_longos[osname] == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_cluster_longosarch: The OS name ' .. osname .. ' is unknown.\n' )
        return nil, nil
    end

    if accelerator ~= nil and accelerator_to_longacc[accelerator] == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_cluster_longosarch: The accelerator ' .. accelerator .. ' is unknown.\n' )
        return nil, nil
    end

    local cluster_longosarch = osname_to_longos[osname] .. osversion .. '-' ..
                               cpustring_to_longtarget[cpustring]

    if accelerator == nil then
        cluster_longosarch  = cluster_longosarch  .. '-noaccel'
    else
        cluster_longosarch  = cluster_longosarch  .. '-' .. accelerator_to_longacc[accelerator]
    end

    return cluster_longosarch

end


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
--  3. Short maximal name, with `-host` added for nodes without accelerator
--  4. Long maximal name, with `-noaccel` added for nodes without accelerator
-- e.g., `RH8-zen2, redhat8-zen2, RH8-zen2-host, redhat8-zen2-noaccel` or
-- `RH8-SKLX-NEC1, redhat8-skylake-aurora1, RH8-SKLX-NEC1, redhat8-skylake-aurora1`
--
function get_clusterarch()

    local cpustring         = get_cpu_info()
    local osname, osversion = get_os_info()
    local accelerator       = get_accelerator_info()

    if cpustring == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_clusterarch/get_cpu_info: Failed to determine the CPU type.\n' )
        return nil, nil
    end

    if osname == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_clusterarch/get_os_info: Failed to determine the OS name.\n' )
        return nil, nil
    end

    if osversion == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_clusterarch/get_os_info: Failed to determine the OS version.\n' )
        return nil, nil
    end

    if cpustring_to_longtarget[cpustring] == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_clusterarch: The target ' .. cpustring .. ' is unknown.\n' )
        return nil, nil
    end

    if osname_to_longos[osname] == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_clusterarch: The OS name ' .. osname .. ' is unknown.\n' )
        return nil, nil
    end

    if accelerator ~= nil and accelerator_to_longacc[accelerator] == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_clusterarch: The accelerator ' .. accelerator .. ' is unknown.\n' )
        return nil, nil
    end

    local clusterarch_short_minimal = osname_to_shortos[osname] .. osversion  .. '-' ..
                                      cpustring_to_shorttarget[cpustring]
    local clusterarch_long_minimal  = osname_to_longos[osname] .. osversion .. '-' ..
                                      cpustring_to_longtarget[cpustring]
    local clusterarch_short_maximal
    local clusterarch_long_maximal

    if accelerator == nil then
        clusterarch_short_maximal = clusterarch_short_minimal .. '-host'
        clusterarch_long_maximal  = clusterarch_long_minimal  .. '-noaccel'
    else
        clusterarch_short_minimal = clusterarch_short_minimal .. '-' .. accelerator_to_shortacc[accelerator]
        clusterarch_long_minimal  = clusterarch_long_minimal  .. '-' .. accelerator_to_longacc[accelerator]
        clusterarch_short_maximal = clusterarch_short_minimal
        clusterarch_long_maximal  = clusterarch_long_minimal
    end

    return clusterarch_short_minimal, clusterarch_long_minimal, clusterarch_short_maximal, clusterarch_long_maximal

end


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
--  3. Short maximal name, with `-host` added for nodes without accelerator
--  4. Long maximal name, with `-noaccel` added for nodes without accelerator
-- e.g., `RH8-zen2, redhat8-zen2, RH8-zen2-host, redhat8-zen2-noaccel` or
-- `RH8-SKLX-NEC1, redhat8-skylake-aurora1, RH8-SKLX-NEC1, redhat8-skylake-aurora1`
--
function get_clusterarch()

    local cpustring         = get_cpu_info()
    local osname, osversion = get_os_info()
    local accelerator       = get_accelerator_info()

    if cpustring == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_clusterarch/get_cpu_info: Failed to determine the CPU type.\n' )
        return nil, nil
    end

    if osname == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_clusterarch/get_os_info: Failed to determine the OS name.\n' )
        return nil, nil
    end

    if osversion == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_clusterarch/get_os_info: Failed to determine the OS version.\n' )
        return nil, nil
    end

    if cpustring_to_longtarget[cpustring] == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_clusterarch: The target ' .. cpustring .. ' is unknown.\n' )
        return nil, nil
    end

    if osname_to_longos[osname] == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_clusterarch: The OS name ' .. osname .. ' is unknown.\n' )
        return nil, nil
    end

    if accelerator ~= nil and accelerator_to_longacc[accelerator] == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_clusterarch: The accelerator ' .. accelerator .. ' is unknown.\n' )
        return nil, nil
    end

    local clusterarch_short_minimal = osname_to_shortos[osname] .. osversion  .. '-' ..
                                      cpustring_to_shorttarget[cpustring]
    local clusterarch_long_minimal  = osname_to_longos[osname] .. osversion .. '-' ..
                                      cpustring_to_longtarget[cpustring]
    local clusterarch_short_maximal
    local clusterarch_long_maximal

    if accelerator == nil then
        clusterarch_short_maximal = clusterarch_short_minimal .. '-host'
        clusterarch_long_maximal  = clusterarch_long_minimal  .. '-noaccel'
    else
        clusterarch_short_minimal = clusterarch_short_minimal .. '-' .. accelerator_to_shortacc[accelerator]
        clusterarch_long_minimal  = clusterarch_long_minimal  .. '-' .. accelerator_to_longacc[accelerator]
        clusterarch_short_maximal = clusterarch_short_minimal
        clusterarch_long_maximal  = clusterarch_long_minimal
    end

    return clusterarch_short_minimal, clusterarch_long_minimal, clusterarch_short_maximal, clusterarch_long_maximal

end


-- -----------------------------------------------------------------------------
--
-- get_fullos()
--
-- Returns the long OS name including the version
--
function get_fullos()

    local osname, osversion = get_os_info()

    if osname == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_fullos/get_os_info: Failed to determine the OS name.\n' )
        return nil, nil
    end

    if osversion == nil then
        io.stderr:write( 'SitePackage_system_info.lua get_fullos/get_os_info: Failed to determine the OS version.\n' )
        return nil, nil
    end

    return osname_to_longos[osname] .. osversion

end


