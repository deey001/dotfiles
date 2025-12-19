@echo off
REM ==============================================================================
REM setup-windows.bat - Simple wrapper for local-setup.ps1
REM ==============================================================================
REM This batch file launches the PowerShell setup script with proper permissions.
REM
REM USAGE:
REM   1. Right-click this file
REM   2. Select "Run as Administrator"
REM   3. Follow the prompts
REM ==============================================================================

echo ===============================================================================
echo Dotfiles Windows Setup Launcher
echo ===============================================================================
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script requires Administrator privileges
    echo.
    echo Please right-click setup-windows.bat and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

echo Starting PowerShell setup script...
echo.

REM Run PowerShell script with bypass execution policy
powershell.exe -ExecutionPolicy Bypass -File "%~dp0local-setup.ps1"

echo.
echo ===============================================================================
echo Setup script finished
echo ===============================================================================
echo.
pause
