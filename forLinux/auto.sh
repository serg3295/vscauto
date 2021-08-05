#!/bin/sh

# Keep the Lua.version = "" for automatically getting value from
# 'sumneko Lua Language server' setting. Set $luaVer to "5.1" or "5.3"
# if 'sumneko Lua Language server' VSCode extension is not installed.
#
luaVer="" # or = "5.3" | "5.1"
lfs_size=0x040000
lfs_base=0x084000

lfs_mapped=$(( 0x40200000 + $lfs_base )) # LFS region at ESP address 0x402'base'

rmFile () {
  if [ -f $1 ]; then
    rm $1
  fi
}

# Trying to get the 'Lua.runtime.version' value from sumneko.Lua extension
if [ -z $luaVer ]; then
  fpath="./.vscode/settings.json"
  if [ -f $fpath ]; then
  luaVer=`grep -oE '"Lua.runtime.version": "Lua 5.[1-4]"' $fpath | grep -oE '5.[1-4]'`
  fi
fi

if [ -z $luaVer ]; then
  echo "\033[31mThe 'Lua.runtime.version' setting from 'sumneko Lua language server' extension was not found! Set Lua version manually in this script.\033[0m"
  exit 1
fi

if   [ $luaVer = "5.3" ]; then
  luacCross=/opt/lua/5.3/luac.cross
elif [ $luaVer = "5.1" ]; then
  luacCross=/opt/lua/5.1/luac.cross
else
  echo "\033[31mIncorrect Lua version: $luaVer\033[0m"
  exit 1
fi

case $1 in
#--- command - FTP: build LFS & upload ---
  1)
    fpath=$2
    rmFile $fpath
    $luacCross -o $fpath -f -m $lfs_size -l $4/*.lua > $5
    if [ -f $fpath ]; then
      curl -T $fpath --config $3 --ftp-pasv --disable-epsv --progress-bar --list-only
      curl --config $3 --ftp-pasv --disable-epsv -Q "LFS" --list-only
    else
      echo "\033[31mCompile error\033[0m"
    fi
  ;;

#--- command - COM: LFS build, upload & flashreload ---
  2)
    fpath=$3
    rmFile $fpath
    $luacCross -o $fpath -f -m $lfs_size -l $4/*.lua > $5
    if [ -f $fpath ]; then
      nodemcu-tool upload $2 $fpath
      nodemcu-tool $2 terminal --run "lfsreload.lua"
    else
      echo "\033[31mCompile error\033[0m"
    fi
  ;;

#--- command - COM: File compile, upload, run in terminal ---
  3)
    fpath=$3
    rmFile $fpath
    $luacCross -o $fpath -l $4 > $5
    if [ -f $fpath ]; then
      nodemcu-tool upload $2 $fpath
      nodemcu-tool terminal --run $6 $2
    else
      echo "\033[31mCompile error\033[0m"
    fi
  ;;

#--- command - COM: File compile, upload, run ---
  4)
    fpath=$3
    rmFile $fpath
    $luacCross -o $fpath -l $4 > $5
    if [ -f $fpath ]; then
      nodemcu-tool upload $2 $fpath
      nodemcu-tool run $2 $6
    else
      echo "\033[31mCompile error\033[0m"
    fi
  ;;

#--- command - COM: absolute LFS Build & upload ---
  5)
    fpath=$3
    rmFile $fpath
    if [ $luaVer = "5.1" ]; then
      $luacCross -o $fpath -f -m $lfs_size -a $lfs_mapped -l $4/*.lua > $5
      if [ -f $fpath ]; then
        esptool.py $2 write_flash $lfs_base $fpath
      else
        echo "\033[31mCompile error\033[0m"
      fi
    else
      echo "\033[33mNot implemented yet\033[0m"
    fi
  ;;

#--- command - FTP: LuaSrcDiet & upload active file ---
  6)
    fpath=$3
    rmFile $fpath
    luasrcdiet $2 -o $fpath > $5
    if [ -f $fpath ]; then
      curl -T $fpath --config $4 --ftp-pasv --disable-epsv --progress-bar
    else
      echo "\033[31mLuaSrcDiet error\033[0m"
    fi
  ;;

#--- command - Cross compiler ---
  7)
    fpath=$2
    rmFile $fpath
    $luacCross -o $fpath -l $3 > $4
  ;;

#--- command - COM: upload active file ---
  8)
    if [ $luaVer = "5.3" ]; then
      echo "\033[33mThe file is being uploaded without '--minify' option! See: (https://github.com/mathiasbynens/luamin/issues/76)\033[0m"
      nodemcu-tool upload $2 $3
    elif [ $luaVer = "5.1" ]; then
      nodemcu-tool upload --minify $2 $3
    else
      echo "\033[31mIncorrect Lua version: $luaVer\033[0m"
      exit 1
    fi
  ;;

#--- command - FTP: Luamin & upload active file ---
  9)
    fpath=$3
    rmFile $fpath
    luamin -f $2 > $3
    if [ -f $fpath ]; then
      curl -T $fpath --config $4 --ftp-pasv --disable-epsv --progress-bar
    else
      echo "\033[31mLuamin error\033[0m"
    fi
  ;;

  *)
    echo "\033[33mUnknown command\033[0m"
  ;;
esac
