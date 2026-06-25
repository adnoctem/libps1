@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title winkit - Bootstrap Installer

rem ############################################################################
rem  winkit :: bin/bootstrap.cmd
rem  Thin launcher -> scripts/Invoke-Bootstrap.ps1.
rem  Installs winget, PowerShell 7, VC++ redistributables, registers bin\ on
rem  system PATH.  Uses Windows PowerShell deliberately; pwsh may not exist yet.
rem ############################################################################

rem === Configuration ===
set "PS_SCRIPT=%~dp0..\scripts\Invoke-Bootstrap.ps1"

rem === Help gate ===
if /i "%~1"=="help"    call :usage && exit /b 0
if /i "%~1"=="--help"  call :usage && exit /b 0
if /i "%~1"=="/help"   call :usage && exit /b 0
if /i "%~1"=="/h"      call :usage && exit /b 0
if /i "%~1"=="/?"      call :usage && exit /b 0

rem Bootstrap intentionally uses Windows PowerShell, NOT pwsh, because
rem PowerShell 7 is one of the things bootstrap installs.
set "PS_EXE=powershell"

rem === Main ===
call :init_log
call :show_banner
call :check_admin       || goto :fail
call :confirm           || goto :fail
call :check_script      || goto :fail
call :run_bootstrap     || goto :fail

exit /b %RC%

rem === Functions ===

:init_log
if not exist "%LOCALAPPDATA%\winkit\logs" mkdir "%LOCALAPPDATA%\winkit\logs"
set "LOG=%LOCALAPPDATA%\winkit\logs\bootstrap.log"
exit /b 0

:show_banner
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
echo     %GRAY%winkit machine configuration  ::  first-run bootstrap%RESET%
echo.
exit /b 0

:usage
echo.
echo winkit :: bootstrap.cmd - First-Run Machine Bootstrap
echo =====================================================
echo.
echo Installs essential prerequisites on a fresh Windows machine:
echo   - winget (Windows Package Manager)
echo   - PowerShell 7+ (pwsh)
echo   - VC++ redistributables (14.0 by default)
echo   - Registers bin\ on the system PATH
echo.
echo Intended as the first command run on a newly imaged machine.
echo Run this once before using optimizer, server-optimizer, or ir.cmd.
echo.
echo USAGE
echo   bootstrap.cmd [options]
echo.
echo   options   Any additional Invoke-Bootstrap.ps1 parameter:
echo            -VCRedistVersions 14.0,12.0   Install multiple VC++ runtimes.
echo            -SkipPath                     Don't modify the system PATH.
echo            -WhatIf                       Show what would be installed.
echo            -Verbose                      Show detailed step output.
echo            -DryRun                       Preview steps without executing.
echo.
echo EXAMPLES
echo   bootstrap.cmd                                    Full bootstrap, default runtimes
echo   bootstrap.cmd -VCRedistVersions 14.0,12.0        Install 14.0 and 12.0
echo   bootstrap.cmd -SkipPath                          Skip PATH registration
echo   bootstrap.cmd -DryRun                            Preview what would be installed
echo   bootstrap.cmd help                               Show this help text
echo.
echo REQUIREMENTS
echo   - Administrator privileges (run as Admin / elevate)
echo   - PowerShell 5.1+ (Windows PowerShell, always present)
echo   - Internet access to download packages
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
    echo [ERROR] Could not find Invoke-Bootstrap.ps1 at "%PS_SCRIPT%" 1>&2
    exit /b 1
)
exit /b 0

:confirm
echo.
set /p "CONFIRM=This will bootstrap the machine (install winget, PowerShell 7, VC++ 14.0). Press Y to continue or N to abort: "
if /i "%CONFIRM%"=="Y" exit /b 0
echo [WARN] Aborted by user.
exit /b 1

:run_bootstrap
echo [INFO] Launching bootstrap via %PS_EXE%
rem -NoProfile keeps the run deterministic (ignores user $PROFILE customisations).
rem -ExecutionPolicy Bypass avoids policy blocking an unsigned dev checkout;
rem CHANGE-NOTE: drop -ExecutionPolicy once scripts are signed and AllSigned is in use.
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %* >> "%LOG%" 2>&1
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
echo [INFO] Bootstrap completed successfully
echo [INFO] Open a new terminal for PATH changes to take effect.
exit /b 0

:fail
echo [ERROR] Bootstrap failed with exit code %RC% 1>&2
exit /b 1
