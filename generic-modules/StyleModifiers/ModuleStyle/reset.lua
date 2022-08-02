if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. myModuleFullName() .. ', mode ' .. mode() .. ': Entering' )
end
--
-- This module will restore the default module display by unloading all style modules.
-- Hence the state is no longer visible from the loaded modules.
--
-- Note that this module is deliberaty not sticky unless most other ModuleStyle modules
-- as unloading doens't do anything at the moment.
--

whatis( 'Resets the module display style to the initial view at login.' )

help( [[

Description
===========
Loading this module will reset the module display style to the system default 
determined by the Lmod installation.

Unloading this module has no effect.
]])

if mode() == 'load' then
    unload( 'ModuleColour' )
    unload( 'ModuleExtensions' )
    unload( 'ModuleLabel' )
    unload( 'ModulePowerUser' )
end

if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. myModuleFullName() .. ', mode ' .. mode() .. ': Exiting' )
end
