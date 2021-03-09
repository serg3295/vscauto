# vscauto

Visual Studio Code scripts and commands for compile, upload and run Lua files on ESP8266, ESP-32.

Works on Windows only.

# Install

install **[nodemcu-tool](https://github.com/AndiDittrich/NodeMCU-Tool)**

install **[LuaSrcDiet](https://github.com/jirutka/luasrcdiet#using-luarocks)**

Enable PowerShell scripts execution

```
Run (admin) Windows PowerShell -> Set-ExecutionPolicy Unrestricted -> "A"
```

Create folders

```
.output -- empty
.vscode -- files from this repository
your files in workspace
```

In order to execute the "COM: LFS build, upload & flashreload" command, you need to write the file **lfsreload.lua** to spiffs.

# Settings

File **ftp.txt**  - device IP address, credential information for FTP server

File **http.txt** - device IP address

File **auto.ps1** - $lfs_size, $lfs_base, $lfs_mapped

*$lfs_base* and *$lfs_mapped* uses only for an LFS absolute image (luac.cross with -a \<baseAddr\> option.)
