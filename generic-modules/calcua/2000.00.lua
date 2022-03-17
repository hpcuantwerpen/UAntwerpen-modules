-- calcua generic module code
-- Written by Kurt Lust, kurt.lust@uantwerpen.be
--

if os.getenv( '_CALCUA_LMOD_DEBUG' ) ~= nil then
    LmodMessage( 'DEBUG: ' .. myModuleFullName() .. ', mode ' .. mode() )
end

-- -----------------------------------------------------------------------------
--
-- Initialisations
--

family( 'CalcUA_SoftwareStack' )
add_property("lmod","sticky")






-- Final debugging information

if os.getenv( '_CALCUA_LMOD_DEBUG' ) ~= nil then
    local modulepath = os.getenv( 'MODULEPATH' ):gsub( ':', '\n' )
    LmodMessage( 'DEBUG: The MODULEPATH before exiting ' .. myModuleFullName() .. ' (mode ' .. mode() .. ') is:\n' .. modulepath .. '\n' )
end
