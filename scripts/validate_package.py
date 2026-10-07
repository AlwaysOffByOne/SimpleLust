from __future__ import annotations

import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TEXT_SUFFIXES = {".lua", ".md", ".py", ".toc", ".xml", ".yaml", ".yml"}


def tracked_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        check=True,
        capture_output=True,
    )
    return [
        ROOT / path.decode()
        for path in result.stdout.split(b"\0")
        if path
    ]


def check_whitespace(files: list[Path]) -> list[str]:
    errors: list[str] = []
    for path in files:
        relative = path.relative_to(ROOT)
        if relative.parts[0] == "Libs" or path.suffix.lower() not in TEXT_SUFFIXES:
            continue

        for line_number, line in enumerate(path.read_bytes().splitlines(), start=1):
            if line.endswith((b" ", b"\t")):
                errors.append(f"{relative}:{line_number}: trailing whitespace")
    return errors


def referenced_paths(path: Path) -> list[Path]:
    references: list[Path] = []
    if path.suffix.lower() == ".toc":
        for raw_line in path.read_text(encoding="utf-8-sig").splitlines():
            line = raw_line.strip()
            if line and not line.startswith("#"):
                references.append(ROOT / line.replace("\\", "/"))
    elif path.suffix.lower() == ".xml":
        root = ET.parse(path).getroot()
        for element in root.iter():
            if element.tag.rsplit("}", 1)[-1] in {"Include", "Script"}:
                file_name = element.get("file")
                if file_name:
                    references.append(path.parent / file_name.replace("\\", "/"))
    return references


def check_package_references() -> list[str]:
    errors: list[str] = []
    pending = list(ROOT.glob("*.toc"))
    checked: set[Path] = set()

    while pending:
        source = pending.pop().resolve()
        if source in checked:
            continue
        checked.add(source)

        for reference in referenced_paths(source):
            reference = reference.resolve()
            if not reference.is_file():
                errors.append(
                    f"{source.relative_to(ROOT)}: missing "
                    f"{reference.relative_to(ROOT)}"
                )
            elif reference.suffix.lower() == ".xml":
                pending.append(reference)

    return errors


def main() -> int:
    errors = check_whitespace(tracked_files())
    errors.extend(check_package_references())

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1

    print("Package references and whitespace are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
