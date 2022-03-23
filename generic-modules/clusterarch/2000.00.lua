-- clusterarch generic module code
-- Written by Kurt Lust, kurt.lust@uantwerpen.be
--
-- This module works together with the calcua generic module to set up a version
-- of the software stack optimised for the hardware of the system
--

if os.getenv( '_CALCUA_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myModuleFullName() .. ': Entering' )
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myFileName() .. ': Entering' )
end

family( 'CalcUA_clusterarch' )
add_property("lmod","sticky")





-- Final debugging information

if os.getenv( '_CALCUA_LMOD_DEBUG' ) ~= nil then
    local modulepath = os.getenv( 'MODULEPATH' ):gsub( ':', '\n' )
    LmodMessage( 'DEBUG: ' .. mode() .. ' ' .. myModuleFullName() .. ': The MODULEPATH before exiting ' .. myModuleFullName() .. ' (mode ' .. mode() .. ') is:\n' .. modulepath .. '\n' )
end
