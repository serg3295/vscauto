#
# Keep the Lua.version = $null for automatically getting value from
# 'sumneko Lua Language server' setting. Set $luaVer to "5.1" or "5.3"
# if 'sumneko Lua Language server' VSCode extension is not installed.
#
$luaVer   = $null    # = "5.1" or = "5.3"
$lfs_size = 0x040000
$lfs_base = 0x084000

$lfs_mapped = 0x40200000 + $lfs_base #an LFS region at ESP address 0x402'base'

# Trying to get the 'Lua.runtime.version' value from an sumneko.Lua extension
if (-not $luaVer) {
  $fpath = ".\.vscode\settings.json"
  if (Test-Path $fpath) {
    $luaVer = Select-String -Path $fpath -Pattern "Lua.runtime.version" | Where-Object {$_ -match "5\.\d"} | ForEach-Object {$Matches[0]}
  }
}
if (-not $luaVer) {
  Write-Warning("The 'Lua.runtime.version' setting from 'sumneko Lua language server' extension was not found! Set Lua version manually in this script.")
  exit 1
}

if ($luaVer -eq "5.3") {
    $luacCross = "c:/Program` Files` `(x86`)/Lua/5.3/luac.cross.exe"
} elseif ($luaVer -eq "5.1") {
    $luacCross = "c:/Program` Files` `(x86`)/Lua/5.1/luac.cross.exe"
} else {
    Write-Warning("Incorrect Lua version: $luaVer")
    exit 1
}

switch ($args[0]) {
#--- command - FTP: build LFS & upload ---
  1 {
    $fpath = $args[1]
    if (Test-Path $fpath) {
      Remove-Item -Path $fpath
    }
    & $luacCross -o $fpath -f -m $lfs_size -l $args[3] | Out-file $args[4]
    if (Test-Path $fpath) {
      curl.exe -T $fpath --config $args[2] --ftp-pasv --disable-epsv --progress-bar  --list-only
      curl.exe --config $args[2] --ftp-pasv --disable-epsv -Q "LFS"  --list-only
    } else {
      Write-Warning("Compile error")
    }
    break
  }

#--- command - COM: LFS build, upload & flashreload ---
  2 {
    $fpath = $args[2]
    if (Test-Path $fpath) {
      Remove-Item -Path $fpath
    }
    & $luacCross -o $fpath -f -m $lfs_size -l $args[3] | Out-file $args[4]
    if (Test-Path $fpath) {
      nodemcu-tool upload  $args[1] $fpath
      nodemcu-tool $args[1] terminal --run "lfsreload.lua"
    } else {
      Write-Warning("Compile error")
    }
    break
  }

#--- command - COM: File compile, upload, run in terminal ---
  3 {
    $fpath = $args[2]
    if (Test-Path $fpath) {
      Remove-Item -Path $fpath
    }
    & $luacCross -o $fpath -l $args[3] | Out-file $args[4]
    if (Test-Path $fpath) {
      nodemcu-tool upload  $args[1] $fpath
      nodemcu-tool terminal --run $args[5] $args[1]
    } else {
      Write-Warning("Compile error")
    }
    break
  }

#--- command - COM: File compile, upload, run ---
  4 {
    $fpath = $args[2]
    if (Test-Path $fpath) {
      Remove-Item -Path $fpath
    }
    & $luacCross -o $fpath -l $args[3] | Out-file $args[4]
    if (Test-Path $fpath) {
      nodemcu-tool upload  $args[1] $fpath
      nodemcu-tool run $args[1] $args[5]
    } else {
      Write-Warning("Compile error")
    }
    break
  }

#--- command - COM: absolute LFS Build & upload ---
  5 {
    $fpath = $args[2]
    if (Test-Path $fpath) {
      Remove-Item -Path $fpath
    }

    if ($luaVer -eq "5.1") {
      & $luacCross -o $fpath -f -m $lfs_size -a $lfs_mapped -l $args[3] | Out-file $args[4]
      if (Test-Path $fpath) {
        esptool.py $args[1] write_flash $lfs_base $fpath
      } else {
        Write-Warning("Compile error")
      }
    } else {
      Write-Warning("Not implemented yet")
    }
    break
  }

#--- command - FTP: LuaSrcDiet & upload active file ---
  6 {
    $fpath = $args[2]
    if (Test-Path $fpath) {
      Remove-Item -Path $fpath
    }
    luaSrcDiet $args[1] -o $fpath | Out-file $args[4]
    if (Test-Path $fpath) {
      curl.exe -T $fpath --config $args[3] --ftp-pasv --disable-epsv --progress-bar
    } else {
      Write-Warning("LuaSrcDiet error")
    }
    break
  }

#--- command - Cross compiler ---
  7 {
    $fpath = $args[1]
    if (Test-Path $fpath) {Remove-Item -Path $fpath}
    & $luacCross -o $fpath -l $args[2] | Out-file $args[3]
    break
  }

  #--- command - COM: upload active file ---
  8 {
    if ($luaVer -eq "5.3") {
      Write-Warning("The file is being uploaded without the `--minify` option! See: (https://github.com/mathiasbynens/luamin/issues/76)")
      nodemcu-tool upload $args[1] $args[2]
    } elseif ($luaVer -eq "5.1") {
      nodemcu-tool upload --minify $args[1] $args[2]
    } else {
      Write-Warning("Incorrect Lua version: $luaVer")
      exit 1
    }
    break
  }

#--- command - FTP: Luamin & upload active file ---
9 {
  $fpath = $args[2]
  if (Test-Path $fpath) {
    Remove-Item -Path $fpath
  }
  luamin -f $args[1] | Out-file $args[2]
  if (Test-Path $fpath) {
    curl.exe -T $fpath --config $args[3] --ftp-pasv --disable-epsv --progress-bar
  } else {
    Write-Warning("Luamin error")
  }
  break
}

}
exit
