"""One-time Steam login for the farm's Steam account.

    .venv\\Scripts\\python scripts\\steam_login.py              log in (again)
    .venv\\Scripts\\python scripts\\steam_login.py --if-needed  only if no token yet (setup.bat)

Stores the Steam password (obfuscated) in the profile's auth_config.json, then logs
in on this console so Steam Guard can be answered. Leaves a refresh token behind,
so the farm never needs the password or a Guard code again. Exit 1 = no token.
"""
import getpass
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from aic import cli  # noqa: E402
from aic.auth import load_auth_config, save_auth_config  # noqa: E402
from aic.config import load_settings  # noqa: E402

settings = load_settings()
cfg = load_auth_config(settings)
if "--if-needed" in sys.argv and cfg.get("steam_refresh_token"):
    print("Steam login already stored.")
    sys.exit(0)
user = os.environ.get("STEAM_USER") or input("Steam account name: ").strip()
cfg["steam_username"] = user
cfg["steam_password_seed"] = getpass.getpass(f"Steam password for {user} (it stays hidden as you type): ")
save_auth_config(settings, cfg)
print("Password stored (obfuscated). Logging in - type the Steam Guard code when asked:")
cli.main(["login"])
ok = bool(load_auth_config(settings).get("steam_refresh_token"))
print("STEAM TOKEN STORED" if ok else "no token yet - Steam login did not complete")
sys.exit(0 if ok else 1)
