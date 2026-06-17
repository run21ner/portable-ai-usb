@echo off
title Portable AI - One-Click Setup
color 0E

echo ===================================================
echo        PORTABLE AI - USB SETUP
echo ===================================================
echo.
echo This will download everything you need onto this
echo USB drive. Total download size: ~1.5 GB.
echo.
echo Make sure you have a good internet connection!
echo.
pause

powershell -ExecutionPolicy Bypass -File "%~dp0install-core.ps1"

if errorlevel 1 (
    echo.
    echo ===================================================
    echo   SETUP FAILED. Check errors above and try again.
    echo ===================================================
    pause
    exit /b 1
)

echo.
echo ===================================================
echo     SETUP COMPLETE! You're ready to go!
echo ===================================================
echo.
echo To start your AI, double-click start-windows.bat
echo.
pause
