--------------------------------------------------------------------------
--
-- This is a file that replaces a number of functions that are available
-- in Lmod when writing routines for SitePackage.lua. It can be included
-- in test scripts to enable routine developement without having to
-- test everything via Lmod modules.
--
-- Important functions included in this file:
-- -   pathJoin
-- -   string.split can be useful also but is not part of the official
--     Lmod API.
-- -   isDir. The implementation from Lmod uses lfs and that seems to
--     work better than an implementation using the posix package.
--

--------------------------------------------------------------------------
-- An iterator to loop split a pieces.  This code is from the
-- lua-users.org/lists/lua-l/2006-12/msg00414.html
-- @param self input string
-- @param pat pattern to split on.

function string.split(self, pat)

   pat  = pat or "%s+"
   local st, g = 1, self:gmatch("()("..pat..")")

   local function getter( myself, segs, seps, sep, cap1, ... )

      st = sep and seps + #sep

      return myself:sub( segs, (seps or 0) - 1 ), cap1 or sep, ...

   end

   local function splitter( myself )

      if st then return getter( myself, st, g() ) end

   end

   return splitter, self

end

function string.trim(self)

   local ja = self:find( "%S" )

   if (ja == nil) then return '' end

   local jb = self:find( "%s+$" ) or 0

   return self:sub( ja, jb-1 )

end

--------------------------------------------------------------------------
-- Remove leading and trail spaces and extra slashes.
-- @param value A path
-- @return A clean canonical path.
function path_regularize(value, full)
   if value == nil then return nil end
   value = value:gsub("^%s+", "")
   value = value:gsub("%s+$", "")
   value = value:gsub("//+" , "/")
   value = value:gsub("/%./", "/")
   value = value:gsub("/$"  , "")
   value = value:gsub("^~"  , os.getenv("HOME") or "~")
   if (value == '') then
      value = ' '
      return value
   end
   local a    = {}
   local aa   = {}
   for dir in value:split("/") do
      aa[#aa + 1] = dir
   end

   local first  = aa[1]
   local icnt   = 2
   local num    = #aa
   if (first == ".") then
      for i = 2, num do
         if (aa[i] ~= ".") then
            icnt = i
            break
         else
            icnt = icnt + 1
         end
      end
      a[1] = (icnt > num) and "." or aa[icnt]
      icnt = icnt + 1
   else
      a[1] = first
   end

   if (full) then
      for i = icnt, #aa do
         local dir  = aa[i]
         local prev = a[#a]
         if (    dir == ".." and prev ~= "..") then
            a[#a] = nil
         elseif (dir ~= ".") then
            a[#a+1] = dir
         end
      end
   else
      for i = icnt, #aa do
         local dir  = aa[i]
         local prev = a[#a]
         if (dir ~= ".") then
            a[#a+1] = dir
         end
      end
   end

   value = table.concat(a,"/")

   return value
end


--------------------------------------------------------------------------
-- Join argument into a path that has single slashes between directory
-- names and no trailing slash.
-- @return a file path with single slashes between directory names
-- and no trailing slash.

function pathJoin(...)
   local a    = {}
   local argA = table.pack(...)
   for i = 1, argA.n  do
      local v = argA[i]
      if (v and v ~= '') then
         local vType = type(v)
         if (vType ~= "string") then
            local msg = "bad argument #" .. i .." (string expected, got " .. vType .. " instead)\n"
            assert(vType ~= "string", msg)
         end
         v = v:trim()
         if (v:sub(1,1) == '/' and i > 1) then
            if (v:len() > 1) then
               v = v:sub(2,-1)
            else
               v = ''
            end
         end
         v = v:gsub('//+','/')
         if (v:sub(-1,-1) == '/') then
            if (v:len() > 1) then
               v = v:sub(1,-2)
            elseif (i == 1) then
               v = '/'
            else
               v = ''
            end
         end
         if (v:len() > 0) then
            a[#a + 1] = v
         end
      end
   end
   local s = table.concat(a,"/")
   s = path_regularize(s)
   return s
end


--------------------------------------------------------------------------
--
-- isDir - Check if a directory exists.
--
-- This implementation uses the lfs package and works even if the directory
-- is a symbolic link to another directory.
--
function isDir( dir )

    local lfs = require( 'lfs' )

    if ( dir == nil ) then return false end

    local attr = lfs.attributes( dir )

    return ( attr and attr.mode == 'directory' )

end


--------------------------------------------------------------------------
--
-- LmodError - Print an error message
--
-- This implementation will simply print an error message but currently 
-- does not interrupt the execution
--
function LmodError( error_string )

    io.write( error_string .. '\n' )

end