"""tools/build_gamedata.py against the real master.mdb (skipped without the game)."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools"))

from aic.racedata import find_master_mdb  # noqa: E402
from build_gamedata import build  # noqa: E402


def main() -> int:
    mdb = find_master_mdb()
    if not mdb:
        print("skipped (no master.mdb on this machine)")
        return 0
    data = build(mdb)
    support, charas = data["support_list"], data["chara_list"]
    assert support["10001"] == {"name": "Special Week", "rarity": "R", "type": "Guts"}, support["10001"]
    assert support["10002"]["type"] == "Speed" and support["30081"]["name"] == "Team Sirius"
    assert {s["type"] for s in support.values()} <= {"Speed", "Stamina", "Power", "Guts",
                                                     "Wisdom", "Friends", "Group"}
    assert charas["100101"] == "Special Week", charas["100101"]
    assert charas["100102"] == "Special Week (Alt)", charas["100102"]
    assert charas["100103"] == "Special Week (Alt 2)", charas["100103"]
    assert data["succession_relation"] and data["succession_relation_member"]
    print(f"all game-data checks passed ({len(support)} support cards, {len(charas)} trainees)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
