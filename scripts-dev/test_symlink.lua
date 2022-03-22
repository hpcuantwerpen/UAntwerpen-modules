#! /usr/bin/env lua

local lfs = require( 'lfs' )

link_name = arg[1]

link_name_attr = lfs.symlinkattributes( link_name )

if link_name_attr == nil then

    print( link_name .. ' does not exist' )

elseif link_name_attr.mode == 'file' then
    
    print( link_name .. ' already exists but is a regular file.' )

elseif link_name_attr.mode == 'link' then

    print( link_name .. ' exists and is a link with target ' .. link_name_attr.target )

else
    print( link_name .. ' exists and is a ' .. link_name_attr.mode )

end
