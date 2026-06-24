@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title libps1 - Server Optimizer

rem ############################################################################
rem  libps1 :: bin/server-optimizer.cmd
rem  Thin launcher -> scripts/Invoke-Optimizer.ps1.
rem  Profile is always Server.  Remaining args forwarded to the PowerShell
rem  script.  For other profiles, use optimizer.cmd or the .ps1 directly.
rem ############################################################################

rem === Configuration ===
set "PS_SCRIPT=%~dp0..\scripts\Invoke-Optimizer.ps1"
set "PROFILE_NAME=Server"
set "SKIP_FIRST=0"

rem === Help gate ===
if /i "%~1"=="help"    call :usage && exit /b 0
if /i "%~1"=="--help"  call :usage && exit /b 0
if /i "%~1"=="/help"   call :usage && exit /b 0
if /i "%~1"=="/h"      call :usage && exit /b 0
if /i "%~1"=="/?"      call :usage && exit /b 0

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
set "LOG=%LOCALAPPDATA%\libps1\logs\server-optimizer.log"
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
echo libps1 :: server-optimizer.cmd - Server Configuration Orchestrator
echo =================================================================
echo.
echo Runs a conservative Server configuration profile.  Applies registry
echo policies, disables telemetry, and configures system defaults without
echo debloating AppX packages or applying desktop UI tweaks (servers do
echo not ship most of it).
echo.
echo For domain controllers, use optimizer.cmd -Profile DC or run
echo Invoke-Optimizer.ps1 directly with no -Profile to auto-detect.
echo.
echo USAGE
echo   server-optimizer.cmd [options]
echo.
echo   options   Any additional Invoke-Optimizer.ps1 parameter:
echo            -WhatIf            Show what would be configured (dry run).
echo            -Verbose           Show detailed per-setting output.
echo            -StopOnError       Abort if any single step fails.
echo            -DryRun            Preview scripts without executing them.
echo            -ListOnly          Print the resolved script list and exit.
echo.
echo EXAMPLES
echo   server-optimizer.cmd                   Run Server profile
echo   server-optimizer.cmd -WhatIf            Detailed dry-run
echo   server-optimizer.cmd -DryRun            Preview which scripts would run
echo   server-optimizer.cmd help               Show this help text
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
set /p "CONFIRM=This will apply Server configuration profile. Press Y to continue or N to abort: "
if /i "%CONFIRM%"=="Y" exit /b 0
echo [WARN] Aborted by user.
exit /b 1

:run_optimizer
echo [INFO] Launching %PROFILE_NAME% optimization via %PS_EXE%
rem -NoProfile keeps the run deterministic (ignores user $PROFILE customisations).
rem -ExecutionPolicy Bypass avoids policy blocking an unsigned dev checkout;
rem CHANGE-NOTE: drop -ExecutionPolicy once scripts are signed and AllSigned is in use.
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Profile %PROFILE_NAME% %* >> "%LOG%" 2>&1
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
