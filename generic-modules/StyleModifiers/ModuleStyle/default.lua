if os.getenv( '_CALCUA_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. myModuleFullName() .. ', mode ' .. mode() .. ': Entering' )
end
--
-- This module will restore the default module display by loading all default modules
-- for those that have multiple versions and unloading all others. The default versions
-- are not determined in this module, but by the system modulerc.lua file.
--
-- Note that this module is deliberaty not sticky unless most other ModuleStyle modules
-- as unloading doens't do anything at the moment.
--

whatis( 'Restores the module display style to the default intended by the system admins' )

help( [[

Description
===========
Loading this module will restore the default module display style as intended by the
system administrators. It differs from ModuleSystem/reset as the latter tries to restore
the situation determined by the Lmod configuration.

Unloading this module has no effect.
]])

if mode() == 'load' then
    load( 'ModuleColour' )
    load( 'ModuleExtensions' )
    load( 'ModuleLabel' )
    unload( 'ModulePowerUser' )
end

if os.getenv( '_CALCUA_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. myModuleFullName() .. ', mode ' .. mode() .. ': Exiting' )
end
