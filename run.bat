@echo off
title NovaPanel Run

set NOVAPANEL_ROOT=%~dp0

echo ========================================
echo   NovaPanel Run
echo   Daemon:  8079
echo   Web:     8080
echo   Data:    go-daemon\data\
echo ========================================
echo.

:: Check Go
where go >nul 2>nul
if errorlevel 1 (
    echo [Error] Go not found!
    echo Install from: https://golang.google.cn/dl/
    pause
    exit /b 1
)

echo [Check] Go version:
go version
echo.

:: Start services
echo [1/3] Cleaning ports 8079/8080...
call :killport 8079
call :killport 8080
echo.

echo [2/3] Tidying Go deps...
cd /d "%NOVAPANEL_ROOT%"
go mod tidy
echo.

echo [3/3] Starting NovaPanel services...
start "NovaPanel Daemon" cmd /c "cd /d %NOVAPANEL_ROOT%go-daemon && go run daemon_app.go"
timeout /t 2 >nul

start "NovaPanel Web" cmd /k "cd /d %NOVAPANEL_ROOT%go-web && go run web_app.go mcsmanager_client.go"
timeout /t 2 >nul

start "" "http://127.0.0.1:8080"

echo.
echo ========================================
echo   Started!
echo   Daemon:  http://127.0.0.1:8079
echo   Web:     http://127.0.0.1:8080
echo   Users:   %NOVAPANEL_ROOT%go-daemon\data\users.json
echo ========================================
echo Window will close in 2 seconds...
timeout /t 2 >nul
exit

:: ===== Subroutine: kill process listening on given port =====
:killport
set "KILLPORT=%~1"
if "%KILLPORT%"=="" goto :eof
set "KILLED=0"
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%KILLPORT% " ^| findstr "LISTENING"') do (
    taskkill /F /PID %%a >nul 2>nul
    echo   killed PID %%a on port %KILLPORT%
    set "KILLED=1"
)
if "%KILLED%"=="0" echo   port %KILLPORT% is free
goto :eof