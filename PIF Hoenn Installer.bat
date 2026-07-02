@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
title Infinite Fusion Hoenn - Installer / Updater
color 0A

:: ============================================================
::  CONFIG
:: ============================================================
set "REPO_URL=https://github.com/infinitefusion/infinitefusion-hoenn-public.git"
set "REPO_RAW=https://raw.githubusercontent.com/infinitefusion/infinitefusion-hoenn-public/releases"
set "BRANCH=releases"
set "MGIT=.\REQUIRED_BY_INSTALLER_UPDATER\cmd\git.exe"
set "VER_FILE=Data\Scripts\001_Settings.rb"
set "REMOTE_VER_FILE=Data/Scripts/001_Settings.rb"

:: ============================================================
::  Read current local version
:: ============================================================
set "HOENN_VER=unknown"
if exist "%VER_FILE%" (
    for /f "usebackq tokens=*" %%A in (
        `powershell -NoProfile -Command "$l=(Select-String 'HOENN_VERSION_NUMBER' '%VER_FILE%').Line; if($l){($l -replace '.*\x22(.+)\x22.*','$1')}else{'unknown'}"`
    ) do set "HOENN_VER=%%A"
)

:: ============================================================
::  Fetch remote version for preview
:: ============================================================
set "LATEST_VER=unknown"
for /f "usebackq tokens=*" %%A in (
    `powershell -NoProfile -Command "try{$r=(Invoke-WebRequest -Uri '%REPO_RAW%/%REMOTE_VER_FILE%' -UseBasicParsing -TimeoutSec 5).Content; $l=($r -split '\n' | Select-String 'HOENN_VERSION_NUMBER'); if($l){($l.Line -replace '.*\x22(.+)\x22.*','$1')}else{'unknown'}}catch{'unknown'}"`
) do set "LATEST_VER=%%A"

:: ============================================================
::  Header
:: ============================================================
echo.
echo  ==========================================================
echo   Infinite Fusion Hoenn  ^|  Installer ^& Updater
echo  ==========================================================
echo   Current Version  : !HOENN_VER!
echo   Latest Version   : !LATEST_VER!
echo  ----------------------------------------------------------
echo.
echo   This downloads the latest base Hoenn release from GitHub
echo   and applies it to this folder.
echo.
echo   Your saves will NOT be affected by this update.
echo.
echo   SOURCE: github.com/infinitefusion/infinitefusion-hoenn-public
echo  ==========================================================
echo.
set /p "go=  Press ENTER to update, or close this window to cancel: "

echo.
echo  Preparing update...
echo.

:: ============================================================
::  Sanity checks
:: ============================================================
if not exist "%MGIT%" (
    color 0C
    echo.
    echo  ==========================================================
    echo   ERROR: Bundled git.exe was not found.
    echo  ----------------------------------------------------------
    echo   Expected path:
    echo   %MGIT%
    echo  ----------------------------------------------------------
    echo   Your installer files may be incomplete.
    echo  ==========================================================
    echo.
    pause
    exit /b 1
)

:: Remove stale locks if present
if exist ".git\shallow.lock" (
    echo  [INFO] Removing stale git shallow lock...
    erase /f /q ".git\shallow.lock"
)
if exist ".git\index.lock" (
    echo  [INFO] Removing stale git index lock...
    erase /f /q ".git\index.lock"
)

:: ============================================================
::  Download and apply update
:: ============================================================
echo  [1/3] Initializing repository...
%MGIT% init . >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    color 0C
    echo  ==========================================================
    echo   ERROR: Failed to initialize the updater repository.
    echo  ----------------------------------------------------------
    echo   Close other Git/updater windows and try again.
    echo  ==========================================================
    echo.
    pause
    exit /b 1
)

echo  [2/3] Fetching latest release from GitHub...
%MGIT% remote remove origin >nul 2>&1
%MGIT% remote add origin "%REPO_URL%" >nul 2>&1
%MGIT% fetch --depth=1 --force origin %BRANCH%
if %errorlevel% neq 0 (
    echo.
    color 0C
    echo  ==========================================================
    echo   ERROR: Failed to download update.
    echo  ----------------------------------------------------------
    echo   Possible causes:
    echo   - No internet connection
    echo   - GitHub is temporarily unavailable
    echo   - Another Git process is locking files
    echo  ----------------------------------------------------------
    echo   Screenshot this window for further help.
    echo  ==========================================================
    echo.
    pause
    exit /b 1
)

echo  [3/3] Applying update...
%MGIT% reset --hard origin/%BRANCH%
if %errorlevel% neq 0 (
    echo.
    color 0C
    echo  ==========================================================
    echo   ERROR: Failed to apply update.
    echo  ----------------------------------------------------------
    echo   Close the game and any Git/updater windows, then try again.
    echo  ==========================================================
    echo.
    pause
    exit /b 1
)

:: ============================================================
::  Re-read version after update
:: ============================================================
set "NEW_HOENN_VER=unknown"
if exist "%VER_FILE%" (
    for /f "usebackq tokens=*" %%A in (
        `powershell -NoProfile -Command "$l=(Select-String 'HOENN_VERSION_NUMBER' '%VER_FILE%').Line; if($l){($l -replace '.*\x22(.+)\x22.*','$1')}else{'unknown'}"`
    ) do set "NEW_HOENN_VER=%%A"
)

:: ============================================================
::  Done
:: ============================================================
echo.
echo  ==========================================================
echo   Update Complete!
echo  ----------------------------------------------------------
echo   Previous Version  : !HOENN_VER!
echo   Installed Version : !NEW_HOENN_VER!
echo  ==========================================================
echo.
pause
