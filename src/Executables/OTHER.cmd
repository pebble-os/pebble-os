@echo off
setlocal EnableDelayedExpansion

:: Config SVC Split Threshold depending on RAM
for /f "tokens=2 delims==" %%a in ('wmic os get TotalVisibleMemorySize /format:value') do set "memTemp=%%a"
set /a "mem=%memTemp% + 1024000"
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%mem%" /f >NUL

:: Disable NetBios over tcp/ip
:: Works only when services are enabled
for /f "delims=" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s /f "NetbiosOptions" ^| findstr "HKEY"') do (
    reg add "%%a" /v "NetbiosOptions" /t REG_DWORD /d "2" /f
)

:: MSI Mode

:: Enable MSI mode on USB, GPU, Audio, SATA controllers and network adapters
:: Deleting DevicePriority sets the priority to undefined
for %%a in (
    Win32_NetworkAdapter,
    Win32_PnPEntity,
    Win32_SoundDevice,
    Win32_USBController,
    Win32_VideoController,
) do (
    if "%%a" == "Win32_PnPEntity" (
        for /f "tokens=*" %%b in ('PowerShell -NoP -C "Get-WmiObject -Class Win32_PnPEntity | Where-Object {$_.PNPClass -eq 'SCSIAdapter'} | Where-Object { $_.PNPDeviceID -like 'PCI\VEN_*' } | Select-Object -ExpandProperty DeviceID"') do (
            reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%b\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
            reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%b\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f
        )
    ) else (
        for /f %%b in ('wmic path %%a get PNPDeviceID ^| findstr /l "PCI\VEN_"') do (
            reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%b\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f
            reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%b\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f
        )
    )
)

:: Debloat 'Send To' context menu, hidden files do not show up in the 'Send To' context menu
attrib +h "%APPDATA%\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"
attrib +h "%APPDATA%\Microsoft\Windows\SendTo\Mail Recipient.MAPIMail"
attrib +h "%APPDATA%\Microsoft\Windows\SendTo\Documents.mydocs"

:: Prevents mobsync from running on startup
ren "!windir!\System32\mobsync.exe" mobsync.old
ren "!windir!\SysWOW64\mobsync.exe" mobsync.old
