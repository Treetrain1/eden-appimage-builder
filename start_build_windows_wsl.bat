@echo off
:: Title: Eden AppImage Build Windows Script
:: Description: Builds and runs the Arch Linux docker container to create an Eden AppImage.

:: Check if Docker is installed
echo Checking for Docker installation...
docker --version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo ==================================================================
    echo   Docker is not installed on your system.
    echo   Please install Docker from the official Docker website: 
    echo   https://docs.docker.com/desktop/setup/install/windows-install/
    echo ==================================================================
    echo.
    pause
    exit /b 1
)

:: Check if Docker is running
docker info >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo =====================================================================
    echo   Docker is not running. Please start Docker Desktop and try again.
    echo =====================================================================
    echo.
    pause
    exit /b
)

:: Ask user for version
echo ========================================================
echo   Choose the version to build:
echo   1. [Default] Latest master branch (nightly build)
echo   2. Eden Canary Refresh Version 0.5
echo   3. Eden Canary Refresh Version 0.4
echo   4. Specific version (Tag, Branch name or Commit Hash)
echo ========================================================
set /p VERSION_CHOICE="Enter choice ([1]/2/3/4): "
if "%VERSION_CHOICE%"=="1" (
    set EDEN_VERSION=master
) else if "%VERSION_CHOICE%"=="2" (
    set EDEN_VERSION=v0.5-canary-refresh
) else if "%VERSION_CHOICE%"=="3" (
    set EDEN_VERSION=v0.4-canary-refresh
) else if "%VERSION_CHOICE%"=="4" (
    set /p EDEN_VERSION="Enter the version (Tag, Branch or Commit Hash): "
) else (
    echo Defaulting to latest master branch.
    set EDEN_VERSION=master
)

:: Ask user for build mode
echo ========================================================
echo   Choose the build mode:
echo   1. [Default] SteamDeck optimizations
echo   2. Release mode
echo   3. Compatibility mode (for older architectures)
echo   4. Debug mode
echo ========================================================
set /p BUILD_MODE_CHOICE="Enter choice ([1]/2/3/4): "
if "%BUILD_MODE_CHOICE%"=="1" (
    set EDEN_BUILD_MODE=steamdeck
    echo Defaulting to SteamDeck optimizations.
) else if "%BUILD_MODE_CHOICE%"=="2" (
    set EDEN_BUILD_MODE=release
) else if "%BUILD_MODE_CHOICE%"=="3" (
    set EDEN_BUILD_MODE=compatibility
) else if "%BUILD_MODE_CHOICE%"=="4" (
    set EDEN_BUILD_MODE=debug
) else (
    echo Defaulting to SteamDeck optimizations.
    set EDEN_BUILD_MODE=steamdeck
)

:: Ask user if they want to cache the Git repository for subsequent builds
echo ========================================================
echo   Do you want to cache the Git repository for 
echo   subsequent builds? (This may speed up builds but 
echo   will consume around 1 GB of disk space.)
echo   1. Yes
echo   2. [Default] No
echo ========================================================
set /p CACHE_REPO="Enter choice (1/[2]): "
if "%CACHE_REPO%"=="1" (
    set USE_CACHE=true
) else (
    echo Defaulting to No.
    set USE_CACHE=false
)

:: Ask user if they want to output Linux binaries
echo ========================================================
echo   Do you want to output Linux binaries?
echo   1. Yes
echo   2. [Default] No
echo ========================================================
set /p OUTPUT_BINARIES="Enter choice (1/[2]): "
if "%OUTPUT_BINARIES%"=="1" (
    set OUTPUT_LINUX_BINARIES=true
) else (
    echo Defaulting to No.
    set OUTPUT_LINUX_BINARIES=false
)

:: Build the new image
docker build -t eden-builder .

:: Build the container with the selected options
docker run --rm -e EDEN_VERSION=%EDEN_VERSION% -e EDEN_BUILD_MODE=%EDEN_BUILD_MODE% -e OUTPUT_LINUX_BINARIES=%OUTPUT_LINUX_BINARIES% -e USE_CACHE=%USE_CACHE% -v %CD%:/output eden-builder

:: Ask the user if they want to delete the Docker image to save disk space (default to Yes)
echo.
echo ==================================================
echo   Do you want to remove the eden-builder image  
echo   to save disk space? ^(Y/n^)                     
echo ==================================================
echo.
set /p DELETE_IMAGE="Enter choice: "
if /I "%DELETE_IMAGE%"=="" set DELETE_IMAGE=Y

if /I "%DELETE_IMAGE%"=="Y" ( 
    echo.
    echo ================================
    echo   Removing eden-builder image  
    echo ================================
    echo.
    docker rmi -f eden-builder
    echo eden-builder image removed.
) else (
    echo.
    echo ================================
    echo   eden-builder image kept  
    echo ================================
    echo.
)

:: Ask the user if they want to delete the cached Git repository
if exist eden.tar.zst (
    echo.
    echo ==================================================
    echo   Do you want to delete the cached repository 
    echo   file eden.tar.zst to free up space? ^(y/N^)
    echo ==================================================
    echo.
    set /p DELETE_CACHE="Enter choice: "
    if /I "%DELETE_CACHE%"=="" set DELETE_CACHE=N

    if /I "%DELETE_CACHE%"=="Y" (
        echo.
        echo ================================
        echo   Deleting cached repository...  
        echo ================================
        del /Q eden.tar.zst
        echo eden.tar.zst deleted.
    ) else (
        echo.
        echo ================================
        echo   Cached repository kept.  
        echo ================================
        echo.
    )
)

pause
