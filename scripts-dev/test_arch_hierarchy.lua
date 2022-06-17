#! /usr/bin/env lua

dofile( '../scripts/calcua_tools/lmod_emulation.lua' )

--
-- Instead of readint etc/SystemDefnition.lua. we put a test example hre
--

-- -----------------------------------------------------------------------------
--
-- CalcUA_NodeTypes is simply n array of nodes in the system, specified using
-- the long os-CPU-accelerator names.
--
-- As this is a description of the current hardware in the cluster, it is not
-- for a specific version of the software stack. The table is used to produce
-- output for debug purposes of this configuration file, e.g., to list which
-- software stacks for which architectures will be available on which node 
-- types.
--

CalcUA_NodeTypes = {
    'redhat7-ivybridge-noaccel',
    'redhat7-broadwell-noaccel',
    'redhat8-boradwell-noaccel',
    'redhat8-broadwell-pascal',
    'redhat8-broadwell-P5000',
    'redhat8-skylake-noaccel',
    'redhat8-skylake-aurora1',
    'redhat8-zen2-noaccel',
    'redhat8-zen2-ampere',
    'redhat8-zen2-arcturus',
}

--
-- SystemTable defines the setup of the module system. For each toolchain it
-- indicates which OSes are supported for which architectures.
--
-- It is sufficient to only specify the "top" architectures (the leaves
-- of the tree). The other ones will be completed automatically based on
-- the architecture hierarchy structure.
--
-- This data structure should always use names from the 3L scheme to 
-- avoid any confusion. However, it is advised to not use the middle level
-- from the 3L scheme in the table, or to be extremely careful that that 
-- name is not used for toolchains that use a 2L naming
-- scheme.
--

CalcUA_SystemTable = {
    ['system'] = {
        ['redhat7'] = {
            'x86_64',
        },
        ['redhat8'] = {
            'x86_64',
        },
    },
    ['manual'] = {
        ['redhat7'] = {
            'x86_64',
        },
        ['redhat8'] = {
            'x86_64',
        },
    },
    ['2020a'] = {
        ['redhat7'] = {
            'ivybridge-noaccel',
            'broadwell-noaccel',
        },
        ['redhat8'] = {
            'zen2-noaccel',
            'skylake-noaccel',
        }
    },
    ['2021b'] = {
        ['redhat7'] = {
            'ivybridge-noaccel',
        },
        ['redhat8'] = {
            'broadwell-noaccel',
            'zen2-arcturus',
            'zen2-noaccel',
            'skylake-noaccel',
        }
    },
    ['3000a'] = {
        ['redhat7'] = {
            'ivybridge',
        },
        ['redhat8'] = {
            'broadwell-noaccel',
            'zen2-noaccel',
            'zen2-arcturus',
            'skylake-noaccel',
        }
    },
    ['4000a'] = {
        ['redhat8'] = {
            'broadwell-noaccel',
            'zen2-noaccel',
            'zen2-arcturus',
            'skylake-noaccel',
        }
    },
}

--
-- SystemProperties defines other properties of the system, e.g.,
--   * ['EasyBuild']: Version of EasyBuild to use.
--   * ['hierarchy']: Type of hierarchy, 3 values though not all are implemented
--       * 2L:  2 levels, all names on the second level include accelerator
--       * 3L: 3 levels
--
CalcUA_SystemProperties = {
    ['system'] = {
        ['EasyBuild'] = '4.5.3',
        ['hierarchy'] = '2L',  -- Doesn't really matter as we use only one level
    },
    ['manual'] = {  -- This is not an EasyBuild-managed stack.
        ['hierarchy'] = '2L',  -- Doesn't really matter as we use only one level
    },
    ['2020a'] = {
        ['EasyBuild'] = '4.2.2',
        ['hierarchy'] = '2L',
    },
    ['2021b'] = {
        ['EasyBuild'] = '4.5.3',
        ['hierarchy'] = '2L',
    },
    ['3000a'] = {
        ['EasyBuild'] = '4.5.3',
        ['hierarchy'] = '3L',
    },
    ['4000a'] = {
        ['EasyBuild'] = '4.5.3',
        ['hierarchy'] = '3L',
    },
}


--
-- CalcUA_ClusterMap is a structure that maps names of clusters onto
-- architectures.
--
-- This mapping is not defined for the 'manual' toolchain as that is not
-- one that users should be able to load via calcua modules.
--

CalcUA_ClusterMap = {
    ['system'] = {
        ['hopper'] =      'redhat7-x86_64',
        ['leibniz'] =     'redhat8-x86_64',
        ['leibniz-skl'] = 'redhat8-x86_64',
        ['vaughan'] =     'redhat8-x86_64',
    },
    ['2020a'] = {
        ['hopper'] =      'redhat7-ivybridge-noaccel',
        ['leibniz'] =     'redhat7-broadwell-noaccel',
        ['leibniz-skl'] = 'redhat8-skylake-noaccel',
        ['vaughan'] =     'redhat8-zen2-noaccel',
    },
    ['2021b'] = {
        ['hopper'] =      'redhat7-ivybridge-noaccel',
        ['leibniz'] =     'redhat8-broadwell-noaccel',
        ['leibniz-skl'] = 'redhat8-skylake-noaccel',
        ['vaughan'] =     'redhat8-zen2-noaccel',
    },
    ['3000a'] = {
        ['hopper'] =      'redhat7-ivybridge',
        ['leibniz'] =     'redhat8-broadwell-noaccel',
        ['leibniz-skl'] = 'redhat8-skylake-noaccel',
        ['vaughan'] =     'redhat8-zen2-noaccel',
    },
    ['4000a'] = {
        ['hopper'] =      'redhat7-ivybridge-noaccel',
        ['leibniz'] =     'redhat8-broadwell-noaccel',
        ['leibniz-skl'] = 'redhat8-skylake-noaccel',
        ['vaughan'] =     'redhat8-zen2-noaccel',
    },
}


--
-- SystemTable defines the setup of the module system. For each toolchain in
-- yyyy[a|b] format it gives the matching toolchain in yyyymm format that should
-- be used in version comparisons.
--

CalcUA_toolchain_map = {
    ['system'] = '200000',
    ['manual'] = '200000',
    ['2020a']  = '202001',
    ['2020b']  = '202007',
    ['2021a']  = '202101',
    ['2021b']  = '202107',
    ['2022a']  = '202201',
    ['3000a']  = '300000',
    ['4000a']  = '400000',
}


--
-- The architecture hierarchy is something that we might want to change over
-- time, in particular the choice of whether we go for two or for three
-- levels. Adding architectures is not a problem, that shouldn't break
-- anything and for that we do not need a new version of the architecture
-- hierarchy tables.
--
-- Note that in the map we use yyyymm version numbers without the dot so that
-- no additional transformations is needed in the LUA code to not slow down
-- things further.
--

CalcUA_map_arch_hierarchy = {
   -- We start with a 2-level map
   ['200000'] = {
       ['zen2-ampere']       = 'x86_64',
       ['zen2-arcturus']     = 'x86_64',
       ['zen2-noaccel']      = 'x86_64',
       ['skylake-aurora1']   = 'x86_64',
       ['skylake-noaccel']   = 'x86_64',
       ['broadwell-P5000']   = 'x86_64',
       ['broadwell-pascal']  = 'x86_64',
       ['broadwell-noaccel'] = 'x86_64',
       ['ivybridge-noaccel'] = 'x86_64',
       ['x86_64']            = nil,
   }
}
   
--
--  Mapping of CPU architectures to their generic ones, just in case we ever
--  get ARM or want to switch to two generic architectures otherwise.
--
--  Note that generic architectures are also in the table, but then get a nil
--  as a value.
--
CalcUA_map_cpu_to_gen = {
    ['200000'] = {
        ['zen2']      = 'x86_64',
        ['skylake']   = 'x86_64',
        ['broadwell'] = 'x86_64',
        ['ivybridge'] = 'x86_64',
        ['x86_64']    = nil,
    }
}
 
--
-- The following table defines the order of architectures to search if there is
-- no stack for a particular architecture. It is used to find the closest matching
-- top CPU + accelerator architecture if there is no support for an architecture
-- in a given software stack.
--
-- We support changes over time in this table as insight grows so we add again
-- an additional level based on a yyyymm representation of the software stacks
--

CalcUA_reduce_top_arch = {
    ['200000'] = {
        ['zen2-ampere']       = 'zen2-noaccel',
        ['zen2-arcturus']     = 'zen2-noaccel',
        ['zen2-noaccel']      = 'broadwell-noaccel',
        ['skylake-aurora1']   = 'skylake-noaccel',
        ['skylake-noaccel']   = 'broadwell-noaccel',
        ['broadwell-noaccel'] = 'ivybridge-noaccel',
        ['broadwell-P5000']   = 'broadwell-noaccel',
        ['broadwell-pascal']  = 'broadwell-noaccel',
        ['ivybridge-noaccel'] = 'x86_64',
        ['x86_64']            = nil,
    },
}
   
   


-- -----------------------------------------------------------------------------
--
-- Other included files
--

dofile( '../LMOD/SitePackage_helper.lua' )
dofile( '../LMOD/SitePackage_system_info.lua' )
dofile( '../LMOD/SitePackage_map_toolchain.lua' )
dofile( '../LMOD/SitePackage_arch_hierarchy.lua' )



-- -----------------------------------------------------------------------------
--
-- Some "constants"
--

local mssg_sysdep = '\27[34mSystem-dependend!\27[0m'

--
-- Testing extract_*(name) functions
--

print( '\nTesting extract_* functions\n' )
for index, longname in ipairs( { 'redhat8-zen2-arcturus', 'redhat8-x86_64' } )
do
    print( longname .. ': os is ' .. extract_os( longname ) ..
            ', CPU is ' .. extract_cpu( longname ) ..
            ', accelerator is ' .. ( extract_accel( longname ) or '' ) ..
            ', arch is ' .. extract_arch( longname ) )
end

--
-- Testing get_long_osarchs and get_long_osarchs_reverse
--

print( '\ntesting get_long_osarch and get_long_osarch_reverse\n' )

stack_versions = { '2020a', '3000a', '4000a' }
for _, stack_version in ipairs( stack_versions ) do

    print( 'Hierarchy type of toolchain version ' .. stack_version.. ': ' .. 
           CalcUA_SystemProperties[stack_version]['hierarchy'] )

    osname = 'redhat8'
    archname = 'x86_64'
    result = get_long_osarchs( stack_version, osname, archname )
    print( 'Arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )
    result = get_long_osarchs_reverse( stack_version, osname, archname )
    print( 'Reverse arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )

    osname = 'redhat8'
    archname = 'zen2-noaccel'
    result = get_long_osarchs( stack_version, osname, archname )
    print( 'Arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )
    result = get_long_osarchs_reverse( stack_version, osname, archname )
    print( 'Reverse arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )

    osname = 'redhat8'
    archname = 'zen2-arcturus'
    result = get_long_osarchs( stack_version, osname, archname )
    print( 'Arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )
    result = get_long_osarchs_reverse( stack_version, osname, archname )
    print( 'Reverse arch chain for ' .. archname .. ' on ' .. osname .. ' in toolchain ' .. stack_version .. ' is ' .. table.concat( result, ', ') )

end

--
-- Testing map_long_to_short
--

print( '\nTesting map_long_to_short\n' )
long = 'redhat8-skylake-aurora1'
print( long .. ' converts to ' .. map_long_to_short( long ) )
long = 'redhat8-broadwell-noaccel'
print( long .. ' converts to ' .. map_long_to_short( long ) )
long = 'redhat8-ivybridge'
print( long .. ' converts to ' .. map_long_to_short( long ) )

--
-- Testing map_short_to_;long
--

print( '\nTesting map_short_to_long\n' )
long = 'RH8-SKLX-NEC1'
print( long .. ' converts to ' .. map_short_to_long( long ) )
long = 'RH8-BRW-host'
print( long .. ' converts to ' .. map_short_to_long( long ) )
long = 'RH8-IVB'
print( long .. ' converts to ' .. map_short_to_long( long ) )

--
-- Testing get_calcua_generic
--

print( '\nTesting get_calcua_generic function\n' )

local inputdata = {
    {   
       ['stack_version'] = '2021b',
       ['cluster_arch'] =  'redhat8-zen2-noaccel',
       ['expected'] =      'redhat8-x86_64',
    },
    {   
       ['stack_version'] = '2021b',
       ['cluster_arch'] =  'redhat8-zen2-arcturus',
       ['expected'] =      'redhat8-x86_64',
    },            
}

for index, data in ipairs( inputdata ) do
    local got = get_calcua_generic( data['cluster_arch'], data['stack_version'] )
    local expected = data['expected']
    print( 'Generic for calcua/' .. data['stack_version'] .. ': ' ..
           got .. ', expected: ' .. data['expected'] .. ' so ' .. 
           ( got == expected and 'OK' or '\27[31mNOT OK\27[0m' ) )
end
              
--
-- Testing get_calcua_generic_current
--

print( '\nTesting get_calcua_generic_current function\n' )

for stack,_ in pairs( CalcUA_ClusterMap ) do
       print( 'Generic for ' .. stack .. ' on the current node: ' .. get_calcua_generic_current( stack ) )
end
              
--
-- Testing get_calcua_longosarch_current
--

print( '\nTesting get_calcua_longosarch_current function\n' )

for stack,_ in pairs( CalcUA_ClusterMap ) do
    print( 'Architecture of the current node in the format for ' .. stack .. ': ' .. get_calcua_longosarch_current( stack ) )
end

--
-- Testing get_calcua_top
--

print( '\nTesting get_calcua_top function\n' )

local inputdata = {
    {   
       ['stack_version'] = '2020a',
       ['cluster_arch'] =  'redhat8-zen2-noaccel',
       ['expected'] =      'redhat8-zen2-noaccel',
    },
    {   
       ['stack_version'] = '2020a',
       ['cluster_arch'] =  'redhat8-zen2-arcturus',
       ['expected'] =      'redhat8-zen2-noaccel',
    },            
}

for index, data in ipairs( inputdata ) do
    local got = get_calcua_top( data['cluster_arch'], data['stack_version'] )
    local expected = data['expected']
    print( 'Top architecture for ' .. data['cluster_arch'] .. ' in ' .. data['stack_version'] .. ' is ' ..
           got .. ', expected: ' .. data['expected'] .. ' so ' .. 
           ( got == expected and 'OK' or '\27[31mNOT OK\27[0m' ) )
end

for stack,_ in pairs( CalcUA_ClusterMap ) do
    local current_osarch
   _, _, _, current_osarch = get_clusterarch()
    print( mssg_sysdep .. ' Used architecture for ' .. current_osarch  .. 
           ' (this node) for ' .. stack .. ': ' .. 
           ( get_calcua_top( current_osarch, stack ) or '\27[31mPROBLEM, GOT NIL\27[0m' ) )
end
       
--
-- Testing get_system_module_dirs( longname, stack_name, stack_version )
--

print( '\nTesting get_system_module_dirs\n' )

stack_name =    'calcua'
stack_version = '2021b'
longname = 'redhat8-zen2-arcturus'
result = get_system_module_dirs( longname, stack_name, stack_version )
print( 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_module_dir( longname, stack_name, stack_version ) ..
       '\nFull hierarchy (lowest priority first):\n  ' ..
       table.concat( result, '\n  ') .. '\n' )

stack_name =    'calcua'
stack_version = '2021b'
longname = 'redhat8-x86_64'
result = get_system_module_dirs( longname, stack_name, stack_version )
print( 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_module_dir( longname, stack_name, stack_version ) ..
       '\nFull hierarchy (lowest priority first):\n  ' ..
       table.concat( result, '\n  ') .. '\n' )

stack_name =    'calcua'
stack_version = 'system'
longname = 'redhat8-zen2-arcturus'
result = get_system_module_dirs( longname, stack_name, stack_version )
print( 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_module_dir( longname, stack_name, stack_version ) ..
       '\nFull hierarchy (lowest priority first):\n  ' ..
       table.concat( result, '\n  ') .. '\n' )

stack_name =    'manual'
stack_version = ''
longname = 'redhat8-zen2-arcturus'
result = get_system_module_dirs( longname, stack_name, stack_version )
if result == nil then
    print( 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' returned nil as expected.\n' )
else
    print( 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' \27[31mDID NOT RETURN NIL!\27[0m\n' )
end


--
-- Testing get_system_inframodule_dir() longname, stack_name, stack_version )
--

print( '\nTesting get_system_inframodule_dirs\n' )

stack_name =    'calcua'
stack_version = '2021b'
longname = 'redhat8-zen2-arcturus'
print( 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_inframodule_dir( longname, stack_name, stack_version ) ..'\n' )

stack_name =    'calcua'
stack_version = '2021b'
longname = 'redhat8-x86_64'
print( 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_inframodule_dir( longname, stack_name, stack_version ) .. '\n' )

stack_name =    'calcua'
stack_version = 'system'
longname = 'redhat8-zen2-arcturus'
print( 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_inframodule_dir( longname, stack_name, stack_version ) .. '\n' )

stack_name =    'manual'
stack_version = ''
longname = 'redhat8-zen2-arcturus'
if get_system_inframodule_dir( longname, stack_name, stack_version ) == nil then
    print( 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' returned nil as expected.\n' )
else
    print( 'Modules of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' \27[31mDID NOT RETURN NIL!\27[0m\n' )
end


--
-- Testing get_system_SW_dir() longname, stack_name, stack_version )
--

print( '\nTesting get_system_SW_dirs\n' )

stack_name =    'calcua'
stack_version = '2021b'
longname = 'redhat8-zen2-arcturus'
print( 'Software of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_SW_dir( longname, stack_name, stack_version ) ..'\n' )

stack_name =    'calcua'
stack_version = '2021b'
longname = 'redhat8-x86_64'
print( 'Software of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_SW_dir( longname, stack_name, stack_version ) .. '\n' )

stack_name =    'calcua'
stack_version = 'system'
longname = 'redhat8-zen2-arcturus'
print( 'Software of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_SW_dir( longname, stack_name, stack_version ) .. '\n' )

stack_name =    'manual'
stack_version = ''
longname = 'redhat8-zen2-arcturus'
print( 'Software of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_SW_dir( longname, stack_name, stack_version ) .. '\n' )


--
-- Testing get_system_EBrepo_dir() longname, stack_name, stack_version )
--

print( '\nTesting get_system_EBrepo_dirs\n' )

stack_name =    'calcua'
stack_version = '2021b'
longname = 'redhat8-zen2-arcturus'
print( 'EBrepo files of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_EBrepo_dir( longname, stack_name, stack_version ) ..'\n' )

stack_name =    'calcua'
stack_version = '2021b'
longname = 'redhat8-x86_64'
print( 'EBrepo files of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_EBrepo_dir( longname, stack_name, stack_version ) .. '\n' )

stack_name =    'calcua'
stack_version = 'system'
longname = 'redhat8-zen2-arcturus'
print( 'EBrepo files of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' are in \n  ' ..
       get_system_EBrepo_dir( longname, stack_name, stack_version ) .. '\n' )

stack_name =    'manual'
stack_version = ''
longname = 'redhat8-zen2-arcturus'
stack_name =    'manual'
stack_version = ''
longname = 'redhat8-zen2-arcturus'
if get_system_EBrepo_dir( longname, stack_name, stack_version ) == nil then
    print( 'EBrepo files of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' returned nil as expected.\n' )
else
    print( 'EBrepo files of ' .. stack_name .. '/' .. stack_version .. ' for arch ' .. longname .. ' \27[31mDID NOT RETURN NIL!\27[0m\n' )
end
