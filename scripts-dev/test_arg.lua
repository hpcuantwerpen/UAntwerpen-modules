#! /usr/bin/env lua

local lfs = require( 'lfs' )

print( 'Calling this script as ' .. arg[0] )

directory = arg[0]:match( '(.*)/[^/]+' )
print( 'Found directory ' .. directory )

lfs.chdir( directory )

print( 'Scripts are in: ' .. lfs.currentdir() )
