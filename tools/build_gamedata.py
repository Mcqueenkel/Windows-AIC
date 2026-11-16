"""Build gamedata\\data\\*.json from the game's own master.mdb.

    .venv\\Scripts\\python tools\\build_gamedata.py      (setup.bat runs it)

Every player has master.mdb once the game is installed, so a fresh install needs no
game-data backup. Checked 2026-11-17 against the hand-kept files: every support card
name, rarity and type and every trainee name came out identical, and master.mdb also
had the 40 support and 25 trainee cards released since. Run it again after a game
update for the new cards. Finds master.mdb like the farm does (AIC_MASTER_MDB first).
"""
import json
import shutil
import sqlite3
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from aic.racedata import find_master_mdb  # noqa: E402

#: support_card_data.command_id -> the training it boosts; 0 = see support_card_type.
TYPES = {101: "Speed", 102: "Power", 103: "Guts", 105: "Stamina", 106: "Wisdom"}
KINDS = {2: "Friends", 3: "Group"}
RARITY = {1: "R", 2: "SR", 3: "SSR"}


def build(mdb: Path) -> dict:
    """``{file stem: data}`` in the same shapes as the old hand-kept files."""
    tmp = Path(tempfile.gettempdir()) / "aic_gamedata.mdb"
    shutil.copy2(mdb, tmp)                  # the running game keeps master.mdb open
    con = sqlite3.connect(f"file:{tmp}?mode=ro", uri=True)
    try:
        def text(category):
            return dict(con.execute(
                "SELECT [index], text FROM text_data WHERE category = ?", (category,)))

        card_names, chara_names = text(77), text(6)
        support = {
            str(sid): {"name": card_names[sid], "rarity": RARITY.get(rarity, "?"),
                       "type": TYPES.get(cmd) or KINDS.get(kind, "Unknown")}
            for sid, rarity, cmd, kind in con.execute(
                "SELECT id, rarity, command_id, support_card_type FROM support_card_data "
                "ORDER BY id")
            if sid in card_names        # nameless: leave it out, GameData falls back by id
        }

        # ponytail: 2nd card of a character "(Alt)", 3rd "(Alt 2)", by card id - the old
        # table's convention, and what roster trainee labels like "Oguri_alt" match on.
        charas, seen = {}, {}
        for cid, chara in con.execute("SELECT id, chara_id FROM card_data ORDER BY id"):
            if chara not in chara_names:
                continue
            k = seen[chara] = seen.get(chara, -1) + 1
            name = chara_names[chara]
            charas[str(cid)] = name if k == 0 else f"{name} (Alt)" if k == 1 else f"{name} (Alt {k})"

        relations = [{"relation_type": t, "relation_point": p} for t, p in con.execute(
            "SELECT relation_type, relation_point FROM succession_relation ORDER BY relation_type")]
        members = [{"chara_id": c, "relation_type": t} for t, c in con.execute(
            "SELECT relation_type, chara_id FROM succession_relation_member "
            "ORDER BY relation_type, chara_id")]
    finally:
        con.close()
    return {"support_list": support, "chara_list": charas,
            "succession_relation": relations, "succession_relation_member": members}


def main() -> int:
    mdb = find_master_mdb()
    if not mdb:
        print("  master.mdb not found. Install the game through Steam and open it once.\n"
              "  Installed somewhere else? Put AIC_MASTER_MDB=<full path to master.mdb>"
              " in aic.env.")
        return 1
    out = ROOT / "gamedata" / "data"
    out.mkdir(parents=True, exist_ok=True)
    for stem, data in build(mdb).items():
        (out / f"{stem}.json").write_text(json.dumps(data, indent=2, ensure_ascii=False),
                                          encoding="utf-8")
    print(f"  game data built from {mdb}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
