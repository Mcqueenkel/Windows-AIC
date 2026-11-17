# AutoIndependentCareer for Windows (`aic`)

Farms **Umamusume: Pretty Derby** (Global, Steam) on autopilot from your PC. One Steam
account rotates through many in-game accounts with Data Link, and for each account the farm:

- ends the finished Auto Training (idle) career and starts the next one (Unity Cup by default);
- stops the account for the day once it has gained 28M fans (the game day resets at 15:00 UTC);
- does the daily chores: gift box, club shoe requests and donations, Team Trials, daily races
  and Ace Runs;
- posts every finished career (fans, carats) to Discord, if you give it a webhook.

## Setup

**1. Install these programs** (once):

- [Python 3.12](https://www.python.org/ftp/python/3.12.10/python-3.12.10-amd64.exe) (this
  link: the newest Python on python.org's front page is too new for the farm)
- [Node.js](https://nodejs.org/) (the LTS version)
- Steam, with the game installed and the farm's Steam account signed in

**2. Download this project:** on GitHub, **Code > Download ZIP**, then unzip it, for
example to `C:\aic`.

**3. Get your accounts ready.** For every in-game account you want farmed, you need:

- its **Trainer ID**, shown on the in-game profile;
- a **Link Password**, which you set in the game under **Data Link**.

**4. Double-click `setup.bat`** and follow it. It installs what it needs and opens two files
in Notepad: your settings (paste a Discord webhook if you have one) and your account list
(put your Trainer IDs and Link Passwords in place of the examples). It reads the game data
from your installed game, tests everything, then does the two logins, once:

- the game starts so its login can be read; click past the title screen if it stops there;
- it asks for the Steam account name, password and Steam Guard code.

At the end it offers to start the farm every time you sign in, to keep the PC awake, and
to start the farm now. Say yes to all three.

If setup stops, it says what is wrong. Fix that and double-click `setup.bat` again: it
skips everything that is already done.

## Using it

- **The farm** is the `farm.bat` window. Leave it open (minimized is fine). It restarts by
  itself if something crashes.
- **What is it doing?** Open `state\default\logs\aic.log` in Notepad. The newest lines are
  at the bottom.
- **Stop or restart:** close the farm window, best while the log's last line says
  `Next visit in ...`. Start it again by double-clicking `farm.bat`. Careers keep running on
  the game server while it is closed.
- **Change settings or accounts:** edit `aic.env` or `reroll_accounts.json` in Notepad, then
  restart the farm.
- **Game update:** the farm switches to the new version by itself. Open the game once so it
  downloads the update, close the farm, run `setup.bat` again (it reads the new cards from
  the game) and start the farm.
- **Steam login expired** (the log shows 391, 394 or Steam Guard errors): open PowerShell in
  the folder and run `.venv\Scripts\python scripts\steam_login.py`.

## Accounts

`reroll_accounts.json` lists the accounts to farm, one line each:

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

## Settings

`aic.env` (setup makes it from `aic.env.example`). `1` = on, `0` = off:

| Setting | Default | Meaning |
|---|---|---|
| `AIC_CHORES` | `1` | daily chores |
| `AIC_CLUB_EVERY` | `60` | seconds between club visits per account |
| `AIC_ACE` | `1` | Ace Runs: 5 per account per week (resets Monday 15:00 UTC) |
| `AIC_TEAM` | `1` | Team Trials battles |
| `AIC_GIFTS` | `1` | claim the gift box |
| `AIC_DAILY_RACE` | `1` | use the daily race tickets |
| `AIC_FAN_TARGET` | `28000000` | fans per account per game day, then that account waits for the reset |
| `AIC_FAN_STOP_MARGIN` | `0` | stop this many fans before the target |
| `AIC_VISIT_JITTER_MIN` / `_MAX` | `0` | random extra wait between visits, in minutes |
| `AIC_CAREER_WEBHOOK` | empty | Discord webhook for finished careers |
| `AIC_ALERT_WEBHOOK` | empty | Discord webhook for "the farm is stuck" alerts (see below) |
| `AIC_MASTER_MDB` | | only if the game is not in `C:\Program Files (x86)\Steam`: the full path to its `master.mdb` |

The career options (`--scenario 2` = Unity Cup; 1 = URA, 3 = Grand Concert, 4 = Trackblazer,
the fan races, TP refills, the fan-bonus deck) are on the long line in `farm.bat`.

## Optional: an alert when the farm is stuck

Checks the log every 30 minutes and posts to Discord if the farm stopped making progress.
Run this once in PowerShell, in the folder, with your alert webhook in place of the example:

```powershell
$a = New-ScheduledTaskAction -Execute "$PWD\.venv\Scripts\pythonw.exe" -WorkingDirectory "$PWD" `
  -Argument "scripts\health_alert.py --webhook https://discord.com/api/webhooks/<id>/<token>"
Register-ScheduledTask "aic health" -Action $a `
  -Trigger (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30))
```

## Updating

Close the farm window, download the new ZIP and unzip it over your folder (choose
**Replace**). Your own files are not in the ZIP, so they stay. Then double-click
`setup.bat`: it installs anything new and tests it. (Used `git clone`? Then `git pull`
instead of the ZIP.)

## Where things live

| Path | What |
|---|---|
| `aic.env` | settings and webhooks |
| `reroll_accounts.json` | your accounts |
| `state\default\logs\aic.log` | what the farm is doing; crashes go to `farm-stderr.log` next to it |
| `runtime\default\auth_config.json` | game login + Steam login token |
| `state\` | the farm's memory: fans per day, Ace/club state, Link Passwords it has used |
| `gamedata\` | game data (setup reads it from the game) and the Steam library |

How it works under the hood: [docs/REFERENCE.md](docs/REFERENCE.md).
