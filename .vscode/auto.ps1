$lfs_size = 0x040000  #change if needed

switch ($args[0]) {
#--- command - FTP: build LFS & upload ---
    1 {
        $fpath = $args[1]
        $isFile = Test-Path $fpath
        if($isfile) {
            Remove-Item -Path $fpath
        }
        luac.cross.exe -o $args[1] -f -m $lfs_size -l $args[3] | Out-file $args[4]
        $isFile = Test-Path $fpath
        if($isfile) {
            curl.exe -T $args[1] --config $args[2] --ftp-pasv --disable-epsv --progress-bar  --list-only
            curl.exe --config $args[2] --ftp-pasv --disable-epsv -Q "LFS"  --list-only
        }
        else {
            Write-Warning("Compilation error")
        }
        break
    }
#--- command - COM: LFS build, upload & flashreload ---
    2 {
        $var =  "node.LFS.reload('lfs.img')"
        $fpath = $args[2]
        $isFile = Test-Path $fpath
        if($isfile) {
            Remove-Item -Path $fpath
        }
        luac.cross.exe -o $args[2] -f -m $lfs_size -l $args[3] | Out-file $args[4]
        $isFile = Test-Path $fpath
        if($isfile) {
            nodemcu-tool upload  $args[1] $args[2]
            $var | nodemcu-tool terminal $args[1]
        }
        else {
            Write-Warning("Compilation error")
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
        luac.cross.exe -o $args[2] -l $args[3] | Out-file $args[4]
        $isFile = Test-Path $fpath
        if($isfile) {
            nodemcu-tool upload  $args[1] $args[2]
            nodemcu-tool terminal --run $args[5] $args[1]
        }
        else {
            Write-Warning("Compilation error")
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
        luac.cross.exe -o $args[2] -l $args[3] | Out-file $args[4]
        $isFile = Test-Path $fpath
        if($isfile) {
        nodemcu-tool upload  $args[1] $args[2]
        nodemcu-tool run $args[1] $args[5]
        }
        else {
            Write-Warning("Compilation error")
        }
        break
    }
#--- command - COM: absolute LFS Build & upload ---
    5 {
        $fpath = $args[2]
        $lfs_base = 0x7e000       #change if needed
        $lfs_mapped = 0x4027e000  #change if needed

        $isFile = Test-Path $fpath
        if($isfile) {
            Remove-Item -Path $fpath
        }
        luac.cross.exe -o $args[2] -f -m $lfs_size -a $lfs_mapped -l $args[3] | Out-file $args[4]
        $isFile = Test-Path $fpath
        if($isfile) {
            esptool.py $args[1] write_flash $lfs_base $fpath
        }
        else {
            Write-Warning("Compilation error")
        }
        break
    }
#--- command - FTP: LuaSrcDiet & upload ---
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
}
exit
