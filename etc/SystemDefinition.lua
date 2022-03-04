-- -----------------------------------------------------------------------------
--
-- SystemTable defines the setup of the module system. For each toolchain it
-- indicates which OSes are supported for which architectures.
--
-- It is sufficient to only specify the "main" architectures (the leaves
-- of the tree). The other ones will be completed automatically based on 
-- the architecture hierarchy structure.
-- 

CalcUA_SystemTable = {
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
        ['redhat8'] = {
            'ivybridge-noaccel',
            'broadwell-noaccel',
            'zen2-noaccel',
            'skylake-noaccel',
        }
    },
}

-- -----------------------------------------------------------------------------
--
-- SystemTable defines the setup of the module system. For each toolchain in
-- yyyy[a|b] format it gives the matching toolchain in yyyymm format that should
-- be used in version comparisons. 
--

CalcUA_toolchain_map = {
    ['system'] = '200000',
    ['2020a']  = '202001',
    ['2020b']  = '202007',
    ['2021a']  = '202101',
    ['2021b']  = '202107',
    ['2022a']  = '202201',
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
-- Note:
--   - Current 2-level map:
--         ['zen2-noaccel']      = 'x86_64',
--         ['zen2-ampere']       = 'x86_64',
--         ['zen2-arcturus']     = 'x86_64',
--         ['broadwell-noaccel'] = 'x86_64',
--         ['broadwell-P5000']   = 'x86_64',
--         ['broadwell-pascal']  = 'x86_64',
--         ['skylake-noaccel']   = 'x86_64',
--         ['skylake-aurora1']   = 'x86_64',
--         ['ivybridge-noaccel'] = 'x86_64',
--         ['x86_64']            = nil,
--  - Current 3-level map: 
--         ['zen2-noaccel']      = 'zen2',
--         ['zen2-ampere']       = 'zen2',
--         ['zen2-arcturus']     = 'zen2',
--         ['zen2']              = 'x86_64',
--         ['broadwell-noaccel'] = 'broadwell',
--         ['broadwell-P5000']   = 'broadwell',
--         ['broadwell-pascal']  = 'broadwell',
--         ['broadwell']         = 'x86_64',
--         ['skylake-noaccel']   = 'skylake',
--         ['skylake-aurora1']   = 'skylake',
--         ['skylake']           = 'x86_64',
--         ['ivybridge-noaccel'] = 'x86_64',
--         ['x86_64']            = nil,

CalcUA_map_arch_hierarchy = {
    -- We start with a 2-level map 
    ['200000'] = {
        ['zen2-noaccel']      = 'x86_64',
        ['zen2-ampere']       = 'x86_64',
        ['zen2-arcturus']     = 'x86_64',
        ['broadwell-noaccel'] = 'x86_64',
        ['broadwell-P5000']   = 'x86_64',
        ['broadwell-pascal']  = 'x86_64',
        ['skylake-noaccel']   = 'x86_64',
        ['skylake-aurora1']   = 'x86_64',
        ['ivybridge-noaccel'] = 'x86_64',
        ['x86_64']            = nil,    
    }
}

