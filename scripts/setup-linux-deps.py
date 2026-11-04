#!/usr/bin/env python3
"""Fetch missing Arch development packages into the project without sudo."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
DEPS = ROOT / "out/deps/linux"
PACKAGES = ("openscenegraph", "collada-dom", "mygui", "unshield", "boost", "boost-libs")


def fetch(url):
    destination = DEPS / "packages" / url.rsplit("/", 1)[-1]
    if not destination.exists():
        temporary = destination.with_suffix(destination.suffix + ".part")
        subprocess.run(["curl", "--fail", "--location", "--retry", "2",
                        "--output", str(temporary), url], check=True)
        temporary.replace(destination)
    return destination


def main():
    for tool in ("pacman", "curl", "bsdtar"):
        if not shutil.which(tool):
            raise SystemExit(f"Required tool is missing: {tool}")
    (DEPS / "packages").mkdir(parents=True, exist_ok=True)
    (DEPS / "root").mkdir(parents=True, exist_ok=True)
    urls = subprocess.check_output(
        ["pacman", "-Sp", "--print-format", "%l", *PACKAGES], text=True).splitlines()
    with ThreadPoolExecutor(max_workers=4) as pool:
        archives = list(pool.map(fetch, urls))
    for archive in archives:
        subprocess.run(["bsdtar", "-xf", str(archive), "-C", str(DEPS / "root")], check=True)
    print(f"Native dependencies are available in {DEPS / 'root/usr'}")


if __name__ == "__main__":
    main()
