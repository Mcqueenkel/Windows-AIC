# AutoIndependentCareer for Windows (`aic`)

Farms **Umamusume: Pretty Derby** (Global, Steam) on autopilot from a Windows PC. One Steam
account rotates through many in-game accounts with Data Link, and for each account the farm:

- ends the finished Auto Training (idle) career and starts the next one (Unity Cup by default);
- stops the account for the day once it has gained 28M fans (the game day resets at 15:00 UTC);
- does the daily chores: gift box, club shoe requests and donations, Team Trials, daily races
  and Ace Runs;
- posts every finished career (fans, carats) to Discord.

## Requirements

- Windows 10 or 11, on and awake around the clock
- [Python 3.12](https://www.python.org/downloads/) and [Node.js 20](https://nodejs.org/)
- The game installed through Steam
- One Steam account that owns the game; the farm signs in with it
- A Data Link (Trainer ID + Link Password) for every in-game account you want farmed
- Optional: a Discord webhook for career reports and alerts

**Files to bring** (none of them are in this repository):

| File | Where it goes |
|---|---|
| `vendor\` (the game client, from your private backup) | `vendor\` |
| `reroll_accounts.json`, see [Roster](#roster) | the project folder |
| game data: `support_list.json`, `chara_list.json`, `succession_relation.json`, `succession_relation_member.json` | `gamedata\data\` |

## Install

In PowerShell:

```powershell
git clone https://github.com/Mcqueenkel/Windows-AIC.git aic
cd aic                                   # copy vendor\, reroll_accounts.json and gamedata\data\ in here
py -3.12 -m venv .venv
.venv\Scripts\pip install -r requirements.txt
npm install --prefix gamedata steam-user@5.3.0
npm install --prefix vendor steam-user@5.3.0
```

**1. Capture the game login (once).** Starts the game and reads the login off it into
`runtime\default\auth_config.json`:

```powershell
.\account.bat capture
```

**2. Settings.** Paste your Discord webhook(s) in, or delete those two lines:

```powershell
copy aic.env.example aic.env
notepad aic.env
```

**3. Run the tests.** Every line should say `ok`:

```powershell
$env:PYTHONUTF8 = 1; Get-ChildItem tests\test_*.py | ForEach-Object {
  .venv\Scripts\python $_.FullName *> $null; if ($LASTEXITCODE) { "FAIL $($_.Name)" } else { "ok   $($_.Name)" } }
```

**4. Steam login (once).** Asks for the Steam account name, its password and a Steam Guard
code, then stores a refresh token, so the farm never needs them again. It ends with
`STEAM TOKEN STORED`:

```powershell
.venv\Scripts\python scripts\steam_login.py
```

**5. Start the farm.** Double-click `farm.bat`, or:

```powershell
.\farm.bat
```

Within a minute the log (see [Day to day](#day-to-day)) shows `=== visit 1 | ...`, then
`Transfer accepted` and `Independent training started`.

**6. Keep it running.**

```powershell
# start it, minimized, whenever you sign in
$s = (New-Object -ComObject WScript.Shell).CreateShortcut("$([Environment]::GetFolderPath('Startup'))\aic farm.lnk")
$s.TargetPath = "$PWD\farm.bat"; $s.WorkingDirectory = "$PWD"; $s.WindowStyle = 7; $s.Save()

powercfg /change standby-timeout-ac 0    # a sleeping PC farms nothing

# optional: the wedged-farm alert every 30 minutes (put your alert webhook in)
$a = New-ScheduledTaskAction -Execute "$PWD\.venv\Scripts\pythonw.exe" -WorkingDirectory "$PWD" `
  -Argument "scripts\health_alert.py --webhook https://discord.com/api/webhooks/<id>/<token>"
Register-ScheduledTask "aic health" -Action $a `
  -Trigger (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30))
```

After a reboot the farm starts again once you sign in to Windows.

## Roster

`reroll_accounts.json` has one entry per account:

```json
[
  { "trainer_id": "123 456 789 012", "password": "LinkPassword1", "name": "farm-1", "trainee": "Oguri" },
  { "trainer_id": "234 567 890 123", "password": "LinkPassword2", "name": "ace-only", "ace_once": 5, "club": false }
]
```

| Field | Meaning |
|---|---|
| `trainer_id` | the account's Trainer ID; spaces are optional |
| `password` | its Link Password (from Data Link) |
| `name` | a label, used until the farm learns the in-game name |
| `trainee` | optional: the uma to train, by name (`Oguri`, `Oguri_alt`, …); left out, the farm picks one |
| `ace_once` | optional: do only this many Ace Runs, then leave the rotation |
| `club` | optional: `false` if the account is not in the farm's club, so the club chores are skipped |

The farm only reads the roster when it starts, so restart it once after an edit.

## Settings

**`aic.env`** (template: `aic.env.example`):

| Key | Template value | Meaning |
|---|---|---|
| `AIC_CHORES` | `1` | daily chores on/off |
| `AIC_CLUB_EVERY` | `60` | seconds between club visits per account |
| `AIC_ACE` | `1` | Ace Runs: 5 per account per week (resets Monday 15:00 UTC) |
| `AIC_TEAM` | `1` | Team Trials battles |
| `AIC_GIFTS` | `1` | claim the gift box |
| `AIC_DAILY_RACE` | `1` | use the daily race tickets |
| `AIC_FAN_TARGET` | `28000000` | fans per account per game day, then that account waits for the reset |
| `AIC_FAN_STOP_MARGIN` | `0` | stop this many fans before the target |
| `AIC_VISIT_JITTER_MIN` / `_MAX` | `0` | random extra wait between visits, in minutes |
| `AIC_CAREER_WEBHOOK` | | Discord webhook for finished careers |
| `AIC_ALERT_WEBHOOK` | | Discord webhook for health alerts |
| `AIC_MASTER_MDB` | | only if the game is not in `C:\Program Files (x86)\Steam`: the path to its `master.mdb` |

**`farm.bat`** holds the career options on its `rotate_cli.py run` line: `--scenario 2`
(Unity Cup; 1 = URA, 3 = Grand Concert, 4 = Trackblazer), the fan races to enter, TP
refills and the auto-built fan-bonus deck.

## Day to day

```powershell
Get-Content state\default\logs\aic.log -Tail 20 -Wait    # what it is doing
```

Close the log window when done: while it is open Windows cannot rotate the log at 20 MB.
If the farm crashes, the error is in `state\default\logs\farm-stderr.log` and in the farm
window, and it restarts by itself 5 minutes later.

- **Restart** (to apply a settings, roster or code change): close the farm window while the
  log's last line is `Next visit in ...`, so no visit is cut off, then start `farm.bat` again.
- **Game update:** the farm notices (API error 204), reads the new version from Steam and
  switches by itself. It reads `master.mdb` straight from the game folder, so open the game
  once to download the new one, then restart the farm.
- **Steam token expired** (the log shows 391/394 or Steam Guard errors): run step 4 again.

## Updating the code

At a gap (`Next visit in ...`), close the farm window, then:

```powershell
git pull
```

Run the tests (step 3). All `ok`? Start `farm.bat` again. A `FAIL`? Go back with
`git reset --keep HEAD@{1}` and start `farm.bat`. Careers keep running on the game server while
the farm is closed.

## Where things live

| Path | What |
|---|---|
| `aic.env` | settings and webhooks |
| `reroll_accounts.json` | the roster |
| `runtime\default\auth_config.json` | game login + Steam refresh token |
| `state\default\` | `logs\aic.log`, the fan/carat/Ace/club day state, card inventories |
| `state\accounts.json` | Link Passwords the farm has used |
| `gamedata\` | game data: `data\*.json`, `node_modules` |

How it works under the hood (the game API, selection rules, the measurements behind the
defaults): [docs/REFERENCE.md](docs/REFERENCE.md).
