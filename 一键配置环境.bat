@echo off
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0"
title WatchWhoIsOnline - Environment Setup
set "LOG=%~dp0setup_log.txt"
set "MIRROR=https://pypi.tuna.tsinghua.edu.cn/simple"
set "REQ=%~dp0requirements.txt"
set "REQ2=%~dp0requirements-extra.txt"
set PIP_DISABLE_PIP_VERSION_CHECK=1
if "%BOT_PYVER%"=="" (set "PYVER=3.12.10") else (set "PYVER=%BOT_PYVER%")

echo ============================================================
echo   WatchWhoIsOnline - one-click environment setup
echo   Windows 10/11 64-bit, any folder, needs internet
echo   Reuses Python 3.9+, otherwise downloads 3.12 from CN mirrors
echo ============================================================
echo.
echo   WHAT THIS SCRIPT DOES (read before continuing):
echo     1. Installs Python for the CURRENT USER (no admin), silently,
echo        and adds it to your user PATH.
echo     2. Installs the pinned packages in requirements.txt via pip.
echo     It does NOT verify a checksum on the downloaded installer.
echo     Prefer doing it yourself? Manual steps are in the install
echo     guide (txt) next to this file.
echo.
call :log "==== setup start ===="

net session >nul 2>&1
if not errorlevel 1 (
    echo [WARN] Do not run as Administrator unless you have to.
    echo        Install is per-user; running elevated may put Python under
    echo        another profile. Normal double-click is recommended.
    echo.
)

call :find_python
if defined PYCMD goto have_python
echo [1/4] Python not found. Downloading Python %PYVER% ...
call :install_python
if not defined PYCMD goto fail_python

:have_python
echo [2/4] Using: %PYCMD%
%PYCMD% -c "import sys; print('      Python', sys.version.split()[0], '|', sys.executable)"
%PYCMD% -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)"
if errorlevel 1 goto fail_old
call :log "python=%PYCMD%"

if not exist "%REQ%" (
    set "MSG=requirements.txt not found next to this script."
    goto fail
)
echo [3/4] Installing dependencies from requirements.txt ...
%PYCMD% -m pip --version >nul 2>nul
if errorlevel 1 %PYCMD% -m ensurepip --upgrade
%PYCMD% -m pip install --upgrade pip -i %MIRROR% --timeout 60
%PYCMD% -m pip install -r "%REQ%" -i %MIRROR% --timeout 60
if errorlevel 1 (
    echo      [WARN] mirror failed, retrying with default PyPI ...
    %PYCMD% -m pip install -r "%REQ%" --timeout 60
)
if errorlevel 1 goto fail_pip
if not exist "%REQ2%" goto verify
echo      installing optional extras from requirements-extra.txt ...
%PYCMD% -m pip install -r "%REQ2%" -i %MIRROR% --timeout 60
if errorlevel 1 (
    echo      [WARN] extras failed on mirror, retrying with default PyPI ...
    %PYCMD% -m pip install -r "%REQ2%" --timeout 60
)
if errorlevel 1 goto fail_pip

:verify
echo [4/4] Verifying imports ...
%PYCMD% -c "import botpy, aiohttp, apscheduler, yaml; print('      botpy', getattr(botpy,'__version__','?'), '| aiohttp', aiohttp.__version__, '| APScheduler', apscheduler.__version__, '| PyYAML', yaml.__version__)"
if errorlevel 1 goto fail_verify

echo.
echo [DONE] Environment is ready.
echo        Start the bot with its own start bat. It will reuse this Python.
call :log "DONE"
echo.
echo Log: %LOG%
pause
exit /b 0

:find_python
set "PYCMD="
py -3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)" >nul 2>nul
if not errorlevel 1 set "PYCMD=py -3"
if defined PYCMD exit /b 0
python -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)" >nul 2>nul
if not errorlevel 1 set "PYCMD=python"
if defined PYCMD exit /b 0
for /d %%D in ("%LOCALAPPDATA%\Programs\Python\Python3*") do (
    if exist "%%D\python.exe" "%%D\python.exe" -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)" >nul 2>nul && set PYCMD="%%D\python.exe"
)
if defined PYCMD exit /b 0
for /d %%D in ("%ProgramFiles%\Python3*") do (
    if exist "%%D\python.exe" "%%D\python.exe" -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)" >nul 2>nul && set PYCMD="%%D\python.exe"
)
exit /b 0

:install_python
set "PKG=python-%PYVER%-amd64.exe"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "PKG=python-%PYVER%-arm64.exe"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" set "PKG=python-%PYVER%.exe"
set "EXE=%TEMP%\%PKG%"
set "M1=https://mirrors.huaweicloud.com/python/%PYVER%/%PKG%"
set "M2=https://mirrors.tuna.tsinghua.edu.cn/python/%PYVER%/%PKG%"
set "M3=https://mirrors.aliyun.com/python-release/windows/%PKG%"
set "M4=https://www.python.org/ftp/python/%PYVER%/%PKG%"
if exist "%EXE%" del /f /q "%EXE%" >nul 2>nul
if exist "%~dp0%PKG%" (
    echo      found local installer next to this script, using it.
    copy /y "%~dp0%PKG%" "%EXE%" >nul
)
if not exist "%EXE%" (
    echo      downloading from mirrors ...
    for %%M in ("%M1%" "%M2%" "%M3%" "%M4%") do (
        if not exist "%EXE%" call :try_download %%M
    )
)
if not exist "%EXE%" (
    echo      curl failed, trying PowerShell with mirror 1 ...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing -Uri '%M1%' -OutFile '%EXE%' } catch { exit 1 }"
)
if not exist "%EXE%" (
    echo      [ERROR] download failed on all mirrors.
    call :log "download failed"
    echo      Tip: download %PKG% manually into this folder and run again.
    exit /b 1
)
echo      installing per-user, no admin needed ...
start /wait "" "%EXE%" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1 Include_launcher=1 Include_test=0
timeout /t 3 /nobreak >nul
call :find_python
exit /b 0

:try_download
set "DL=%~1"
echo      trying: %DL%
curl -L --fail --retry 2 --retry-delay 2 --connect-timeout 15 -o "%EXE%" "%DL%"
if not exist "%EXE%" exit /b 1
for %%F in ("%EXE%") do set "SZ=%%~zF"
if not defined SZ exit /b 1
if %SZ% LSS 20000000 (
    echo      file too small, try next mirror.
    del /f /q "%EXE%" >nul 2>nul
    exit /b 1
)
exit /b 0

:fail_python
set "MSG=Python is not available. Install it from python.org and tick Add python.exe to PATH."
goto fail
:fail_old
set "MSG=Python found but it is older than 3.9."
goto fail
:fail_pip
set "MSG=dependency installation failed. Check the network and run this script again."
goto fail
:fail_verify
set "MSG=dependencies were installed but imports failed. Run: python -m pip install -r requirements.txt"
goto fail
:fail
echo.
echo [ERROR] %MSG%
echo         Log: %LOG%
call :log "FAIL %MSG%"
pause
exit /b 1

:log
>>"%LOG%" echo %DATE% %TIME%  %~1
exit /b 0
