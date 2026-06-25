@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title winkit - IR Collector

rem ############################################################################
rem  winkit :: bin/ir.cmd
rem  Thin launcher -> scripts/Invoke-InformationRetrieval.ps1.
rem  First positional arg is the profile name (Quick|Full), defaults to Quick.
rem  Remaining args forwarded verbatim to the PowerShell script.
rem ############################################################################

rem === Configuration ===
set "PS_SCRIPT=%~dp0..\scripts\Invoke-InformationRetrieval.ps1"
set "PROFILE_NAME=%~1"

rem === Help gate — print usage and exit before any checks ===
if /i "%PROFILE_NAME%"=="help"    call :usage && exit /b 0
if /i "%PROFILE_NAME%"=="--help"  call :usage && exit /b 0
if /i "%PROFILE_NAME%"=="/help"   call :usage && exit /b 0
if /i "%PROFILE_NAME%"=="/h"      call :usage && exit /b 0
if /i "%PROFILE_NAME%"=="/?"      call :usage && exit /b 0

rem === Profile resolution ===
set "SKIP_FIRST=0"
if "%PROFILE_NAME%"==""                  set "PROFILE_NAME=Quick"
if /i "%PROFILE_NAME%"=="Quick"          set "PROFILE_NAME=Quick" & set "SKIP_FIRST=1"
if /i "%PROFILE_NAME%"=="Full"           set "PROFILE_NAME=Full"  & set "SKIP_FIRST=1"
if "%PROFILE_NAME:~0,1%"=="-"            set "PROFILE_NAME=Quick"

rem Prefer PowerShell 7+ (pwsh) when present, fall back to Windows PowerShell.
set "PS_EXE=pwsh"
where pwsh >nul 2>&1 || set "PS_EXE=powershell"

rem === Main ===
call :init_log
call :show_banner
call :check_admin       || goto :fail
call :confirm           || goto :fail
call :check_script      || goto :fail
call :run_collector     || goto :fail

exit /b %RC%

rem === Functions ===

:init_log
if not exist "%LOCALAPPDATA%\winkit\logs" mkdir "%LOCALAPPDATA%\winkit\logs"
set "LOG=%LOCALAPPDATA%\winkit\logs\ir.log"
exit /b 0

:show_banner
rem Derive a real ESC byte (0x1B) for ANSI colours. forfiles can emit arbitrary
rem bytes via 0xHH escapes, which is the most reliable cmd-only method and avoids
rem the fragile prompt/pipe idioms.
for /f %%E in ('forfiles /p "%SystemRoot%" /m "explorer.exe" /c "cmd /c echo(0x1B" 2^>nul') do set "ESC=%%E"
set "ORANGE=%ESC%[38;5;208m"
set "GRAY=%ESC%[90m"
set "BOLD=%ESC%[1m"
set "RESET=%ESC%[0m"
echo.
echo %ORANGE% █████╗ ██████╗     ███╗   ██╗ ██████╗  ██████╗████████╗███████╗███╗   ███╗%RESET%
echo %ORANGE%██╔══██╗██╔══██╗    ████╗  ██║██╔═══██╗██╔════╝╚══██╔══╝██╔════╝████╗ ████║%RESET%
echo %ORANGE%███████║██║  ██║    ██╔██╗ ██║██║   ██║██║        ██║   █████╗  ██╔████╔██║%RESET%
echo %ORANGE%██╔══██║██║  ██║    ██║╚██╗██║██║   ██║██║        ██║   ██╔══╝  ██║╚██╔╝██║%RESET%
echo %ORANGE%██║  ██║██████╔╝    ██║ ╚████║╚██████╔╝╚██████╗   ██║   ███████╗██║ ╚═╝ ██║%RESET%
echo %ORANGE%╚═╝  ╚═╝╚═════╝     ╚═╝  ╚═══╝ ╚═════╝  ╚═════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝%RESET%
echo     %GRAY%winkit incident-response collector  ::  profile: %PROFILE_NAME%%RESET%
echo.
echo This script collects evidence only. It does not clean malware.
echo Run this from USB as Administrator while the PC is offline.
echo.
exit /b 0

:usage
echo.
echo winkit :: ir.cmd - Incident-Response Evidence Collector
echo ========================================================
echo.
echo Collects host information, Defender state, event logs, scheduled
echo tasks, registry persistence, processes, network state, services,
echo and user data from an offline Windows endpoint.
echo.
echo USAGE
echo   ir.cmd [profile] [options]
echo.
echo   profile   One of: Quick, Full.  Defaults to Quick if omitted.
echo            Quick  - Core triage: Defender, key event logs, host info,
echo                     scheduled tasks, registry Run keys, processes,
echo                     network state, services, users (~3-5 min).
echo            Full   - Quick + additional event logs, deep registry
echo                     exports, WMI persistence, ZIP archive (~10-15 min).
echo.
echo   options   Any additional Invoke-InformationRetrieval.ps1 parameter:
echo            -OutputPath D:\     Write the case folder to D:\ instead of
echo                                the current directory.
echo            -WhatIf            Show what would be collected (dry run).
echo            -Verbose           Show detailed step output.
echo.
echo EXAMPLES
echo   ir.cmd                     Run Quick triage in current directory
echo   ir.cmd Full                Run comprehensive collection
echo   ir.cmd Quick -OutputPath D:\  Quick triage, output to D:\
echo   ir.cmd help                Show this help text
echo.
echo REQUIREMENTS
echo   - Administrator privileges (run as Admin / elevate)
echo   - Run from USB while the target machine is offline
echo   - PowerShell 5.1+ (default) or pwsh 7+ (preferred, auto-detected)
echo.
echo OUTPUT
echo   Creates IR-COMPUTERNAME-TIMESTAMP\ folder with EVTX\, Text\,
echo   and Artifacts\ subdirectories.  The Full profile also creates
echo   a ZIP archive.
echo.
echo This tool collects evidence only.  It does NOT clean malware.
echo.
exit /b 0

:check_admin
net session >nul 2>&1 || (
    echo [ERROR] Administrator privileges required 1>&2
    exit /b 1
)
exit /b 0

:check_script
if not exist "%PS_SCRIPT%" (
    echo [ERROR] Could not find Invoke-InformationRetrieval.ps1 at "%PS_SCRIPT%" 1>&2
    exit /b 1
)
exit /b 0

:confirm
echo.
set /p "CONFIRM=This will start IR collection with profile '%PROFILE_NAME%'. Press Y to continue or N to abort: "
if /i "%CONFIRM%"=="Y" exit /b 0
echo [WARN] Aborted by user.
exit /b 1

:run_collector
echo [INFO] Launching %PROFILE_NAME% IR collection via %PS_EXE%
rem -NoProfile keeps the run deterministic (ignores user $PROFILE customisations).
rem -ExecutionPolicy Bypass avoids policy blocking an unsigned dev checkout;
rem CHANGE-NOTE: drop -ExecutionPolicy once scripts are signed and AllSigned is in use.
if "%SKIP_FIRST%"=="1" (
    "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Profile %PROFILE_NAME% %2 %3 %4 %5 %6 %7 %8 %9 >> "%LOG%" 2>&1
) else (
    "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Profile %PROFILE_NAME% %* >> "%LOG%" 2>&1
)
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" (
    call :fail
) else (
    call :success
)

if errorlevel 1 exit /b 1
exit /b 0

:success
echo [INFO] %PROFILE_NAME% IR collection completed successfully
exit /b 0

:fail
echo [ERROR] %PROFILE_NAME% IR collection failed with exit code %RC% 1>&2
exit /b 1
