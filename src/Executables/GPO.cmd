@echo off
setlocal EnableDelayedExpansion

for /f "tokens=2 delims==" %%i in ('wmic os get BuildNumber /value ^| find "="') do set "build=%%i"
if %build% gtr 19045 (
	set "backupdir=C:\Temp\GPO\win11"
) else (
	set "backupdir=C:\Temp\GPO\win10"
)

echo %backupdir%
cmd /c "LGPO.exe /g %backupdir%"
