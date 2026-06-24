@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title libps1 - Machine Optimizer

rem ############################################################################
rem  libps1 :: bin/optimizer.cmd
rem  Thin launcher -> scripts/Invoke-Optimizer.ps1.
rem  First positional arg is the profile name (Desktop|Server|DC|Minimal),
rem  defaults to Desktop.  Remaining args forwarded to the PowerShell script.
rem ############################################################################

rem === Configuration ===
set "PS_SCRIPT=%~dp0..\scripts\Invoke-Optimizer.ps1"
set "PROFILE_NAME=%~1"

rem === Help gate ===
if /i "%PROFILE_NAME%"=="help"    call :usage && exit /b 0
if /i "%PROFILE_NAME%"=="--help"  call :usage && exit /b 0
if /i "%PROFILE_NAME%"=="/help"   call :usage && exit /b 0
if /i "%PROFILE_NAME%"=="/h"      call :usage && exit /b 0
if /i "%PROFILE_NAME%"=="/?"      call :usage && exit /b 0

rem === Profile resolution ===
set "SKIP_FIRST=0"
if "%PROFILE_NAME%"==""                  set "PROFILE_NAME=Desktop"
if /i "%PROFILE_NAME%"=="Desktop"        set "PROFILE_NAME=Desktop" & set "SKIP_FIRST=1"
if /i "%PROFILE_NAME%"=="Server"         set "PROFILE_NAME=Server"  & set "SKIP_FIRST=1"
if /i "%PROFILE_NAME%"=="DC"             set "PROFILE_NAME=DC"      & set "SKIP_FIRST=1"
if /i "%PROFILE_NAME%"=="Minimal"        set "PROFILE_NAME=Minimal" & set "SKIP_FIRST=1"
if "%PROFILE_NAME:~0,1%"=="-"            set "PROFILE_NAME=Desktop"

rem Prefer PowerShell 7+ (pwsh) when present, fall back to Windows PowerShell.
set "PS_EXE=pwsh"
where pwsh >nul 2>&1 || set "PS_EXE=powershell"

rem === Main ===
call :init_log
call :show_banner
call :check_admin       || goto :fail
call :confirm           || goto :fail
call :check_script      || goto :fail
call :run_optimizer     || goto :fail

exit /b %RC%

rem === Functions ===

:init_log
if not exist "%LOCALAPPDATA%\libps1\logs" mkdir "%LOCALAPPDATA%\libps1\logs"
set "LOG=%LOCALAPPDATA%\libps1\logs\optimizer.log"
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
echo     %GRAY%libps1 machine configuration  ::  profile: %PROFILE_NAME%%RESET%
echo.
exit /b 0

:usage
echo.
echo libps1 :: optimizer.cmd - Windows Configuration Orchestrator
echo ===========================================================
echo.
echo Runs a curated set of configuration scripts in dependency order
echo according to a named profile.  Each script applies registry policies,
echo disables telemetry, removes bloatware, and tunes Windows behaviour.
echo.
echo USAGE
echo   optimizer.cmd [profile] [options]
echo.
echo   profile   One of: Desktop, Server, DC, Minimal.  Defaults to Desktop.
echo            Desktop - Full workstation hardening + UI debloat + privacy
echo            Server  - Conservative policy baseline, no UI/bloat removal
echo            DC      - Domain controller: minimal policy baseline only
echo            Minimal - Core telemetry + update policy only
echo.
echo   options   Any additional Invoke-Optimizer.ps1 parameter:
echo            -WhatIf            Show what would be configured (dry run).
echo            -Verbose           Show detailed per-setting output.
echo            -StopOnError       Abort if any single step fails.
echo            -DryRun            Preview scripts without executing them.
echo            -ListOnly          Print the resolved script list and exit.
echo.
echo EXAMPLES
echo   optimizer.cmd                   Run Desktop profile
echo   optimizer.cmd Server             Run Server profile
echo   optimizer.cmd Minimal -DryRun    Preview Minimal profile steps
echo   optimizer.cmd Desktop -WhatIf    Detailed dry-run of Desktop profile
echo   optimizer.cmd help               Show this help text
echo.
echo REQUIREMENTS
echo   - Administrator privileges (run as Admin / elevate)
echo   - PowerShell 5.1+ (default) or pwsh 7+ (preferred, auto-detected)
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
    echo [ERROR] Could not find Invoke-Optimizer.ps1 at "%PS_SCRIPT%" 1>&2
    exit /b 1
)
exit /b 0

:confirm
echo.
set /p "CONFIRM=This will apply configuration profile '%PROFILE_NAME%'. Press Y to continue or N to abort: "
if /i "%CONFIRM%"=="Y" exit /b 0
echo [WARN] Aborted by user.
exit /b 1

:run_optimizer
echo [INFO] Launching %PROFILE_NAME% optimization via %PS_EXE%
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
echo [INFO] %PROFILE_NAME% optimization completed successfully
exit /b 0

:fail
echo [ERROR] %PROFILE_NAME% optimization failed with exit code %RC% 1>&2
exit /b 1
