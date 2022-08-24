#! /bin/bash

#
# Latest versions
# - LUA: http://www.lua.org/download.html
# - LuaRocks: https://github.com/luarocks/luarocks/wiki/Download
# - luaposix: https://github.com/luaposix/luaposix/releases
# - luafilesystem: https://keplerproject.github.io/luafilesystem/index.html#download
# - TCL: https://www.tcl.tk/software/tcltk/
# - LMOD: https://github.com/TACC/Lmod/releases
#
lua_version=5.4.4
luarocks_version=3.9.0
luaposix_version='35.1'
luafilesystem_version='1.8'
tcl_version=8.6.12
lmod_version=8.7.10

# Just to be sure, add the binary directory to the PATH.
installdir="$VSC_DATA/Software/$VSC_INSTITUTE_CLUSTER"
workdir="$VSC_SCRATCH/Work"
PATH="$installdir/bin:$PATH"

mkdir -p "$workdir"
cd "$workdir"

#
# Lua installation
#
# - Lua itself
#
cd "$workdir"
# https://www.lua.org/ftp/lua-5.4.3.tar.gz
[[ -f lua-$lua_version.tar.gz ]] || wget https://www.lua.org/ftp/lua-$lua_version.tar.gz
tar -xf lua-$lua_version.tar.gz
cd "$workdir/lua-$lua_version"
# Patch src/luaconf.h to use the correct value for LUA_ROOT
# as otherwise packages will not be found
sed -i -e "s/\/usr\/local\//${installdir//\//\\\/}\//" src/luaconf.h
# Build
make linux install INSTALL_TOP="$installdir"
#
# - LuaRocks
#
cd "$workdir"
[[ -f luarocks-$luarocks_version.tar.gz ]] || wget https://luarocks.org/releases/luarocks-$luarocks_version.tar.gz
tar -xf luarocks-$luarocks_version.tar.gz
cd "$workdir/luarocks-$luarocks_version"
./configure --with-lua="$installdir" --prefix="$installdir"
make ; make install
#
# - posix and filesystem packages
#
cd "$workdir"
luarocks --lua-dir "$installdir" install luaposix $luaposix_version
luarocks --lua-dir "$installdir" install luafilesystem

#
# Install Tcl
#
cd "$workdir"
# https://prdownloads.sourceforge.net/tcl/tcl8.6.11-src.tar.gz
[[ -f tcl$tcl_version-src.tar.gz ]] || wget https://prdownloads.sourceforge.net/tcl/tcl$tcl_version-src.tar.gz
tar -xf tcl$tcl_version-src.tar.gz
cd "$workdir/tcl$tcl_version/unix"
./configure --prefix="$installdir"
make ; make install
cd "$installdir/bin"
ln -s tclsh8.6 tclsh

#
# Install Lmod
#
cd "$workdir"
[[ -f lmod-$lmod_version.tar.gz ]] || eval "wget https://github.com/TACC/Lmod/archive/refs/tags/$lmod_version.tar.gz ; mv $lmod_version.tar.gz lmod-$lmod_version.tar.gz"
tar -xf lmod-$lmod_version.tar.gz
cd "$workdir/Lmod-$lmod_version"
TCL_INCLUDE="-I$installdir/include" \
PATH_TO_TCLSH="$installdir/bin/tclsh8.6" \
./configure --prefix=$installdir/share \
            --with-lua_include=/$installdir/include \
            --with-lua=$installdir/bin/lua \
            --with-luac=$installdir/bin/luac
make install

#
# Clean up
#
cd "$workdir"
rm -rf lua-$lua_version
rm -rf luarocks-$luarocks_version
rm -rf tcl$tcl_version
rm -rf Lmod-$lmod_version

# Initialise:
# module purge
# source $HOME/appl/share/lmod/lmod/init/bash
