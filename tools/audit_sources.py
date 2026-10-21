"""Check the v0.2 runtime for accidental dependencies on the old game."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
project = (root / "project.godot").read_text(encoding="utf-8")
assert "[autoload]" not in project, "Legacy/global autoload is not allowed"
assert 'run/main_scene="res://campaign/main.tscn"' in project
references = []
for source in list((root / "campaign").rglob("*.gd")) + list((root / "campaign").rglob("*.tscn")):
    text = source.read_text(encoding="utf-8")
    for path in re.findall(r'res://[^"\s]+', text):
        assert path.startswith("res://campaign/"), (source.name, path)
        assert (root / path.removeprefix("res://")).is_file(), path
        references.append(path)
for legacy in ["components", "scenes", "scripts", "shaders", "resources", "sprites", "ost", "audio"]:
    assert not any(p.is_file() for p in (root / legacy).rglob("*")), f"Legacy files remain in {legacy}"
assert not list(root.rglob("*.ttf")), "No third-party font binaries are shipped"
assert [p.relative_to(root).as_posix() for p in (root / "campaign/audio").glob("*.wav")] == ["campaign/audio/awakening.wav"]
print(f"Source boundary audit passed: {len(references)} runtime references are local to campaign/; no legacy game sources or assets.")
