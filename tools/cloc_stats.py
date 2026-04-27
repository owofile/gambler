#!/usr/bin/env python3
"""Code statistics counter for Godot GDScript projects."""

from pathlib import Path


def count_lines(file_path: Path) -> int:
    try:
        return len(file_path.read_text(encoding="utf-8").splitlines())
    except Exception:
        return 0


def main():
    root = Path(__file__).parent.parent

    exts = {
        ".gd": "GDScript",
        ".tscn": "TSCN",
        ".json": "JSON",
        ".md": "Markdown",
    }

    stats = {}

    for ext, lang in exts.items():
        files = []
        for f in root.rglob(f"*{ext}"):
            if ".godot" in str(f) or "export_presets" in str(f):
                continue
            files.append(f)

        total_lines = sum(count_lines(f) for f in files)
        stats[lang] = (len(files), total_lines)

    # Scripts breakdown
    scripts_dir = root / "scripts"
    scripts = {}
    if scripts_dir.exists():
        for f in scripts_dir.rglob("*.gd"):
            lines = count_lines(f)
            rel = f.relative_to(scripts_dir)
            key = str(rel)
            scripts[key] = lines

    # Scenes breakdown
    scenes_dir = root / "scenes"
    scenes = {}
    if scenes_dir.exists():
        for ext in [".gd", ".tscn"]:
            for f in scenes_dir.rglob(f"*{ext}"):
                if ".godot" in str(f):
                    continue
                lines = count_lines(f)
                rel = f.relative_to(scenes_dir)
                key = str(rel)
                scenes[key] = scenes.get(key, 0) + lines

    # Print results
    print(f"{'Language':<15} {'Files':>8} {'Lines':>10}")
    print("-" * 35)
    for lang, (files, lines) in sorted(stats.items(), key=lambda x: -x[1][1]):
        print(f"{lang:<15} {files:>8} {lines:>10}")
    print("-" * 35)
    total_files = sum(v[0] for v in stats.values())
    total_lines = sum(v[1] for v in stats.values())
    print(f"{'TOTAL':<15} {total_files:>8} {total_lines:>10}")

    if scripts:
        print()
        print("=== scripts/ breakdown ===")
        total = 0
        for fpath, lines in sorted(scripts.items()):
            print(f"  {fpath:<50} {lines:>6}")
            total += lines
        print(f"  {'TOTAL':<50} {total:>6}")

    if scenes:
        print()
        print("=== scenes/ breakdown ===")
        total = 0
        for fpath, lines in sorted(scenes.items()):
            print(f"  {fpath:<60} {lines:>6}")
            total += lines
        print(f"  {'TOTAL':<60} {total:>6}")


if __name__ == "__main__":
    main()
