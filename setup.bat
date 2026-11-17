@echo off
REM One-time setup: double-click it and answer its questions. Safe to run again:
REM every step that is already done is skipped. Messages that name a folder are kept
REM out of ( ) blocks on purpose - a path like "New folder (2)" would break them.
setlocal
cd /d "%~dp0"
set "PY=.venv\Scripts\python.exe"
set "PYTHONUTF8=1"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\aic farm.lnk"

echo.
echo [1/8] Checking Python and Node.js
if exist "%PY%" goto :python_ok
set "PYV="
for %%v in (3.12 3.11 3.10) do if not defined PYV py -%%v -c "" >nul 2>&1 && set "PYV=%%v"
if defined PYV goto :python_ok
echo   Python 3.12 is not installed. Get it from https://www.python.org/downloads/
goto :fail
:python_ok
where node >nul 2>&1 && goto :node_ok
echo   Node.js is not installed. Get the LTS version from https://nodejs.org/
goto :fail
:node_ok
echo   ok

echo.
echo [2/8] Installing Python packages (the first time takes a few minutes)
if not exist "%PY%" py -%PYV% -m venv .venv || goto :fail
"%PY%" -m pip install --disable-pip-version-check -q -r requirements.txt || goto :fail
echo   ok

echo.
echo [3/8] Installing the Steam library for Node.js
if not exist "gamedata\node_modules\steam-user" call npm install --prefix gamedata steam-user@5.3.0 --silent || goto :fail
if not exist "vendor\node_modules\steam-user" call npm install --prefix vendor steam-user@5.3.0 --silent || goto :fail
echo   ok

echo.
echo [4/8] Settings
if exist "aic.env" goto :env_ok
copy /y aic.env.example aic.env >nul
echo   Notepad opens your settings. Paste your Discord webhooks if you have any,
echo   then save and close Notepad to continue.
start /wait notepad aic.env
:env_ok
for /f "usebackq tokens=1,* delims==" %%a in ("aic.env") do if /i "%%a"=="AIC_MASTER_MDB" set "AIC_MASTER_MDB=%%b"
echo   ok - change them any time in aic.env

echo.
echo [5/8] Your accounts
if not exist "reroll_accounts.json" copy /y reroll_accounts.example.json reroll_accounts.json >nul
findstr /c:"ChangeMe2026" reroll_accounts.json >nul || goto :roster_check
echo   Notepad opens your account list. Replace the example accounts with yours:
echo   the Trainer ID from your in-game profile and the Link Password you set under
echo   Data Link, one line per account. Then save and close Notepad to continue.
start /wait notepad reroll_accounts.json
findstr /c:"ChangeMe2026" reroll_accounts.json >nul || goto :roster_check
echo   The list still has the example accounts in it.
goto :fail
:roster_check
"%PY%" -c "import json, sys; sys.excepthook = lambda t, e, tb: print('  ', e); json.load(open('reroll_accounts.json', encoding='utf-8-sig'))" && goto :roster_ok
echo   reroll_accounts.json has a typo at that line and column, usually a missing
echo   comma or quote mark. Fix it in Notepad.
goto :fail
:roster_ok
echo   ok - change it any time in reroll_accounts.json

echo.
echo [6/8] Reading the game data from the game
"%PY%" tools\build_gamedata.py && goto :data_ok
if exist "gamedata\data\support_list.json" echo   keeping the game data already in gamedata\data& goto :data_ok
goto :fail
:data_ok

echo.
echo [7/8] Self-test
set "FAILED="
for %%t in (tests\test_*.py) do "%PY%" "%%t" >nul 2>&1 || (set "FAILED=1" & echo   FAIL %%t)
if not defined FAILED goto :tests_ok
echo   Some tests failed. Download the ZIP again in case a file is missing.
goto :fail
:tests_ok
echo   ok

echo.
echo [8/8] Logins
if exist "runtime\default\auth_config.json" goto :capture_ok
echo   Open Steam and sign in first. The game now starts so its login can be read:
echo   if it stops at the title screen, click to go in. When this window says
echo   "Captured", you can close the game.
call account.bat capture || goto :fail
:capture_ok
echo   Steam login for the farm:
"%PY%" scripts\steam_login.py --if-needed || goto :fail

echo.
echo ============================================================
echo  Setup done.
echo ============================================================
if exist "%STARTUP%" goto :startup_ok
set "ANS="
set /p "ANS=Start the farm by itself every time you sign in to Windows? [Y/N] "
if /i not "%ANS%"=="y" goto :startup_ok
powershell -NoProfile -Command "$s = (New-Object -ComObject WScript.Shell).CreateShortcut($env:STARTUP); $s.TargetPath = '%~dp0farm.bat'; $s.WorkingDirectory = '%~dp0'; $s.WindowStyle = 7; $s.Save()"
echo   done - it starts minimized when you sign in
:startup_ok
set "ANS="
set /p "ANS=Stop this PC from going to sleep? The farm only works while it is awake. [Y/N] "
if /i "%ANS%"=="y" powercfg /change standby-timeout-ac 0 && echo   done
set "ANS="
set /p "ANS=Start the farm now? Say N if it is already running. [Y/N] "
if /i "%ANS%"=="y" start "aic farm" farm.bat
echo.
pause
exit /b 0

:fail
echo.
echo Setup stopped. Fix the problem above, then run setup.bat again.
pause
exit /b 1
