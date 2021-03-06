# ======== settings ========
$luaVer   = "5.3"     # "5.1" or "5.3"
$lfs_size = 0x040000
$lfs_base = 0x084000
#===========================

$lfs_mapped = 0x40284000 #0x40200000 + $lfs_base #an LFS region at ESP address 0x402'base'

if ($luaVer -eq "5.3") {
  $luacCross = "c:/Program` Files` `(x86`)/Lua/5.3/luac.cross.exe"
}
elseif ($luaVer -eq "5.1") {
  $luacCross = "luac.cross.exe"
  }
else {
  Write-Warning("Incorrect Lua version: $luaVer")
  break
}

switch ($args[0]) {
#--- command - FTP: build LFS & upload ---
    1 {
        $fpath = $args[1]
        $isFile = Test-Path $fpath
        if($isfile) {
            Remove-Item -Path $fpath
        }
        & $luacCross -o $args[1] -f -m $lfs_size -l $args[3] | Out-file $args[4]
        $isFile = Test-Path $fpath
        if($isfile) {
            curl.exe -T $args[1] --config $args[2] --ftp-pasv --disable-epsv --progress-bar  --list-only
            curl.exe --config $args[2] --ftp-pasv --disable-epsv -Q "LFS"  --list-only
        }
        else {
            Write-Warning("Compile error")
        }
        break
    }
#--- command - COM: LFS build, upload & flashreload ---
    2 {
        $fpath = $args[2]
        $isFile = Test-Path $fpath
        if($isfile) {
            Remove-Item -Path $fpath
        }
        & $luacCross -o $args[2] -f -m $lfs_size -l $args[3] | Out-file $args[4]
        $isFile = Test-Path $fpath
        if($isfile) {
            nodemcu-tool upload  $args[1] $args[2]
            nodemcu-tool $args[1] terminal --run "lfsreload.lua"
        }
        else {
            Write-Warning("Compile error")
        }
       break
    }
#--- command - COM: File compile, upload, run in terminal ---
    3 {
        $fpath = $args[2]
        $isFile = Test-Path $fpath
        if($isfile) {
            Remove-Item -Path $fpath
        }
        & $luacCross -o $args[2] -l $args[3] | Out-file $args[4]
        $isFile = Test-Path $fpath
        if($isfile) {
            nodemcu-tool upload  $args[1] $args[2]
            nodemcu-tool terminal --run $args[5] $args[1]
        }
        else {
            Write-Warning("Compile error")
        }
        break
    }
#--- command - COM: File compile, upload, run ---
    4 {
        $fpath = $args[2]
        $isFile = Test-Path $fpath
        if($isfile) {
            Remove-Item -Path $fpath
        }
        & $luacCross -o $args[2] -l $args[3] | Out-file $args[4]
        $isFile = Test-Path $fpath
        if($isfile) {
        nodemcu-tool upload  $args[1] $args[2]
        nodemcu-tool run $args[1] $args[5]
        }
        else {
            Write-Warning("Compile error")
        }
        break
    }
#--- command - COM: absolute LFS Build & upload ---
    5 {
        $fpath = $args[2]

        $isFile = Test-Path $fpath
        if($isfile) {
            Remove-Item -Path $fpath
        }

        if ($luaVer -eq "5.1") {
          & $luacCross -o $args[2] -f -m $lfs_size -a $lfs_mapped -l $args[3] | Out-file $args[4]
          $isFile = Test-Path $fpath
          if($isfile) {
            esptool.py $args[1] write_flash $lfs_base $fpath
          }
          else {
            Write-Warning("Compile error")
          }
        }
        else {
        #  -o name  output to file 'name' (default is "luac.cross.out")
        #  -e name  execute a lua source file
        #  -f       output a flash image file
        #  -F name  load a flash image file
        #  -a addr  generate an absolute, rather than position independent flash image file
        #           (use with -F LFSimage -o absLFSimage to convert an image to absolute format)
        # luac.cross.exe: '-a' also requires '-o' and '-f' options without lua source files
        # luac.cross -o johny.img -a 0x4029C000 mylib.lc mysub1.lua
        $absImg = "./.output/abslfs.img"
          & $luacCross -o $args[2] -f -l $args[3] | Out-file $args[4]
          $isFile = Test-Path $fpath
          if($isfile) {
            Write-Host("$isFile")
          #  & $luacCross -o $args[2] -a $lfs_mapped -F $args[2] | Out-file $args[4]
            & $luacCross -o $absImg -F $args[2] -a $lfs_mapped | Out-file $args[4]
            esptool.py $args[1] write_flash $lfs_base $fpath
          }
          else {
            Write-Warning("Compile error")
          }
        }
        break
    }

#--- command - FTP: LuaSrcDiet & upload active file ---
    6 {
        $fpath = $args[2]
        $isFile = Test-Path $fpath
        if($isfile) {
            Remove-Item -Path $fpath
        }
        luaSrcDiet $args[1] -o $args[2] | Out-file $args[4]
        $isFile = Test-Path $fpath
        if($isfile) {
          curl.exe -T $args[2] --config $args[3] --ftp-pasv --disable-epsv --progress-bar
        }
        else {
            Write-Warning("LuaSrcDiet error")
        }
        break
    }
#--- command - Cross compiler ---
    7 {
      $fpath = $args[1]
      $isFile = Test-Path $fpath
      if($isfile) {
          Remove-Item -Path $fpath
      }
      & $luacCross -o $args[1] -l $args[2] | Out-file $args[3]
      break
    }
}
exit
