-- require("strict")


function get_host_info()

    local f = io.popen( '/usr/bin/cat /proc/cpuinfo | /usr/bin/egrep "vendor_id|cpu family|model" -m 3' )
    local cpuinfo = f:read('*a') or ''
    f:close()

    -- Subsitutions:
    --  * The first three gsubs remove the first part of each line
    --  * The fourth gsub removes the newline at the end
    --  * the fifth gsub replaces the remaining two newlines with underscores.
    local cpustring = cpuinfo:gsub( 'vendor_id%s+:%s', '' ):gsub( 'cpu family%s+:%s', '' ):gsub( 'model%s+:%s', '' ):gsub( '\n$', '' ):gsub( '\n', '_' )

    f = io.popen( 'cat /etc/os-release | egrep "^NAME=|^VERSION_ID="' )
    local osinfo = f:read('*a') or ''
    f:close()

    -- Get the name of the OS:
    _, _, osname = osinfo:find( 'NAME="([%w%s]+)"' )
    local osname = osname:gsub( '%s', '_' )

    -- Get the version of the OS (where we assume that it can be a major.minor as in SLES)
    local osversion
    _, _, osversion = osinfo:find( 'VERSION_ID="([%d%p]+)"' )

    f = io.popen( '/usr/sbin/lspci | /usr/bin/egrep "MI100|GA100|GP104|GP100|NEC" -m 1' )
    local accelinfo = f:read('*a') or ''
    f:close()

    local accelerator = nil
    if     accelinfo:find( 'MI100' ) then accelerator = 'AMD_MI100'
    elseif accelinfo:find( 'GP100' ) then accelerator = 'NVIDIA_GP100'
    elseif accelinfo:find( 'GP104' ) then accelerator = 'NVIDIA_GP104'
    elseif accelinfo:find( 'GA100' ) then accelerator = 'NVIDIA_GA100'
    elseif accelinfo:find( 'NEC' )   then accelerator = 'NEC_aurora1'
    end

    return cpustring, osname, osversion, accelerator

end


function get_clusterarch()

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
        CentOS_Linux = 'centos',
    }

    local osname_to_shortos = {
        CentOS_Linux = 'COS',
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

    local cpustring, osname, osversion, accelerator = get_host_info()

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

    local clusterarch_short = cpustring_to_shorttarget[cpustring] .. '-' ..
                              osname_to_shortos[osname] .. osversion
    local clusterarch_long  = cpustring_to_longtarget[cpustring] .. '-' ..
                              osname_to_longos[osname] .. osversion

    if accelerator ~= nil then
        clusterarch_short = clusterarch_short .. '-' .. accelerator_to_shortacc[accelerator]
        clusterarch_long  = clusterarch_long  .. '-' .. accelerator_to_longacc[accelerator]
    end

    return clusterarch_short, clusterarch_long

end


cpustring, osname, osversion, accelerator = get_host_info()

if accelerator then
    print( cpustring .. ', ' .. osname .. ' ' .. osversion .. ', ' .. accelerator )
else
    print( cpustring .. ', ' .. osname .. ' ' .. osversion )
end

clusterarch_short, clusterarch_long = get_clusterarch()

print( 'Short arch: ' .. clusterarch_short .. ', long arch: ' .. clusterarch_long )
