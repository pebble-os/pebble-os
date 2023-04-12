@echo off
set version=23.04
for /f "tokens=2 delims==" %%i in ('wmic os get BuildNumber /value ^| find "="') do set "build=%%i"
if %build% gtr 19045 ( set "w11=true" )

::WebThreatDefSvc
for /f %%i in ('reg query "HKLM\SYSTEM\ControlSet001\Services" /s /k "webthreatdefusersvc" /f 2^>nul ^| find /i "webthreatdefusersvc" ') do (
  reg add "%%i" /v "Start" /t REG_DWORD /d "4" /f >NUL 2>nul
)

PowerShell -NonInteractive -NoLogo -NoProfile -Command "& {$cpu = Get-CimInstance Win32_Processor; $cpuName = $cpu.Name; if ($cpu.Manufacturer -eq 'GenuineIntel') { if ($cpuName.Substring(0, 2) -eq 'In') { Write-Host 'Detected Intel CPU older than 10th generation.' } else { $cpuGen = [int]($cpuName.Substring(0, 2)); if ($cpuGen -gt 11) { Write-Host 'Optimizing Revision''s Ultra powerplan for 12th generation or later Intel CPUs'; powercfg -changename 3ff9831b-6f80-4830-8178-736cd4229e7b 'Ultra Performance' 'Windows''s Ultimate Performance with optimized settings for newer Intel CPUs.'; powercfg -s 3ff9831b-6f80-4830-8178-736cd4229e7b; powercfg -setacvalueindex scheme_current sub_processor HETEROPOLICY 0; powercfg -setacvalueindex scheme_current sub_processor SCHEDPOLICY 2; powercfg /setactive scheme_current }}};}"

echo Configuring Superfetch for HDD...

for /f %%i in ('PowerShell -NonInteractive -NoLogo -NoProfile -Command "get-physicaldisk | get-disk | get-partition | Where-Object DriveLetter -EQ C | Select-Object DriveLetter, @{n='MediaType';e={$(get-physicaldisk).MediaType}} | Select-Object MediaType -ExpandProperty MediaType"') do (
  set "hardDrive=%%i"
)
if "%hardDrive%"=="HDD" (
  reg add "HKLM\SYSTEM\ControlSet001\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "LowerFilters" /t REG_MULTI_SZ /d "fvevol\0iorate\0rdyboost" /f >NUL 2>nul
  reg add "HKLM\SYSTEM\ControlSet001\Services\rdyboost" /v "Start" /t REG_DWORD /d "0" /f >NUL 2>nul
  reg add "HKLM\SYSTEM\ControlSet001\Services\SysMain" /v "Start" /t REG_DWORD /d "2" /f >NUL 2>nul
  reg add "HKLM\SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "3" /f >NUL 2>nul
  reg add "HKLM\SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d "3" /f >NUL 2>nul
  reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\EMDMgmt" /v "GroupPolicyDisallowCaches" /f >NUL 2>nul
  reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\EMDMgmt" /v "AllowNewCachesByDefault" /f >NUL 2>nul

)

echo Configuring memory...

for /f "tokens=2 delims==" %%a in ('wmic os get TotalVisibleMemorySize /format:value') do set "memTemp=%%a"
set /a "mem=%memTemp% + 1024000"
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%mem%" /f >NUL
reg add "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" /v "AllowInputPersonalization" /t REG_DWORD /d "0" /f >NUL

for /f "usebackq tokens=2 delims=\" %%a in (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
  REM If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs do not have this key.
  reg query "HKEY_USERS\%%a" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" > nul 2>&1
    if not errorlevel 1 (
      if %mem% lss 9000000 (
        reg add "HKU\%%a\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d "0" /f >NUL
        reg add "HKU\%%a\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f >NUL 2>nul
      )
    )
  )
