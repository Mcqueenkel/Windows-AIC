@echo off
REM The farm: rotates the whole roster forever and restarts 5 minutes after any
REM exit. Settings come from aic.env next to this file (template: aic.env.example).
REM Close this window to stop.
setlocal

set "HERE=%~dp0"
if "%AIC_PY%"=="" if exist "%HERE%.venv\Scripts\python.exe" set "AIC_PY=%HERE%.venv\Scripts\python.exe"
if "%AIC_PY%"=="" set "AIC_PY=python"

REM Defaults; aic.env may override them.
set "AIC_TP_JEWEL_FLOOR=0"
set "AIC_PROFILE=default"
if exist "%HERE%aic.env" for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%HERE%aic.env") do set "%%a=%%b"
REM Skill names (U+25CE etc.) crash cp1252 output once stdout is not a console.
set "PYTHONUTF8=1"

set "LOGS=%HERE%state\%AIC_PROFILE%\logs"
if not exist "%LOGS%" mkdir "%LOGS%"
cd /d "%HERE%"

:loop
echo [%date% %time%] farm running. Log: %LOGS%\aic.log
REM stdin/stdout off: no Steam Guard prompt can
REM hang it, and a click in this window (QuickEdit) cannot freeze it. Everything is
REM in aic.log; crashes land in farm-stderr.log.
"%AIC_PY%" "%HERE%rotate_cli.py" run --scenario 2 --use-tp 30 --running-style 3 --races 1:637,1:629,1:630,1:632,1:633,1:627,1:624,1:625,2:181,2:169,2:171,2:163,2:164,2:166,2:73,2:74,2:1023,2:82,2:176,2:85,2:76,2:77,2:79,2:80,2:81,3:8,3:9,3:1,3:11,3:3,3:4,3:5,3:73,3:74,3:101,3:82,3:109,3:85,3:76,3:77,3:79,3:80,3:81 --recover-tp --recover-tp-jewels --auto-deck <nul >nul 2>"%LOGS%\farm-stderr.log"
echo [%date% %time%] farm exited with %ERRORLEVEL%, restarting in 5 minutes
type "%LOGS%\farm-stderr.log"
REM Not `timeout`: it quits at once without a console and would loop Steam logins.
powershell -NoProfile -Command "Start-Sleep 300"
goto loop
