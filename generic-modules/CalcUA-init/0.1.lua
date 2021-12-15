if os.getenv( '_CALCUA_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myFileName() .. ': Entering' )
end

--
-- Some initialisation
--
add_property("lmod","sticky")

-- Find the root of the LUMI installation.
local LUMI_root = myFileName():match( '(.*)/modules/init%-.*/CalcUA%-init/.*' )
local repo =  myFileName():match( '.*/modules/init%-(.*)/CalcUA%-init/.*' )

-- -----------------------------------------------------------------------------
--
-- Enhanced message-of-the-day
--

if mode() == 'load' or mode() == 'show' then

    if os.getenv( '_CALCUA_INIT_FIRST_LOAD' ) == nil then

        -- Get the MOTD and print.
        --
        -- The problem with LmodMessage is that it does some undesired
        -- formatting to the output string, replacing multiple spaces
        -- with single spaces after the initial non-space character.
        -- Note that LmodMessage itself also writes the result with
        -- io.stderr:write.
        local motd = get_motd()
        if mode() == 'load' and motd ~= nil then
            io.stderr:write( motd .. '\n\n' )
        end

        -- Get a fortune text.
        local fortune = get_fortune()
         if mode() == 'load' and fortune ~= nil then
            io.stderr:write( 'Did you know?\n' ..
                             '=============\n' ..
                             fortune .. '\n' )
        end


        -- Make sure this block of code is not executed anymore.
        -- This statement is not reached during an unload of the module
        -- so _CALCUA_INIT_FIRST_LOAD will not be unset anymore.
        setenv( '_CALCUA_INIT_FIRST_LOAD', '1' )

    end

end



-- -----------------------------------------------------------------------------
--
-- Help information
--

help( [[
Description
===========
The CalcUA-init module performs most of the initialisations needed to use the
CalcUA software stacks.


More information
================
  - CalcUA infrastructure documentation on the VSC web site:
    https://docs.vscentrum.be/en/latest/antwerp/tier2_hardware.html
  - Local CalcUA documentation: https://www.uantwerpen.be/en/core-facilities/calcua/
]] )

whatis( 'CalcUA-init: Initialisation module for the software stacks. Remove at your own risk.' )

-- Debug message
if os.getenv( '_CALCUA_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myFileName() .. ': Exiting' )
end


