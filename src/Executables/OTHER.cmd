@echo off
set version=23.04
for /f "tokens=2 delims==" %%i in ('wmic os get BuildNumber /value ^| find "="') do set "build=%%i"
if %build% gtr 19045 ( set "w11=true" )

::WebThreatDefSvc
for /f %%i in ('reg query "HKLM\SYSTEM\ControlSet001\Services" /s /k "webthreatdefusersvc" /f 2^>nul ^| find /i "webthreatdefusersvc" ') do (
  reg add "%%i" /v "Start" /t REG_DWORD /d "4" /f >NUL 2>nul
)

PowerShell -NonInteractive -NoLogo -NoP -C "& {$cpu = Get-CimInstance Win32_Processor; $cpuName = $cpu.Name; if ($cpu.Manufacturer -eq 'GenuineIntel') { if ($cpuName.Substring(0, 2) -eq 'In') { Write-Host 'Detected Intel CPU older than 10th generation.' } else { $cpuGen = [int]($cpuName.Substring(0, 2)); if ($cpuGen -gt 11) { Write-Host 'Optimizing Revision''s Ultra powerplan for 12th generation or later Intel CPUs'; powercfg -changename 3ff9831b-6f80-4830-8178-736cd4229e7b 'Ultra Performance' 'Windows''s Ultimate Performance with optimized settings for newer Intel CPUs.'; powercfg -s 3ff9831b-6f80-4830-8178-736cd4229e7b; powercfg -setacvalueindex scheme_current sub_processor HETEROPOLICY 0; powercfg -setacvalueindex scheme_current sub_processor SCHEDPOLICY 2; powercfg /setactive scheme_current }}};}"

:: Config superfetch for HDDs
for /f %%i in ('PowerShell -NonInteractive -NoLogo -NoP -C "Get-PhysicalDisk | ForEach-Object { $physicalDisk = $_ ; $physicalDisk | Get-Disk | Get-Partition | Where-Object { $_.DriveLetter -eq 'C'} | Select-Object @{n='MediaType';e={$physicalDisk.MediaType}}}"') do (
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

:: Config SVC Split Threshold depending on RAM
for /f "tokens=2 delims==" %%a in ('wmic os get TotalVisibleMemorySize /format:value') do set "memTemp=%%a"
set /a "mem=%memTemp% + 1024000"
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%mem%" /f >NUL

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


:: Disable DMA remapping
:: https://docs.microsoft.com/en-us/windows-hardware/drivers/pci/enabling-dma-remapping-for-device-drivers
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "DmaRemappingCompatible" ^| find /i "Services\" ') do (
    reg add "%%a" /v "DmaRemappingCompatible" /t REG_DWORD /d "0" /f
)

:: Disable NetBios over tcp/ip
:: Works only when services are enabled
for /f "delims=" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s /f "NetbiosOptions" ^| findstr "HKEY"') do (
    reg add "%%a" /v "NetbiosOptions" /t REG_DWORD /d "2" /f
)

:: Enable MSI mode on USB, GPU, SATA controllers and network adapters
:: Deleting DevicePriority sets the priority to undefined
for %%a in (
    Win32_USBController,
    Win32_VideoController,
    Win32_NetworkAdapter,
    Win32_IDEController
) do (
    for /f %%i in ('wmic path %%a get PNPDeviceID ^| findstr /l "PCI\VEN_"') do (
        reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
        reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f
    )
)

:: If e.g. VMWare is used, set network adapter to normal priority as undefined on some virtual machines may break internet connection
wmic computersystem get manufacturer /format:value | findstr /i /c:VMWare && (
    for /f %%a in ('wmic path Win32_NetworkAdapter get PNPDeviceID ^| findstr /l "PCI\VEN_"') do (
        reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%a\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "2" /f
    )
)

:: Debloat 'Send To' context menu, hidden files do not show up in the 'Send To' context menu
attrib +h "%APPDATA%\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"
attrib +h "%APPDATA%\Microsoft\Windows\SendTo\Mail Recipient.MAPIMail"
attrib +h "%APPDATA%\Microsoft\Windows\SendTo\Documents.mydocs"
