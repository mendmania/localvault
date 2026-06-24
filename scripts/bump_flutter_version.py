#!/usr/bin/env python3
import re
import sys
from pathlib import Path

VERSION_RE = re.compile(r"^version:\s*(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?\s*$", re.MULTILINE)


def bump_version(path: Path) -> str:
    content = path.read_text()
    match = VERSION_RE.search(content)
    if not match:
        raise SystemExit(f"No Flutter version line found in {path}")

    major, minor, patch, build = match.groups()
    next_patch = int(patch) + 1
    next_build = int(build or "0") + 1
    next_version = f"{major}.{minor}.{next_patch}+{next_build}"
    updated = VERSION_RE.sub(f"version: {next_version}", content, count=1)
    path.write_text(updated)
    return next_version


def main() -> None:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("pubspec.yaml")
    print(bump_version(path))


if __name__ == "__main__":
    main()
