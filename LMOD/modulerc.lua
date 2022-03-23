--
-- Settings for the Style Modifier modules
--
-- This is a manually maintained file
--
module_version( 'ModuleColour/on',       'default' )
module_version( 'ModuleExtensions/show', 'default' )
module_version( 'ModuleLabel/label',     'default' )

if os.getenv( 'CALCUA_LMOD_POWERUSER' ) == nil then
    hide_version( 'lmod' )
end
