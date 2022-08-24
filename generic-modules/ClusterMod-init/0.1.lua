if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myFileName() .. ': Entering' )
end

--
-- Some initialisation
--
add_property( 'lmod', 'sticky' )

-- Find the root of the module installation.
local ClusterMod_root = myFileName():match( '(.*)/modules%-infrastructure/init/.*%-init/.*' )

repo_modules,repo_easybuild,systemdefinition = get_configuration( )
if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myFileName() .. ': working with module repo ' .. repo_modules ..
                 ' and EasyBuild repo ' .. repo_easybuild )
end

-- -----------------------------------------------------------------------------
--
-- The actual work
--

-- Setting defaults and visibility, note that this is a PATH-style variable.
-- It is currently set by the enable_ClusterMod script already, but add this in again
-- if needed.
-- prepend_path( 'LMOD_MODULERCFILE', pathJoin( repo_modules, 'LMOD', 'modulerc.lua' ) )

--
-- Make the modules that determine visibility available
--
prepend_path( 'MODULEPATH', pathJoin( ClusterMod_root, 'modules-infrastructure/StyleModifiers' ) )

-- Set the display style of the modules
-- Note that if we set LMOD_MODULERCFILE only in this module and not at initialisation,
-- we should not rely on the default versions, so switch the loads below.

if mode() == 'load' or mode() == 'show' then

    if not isloaded( 'ModuleColour' ) then
        try_load( 'ModuleColour' )
        -- load( 'ModuleColour/on' )
    end

    if not isloaded( 'ModuleExtensions' ) then
        try_load( 'ModuleExtensions' )
        -- load( 'ModuleExtensions/show' )
    end

    if not isloaded( 'ModuleLabel' ) then
        try_load( 'ModuleLabel' )
        -- load( 'ModuleLabel/label' )
    end
    
end


--
-- Make the software stacks available
--
prepend_path( 'MODULEPATH', pathJoin( ClusterMod_root, 'modules-infrastructure/stack' ) )

-- -----------------------------------------------------------------------------
--
-- Enhanced message-of-the-day
--

if mode() == 'load' or mode() == 'show' then

    local var_name = '_' .. get_clustername():upper() .. '_INIT_FIRST_LOAD'

    local show_motd = not isFile( pathJoin( os.getenv( 'HOME' ) or '', '.nomotd' ) )
    local show_tip  = not isFile( pathJoin( os.getenv( 'HOME' ) or '', '.nomotdtip' ) ) and show_motd

    if os.getenv( var_name ) == nil and is_interactive() then

        -- Get the MOTD and print.
        --
        -- The problem with LmodMessage is that it does some undesired
        -- formatting to the output string, replacing multiple spaces
        -- with single spaces after the initial non-space character.
        -- Note that LmodMessage itself also writes the result with
        -- io.stderr:write.
        local motd = get_motd()
        if mode() == 'load' and motd ~= nil and show_motd then
            io.stderr:write( motd .. '\n\n' )
        end

        -- Get a fortune text.
        local fortune = get_fortune()
         if mode() == 'load' and fortune ~= nil and show_tip then
            io.stderr:write( 'Did you know?\n' ..
                             '=============\n' ..
                             fortune .. '\n' )
        end


        -- Make sure this block of code is not executed anymore.
        -- This statement is not reached during an unload of the module
        -- so _<PREFIX>_INIT_FIRST_LOAD will not be unset anymore.
        setenv( var_name, '1' )

    end

end



-- -----------------------------------------------------------------------------
--
-- Help information
--

local site_name = get_clustername()

help( [[
Description
===========
The ]] .. site_name .. [[-init module performs most of the initialisations needed to use the
]]  .. site_name .. [[ software stacks.


Usage
=====
You can disable the display of the tip at the end of the message-of-the-day by creating
a file .nomotdtip in your home directory, e.g.,

$ touch ~/.nomotdtip

You can disable the complete message-of-the-day except for some header by creating a file
.nomotd in your home directory, e.g.,

$ touch ~/.nomotd

Note that it is still your responsability to be aware of the information that is spread
via the message-of-the-day, so do not blame the ]] .. site_name .. [[ User Support Team if you
miss information because you hide the message-of-the-day. If you are new on the system
you may have missed information that is in the message-of-the-day and spread by email.
]] )

whatis( site_name .. '-init: Initialisation module for the software stacks. Unload at your own risk.' )

-- Debug message
if os.getenv( '_CLUSTERMOD_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myFileName() .. ': Exiting' )
end


