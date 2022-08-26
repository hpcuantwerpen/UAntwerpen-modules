if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myModuleFullName() .. ': Entering' )
end

--
-- Some site configuration, but there may be more as there are more parts currently
-- tuned for the UAntwerp configuration
--

help( [[
This is a dummy module that should be loaded before EasyBuild-production
or EasyBuild-infrastructure can be loaded to reduce the chance of accidentally
overwriting the system installation.

The module has no other purpose.
]] )

whatis( 'EasyBuild-unlock: Must be loaded when using EasyBuild to install in the system directories.' )

-- Make this a sticky module unless it is installed in /apps/antwerpen.

if myFileName():match('^/apps/antwerpen/') == nil then
    add_property(  'lmod', 'sticky' )
end

-- Some information for debugging

if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myModuleFullName() .. ': Exiting' )
end
