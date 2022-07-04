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
-- Our virtual test cluster defined below supports the following architectures:
--
-- - manual (2L)
--     - redhat7:
--         - redhat7-x86_64
--     - redhat8:
--         - redhat8-x86_64
-- - system (2L)
--     - redhat7:
--         - redhat7-x86_64
--     - redhat8:
--         - redhat8-broadwell-noaccel
--         - redhat8-zen2-noaccell
--         - Remark: redha8-skylake-* nodes should fall back to redha8-broadwell-noaccel
-- TODO: Complete for other toolchains.

CalcUA_NodeTypes = {
    'redhat7-ivybridge-noaccel',
    'redhat7-broadwell-noaccel',
    'redhat8-broadwell-noaccel',
    'redhat8-broadwell-pascal',
    'redhat8-broadwell-P5000',
    'redhat8-skylake-noaccel',
    'redhat8-skylake-aurora1',
    'redhat8-zen2-noaccel',
    'redhat8-zen2-ampere',
    'redhat8-zen2-arcturus',
}

-- -----------------------------------------------------------------------------
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
            'broadwell-noaccel',
            'zen2-noaccel',
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
            'ivybridge-noaccel',
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

-- -----------------------------------------------------------------------------
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
        ['hierarchy'] = '2L',
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


-- -----------------------------------------------------------------------------
--
-- CalcUA_ClusterMap is a structure that maps names of clusters onto
-- architectures. Each should be the topmost supported architecture for a 
-- particular node type.
--
-- This mapping is not defined for the 'manual' toolchain as that is not
-- one that users should be able to load via calcua modules.
--

CalcUA_ClusterMap = {
    ['system'] = {
        ['hopper'] =      'redhat7-x86_64',
        ['leibniz'] =     'redhat8-broadwell-noaccel',
        ['leibniz-skl'] = 'redhat8-broadwell-noaccel',
        ['vaughan'] =     'redhat8-zen2-noaccel',
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
        ['hopper'] =      'redhat7-ivybridge-noaccel',
        ['leibniz'] =     'redhat8-broadwell-noaccel',
        ['leibniz-skl'] = 'redhat8-skylake-noaccel',
        ['vaughan'] =     'redhat8-zen2-noaccel',
    },
    ['4000a'] = {
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


-- -----------------------------------------------------------------------------
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
       ['zen3-noaccel']      = 'x86_64',
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
   },
   -- From 3000a on we need a 3-level map
   ['300000'] = {
       ['zen3-noaccel']      = 'zen3',
       ['zen3']              = 'x86_64',
       ['zen2-ampere']       = 'zen2',
       ['zen2-arcturus']     = 'zen2',
       ['zen2-noaccel']      = 'zen2',
       ['zen2']              = 'x86_64',
       ['skylake-aurora1']   = 'skylake',
       ['skylake-noaccel']   = 'skylake',
       ['skylake']           = 'x86_64',
       ['broadwell-P5000']   = 'broadwell',
       ['broadwell-pascal']  = 'broadwell',
       ['broadwell-noaccel'] = 'broadwell',
       ['broadwel']          = 'x86_64',
       ['ivybridge-noaccel'] = 'ivybridge',
       ['ivybridge']         = 'x86_64',
       ['x86_64']            = nil,
   },
}
   
-- -----------------------------------------------------------------------------
--
-- Map defining the CPU architectures and whether they are generic or 
-- not. 
--
CalcUA_def_cpu = {
    ['zen4']      = false,
    ['zen3']      = false,
    ['zen2']      = false,
    ['skylake']   = false,
    ['broadwell'] = false,
    ['ivybridge'] = false,
    ['x86_64']    = true,
}
 
-- -----------------------------------------------------------------------------
--
-- Mapping of CPU architectures to their generic ones, just in case we ever
-- get ARM or want to switch to two generic architectures otherwise.
--
-- Note that generic architectures are also in the table, but then get a nil
-- as a value.
--
CalcUA_map_cpu_to_gen = {
    ['200000'] = {
        ['zen3']      = 'x86_64',
        ['zen2']      = 'x86_64',
        ['skylake']   = 'x86_64',
        ['broadwell'] = 'x86_64',
        ['ivybridge'] = 'x86_64',
        ['x86_64']    = nil,
    }
}
 
-- -----------------------------------------------------------------------------
--
-- The following table defines reduction rules for CPUs.
-- For each stack in CalcUA_SystemTable, these reduction rules have to be compatible
-- with the matching ones in CalcUA_reduce_top_Arch. I.e., if somehow
-- CPU1-Accel1 in CalcUA_reduce_top_arch reduces to CPU2-Accel2 then it must 
-- also be possible to reduce CPU1 to CPU2 (in one or more steps) using the
-- rules specified in the following table.
--
-- The chain 
--

CalcUA_reduce_cpu = {
    ['200000'] = {
        ['zen3']      = 'zen2',
        ['zen2']      = 'broadwell',
        ['skylake']   = 'broadwell',
        ['broadwell'] = 'ivybridge',
        ['ivybridge'] = 'x86_64',
        ['x86_64']    = nil,
    },
}
   
-- -----------------------------------------------------------------------------
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
        ['zen3-noaccel']      = 'zen2-noaccel',
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

