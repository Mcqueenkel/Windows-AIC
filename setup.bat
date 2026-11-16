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
echo [1/7] Checking Python and Node.js
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
echo [2/7] Checking your files
set "MISSING="
if not exist "vendor\uma_api\client.py" set "MISSING=1" & echo   missing: vendor\  - the game client, from your private backup
if not exist "reroll_accounts.json" set "MISSING=1" & echo   missing: reroll_accounts.json  - your accounts, see README "Roster"
for %%f in (support_list chara_list succession_relation succession_relation_member) do if not exist "gamedata\data\%%f.json" set "MISSING=1" & echo   missing: gamedata\data\%%f.json  - from your game-data backup
if not defined MISSING goto :files_ok
echo.
echo   Put the missing files in %CD%
goto :fail
:files_ok
echo   ok

echo.
echo [3/7] Installing Python packages (the first time takes a few minutes)
if not exist "%PY%" py -%PYV% -m venv .venv || goto :fail
"%PY%" -m pip install --disable-pip-version-check -q -r requirements.txt || goto :fail
echo   ok

echo.
echo [4/7] Installing the Steam library for Node.js
if not exist "gamedata\node_modules\steam-user" call npm install --prefix gamedata steam-user@5.3.0 --silent || goto :fail
if not exist "vendor\node_modules\steam-user" call npm install --prefix vendor steam-user@5.3.0 --silent || goto :fail
echo   ok

echo.
echo [5/7] Settings
if exist "aic.env" goto :env_ok
copy /y aic.env.example aic.env >nul
echo   Notepad opens your settings. Paste your Discord webhooks if you have any,
echo   then save and close Notepad to continue.
start /wait notepad aic.env
:env_ok
echo   ok - change them any time in aic.env

echo.
echo [6/7] Self-test
set "FAILED="
for %%t in (tests\test_*.py) do "%PY%" "%%t" >nul 2>&1 || (set "FAILED=1" & echo   FAIL %%t)
if not defined FAILED goto :tests_ok
echo   Some tests failed. Check that your vendor\ and gamedata\ files are complete.
goto :fail
:tests_ok
echo   ok

echo.
echo [7/7] Logins
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
set /p "ANS=Start the farm now? [Y/N] "
if /i "%ANS%"=="y" start "aic farm" farm.bat
echo.
pause
exit /b 0

:fail
echo.
echo Setup stopped. Fix the problem above, then run setup.bat again.
pause
exit /b 1
