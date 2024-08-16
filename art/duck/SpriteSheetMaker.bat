@rem move to folder with aseprite files you want merged and run it
@echo off 

set "aseprite=D:\Steam\steamapps\common\Aseprite\Aseprite.exe"

for %%f in (*.png) do (
	echo %%f
    if "%%~xf"==".png" call set "mystr=%%f%%mystr%%"
	echo %mystr%
)

"%aseprite%" --batch %mystr% --sheet output.png --data output.json --sheet-pack
pause