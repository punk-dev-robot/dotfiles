#!/usr/bin/env python3
"""Run Plannotator on specs markdown files after Claude edits them."""

from __future__ import annotations

import json
import shutil
import os
import subprocess
import sys
from pathlib import Path


def _resolve_file_path(cwd: str, tool_input: dict[str, object]) -> Path | None:
    file_path = tool_input.get("file_path")
    if not isinstance(file_path, str) or not file_path:
        return None

    path = Path(file_path)
    if path.is_absolute():
        return path
    if not cwd:
        return None
    return Path(cwd) / path


def _is_specs_markdown_file(project_dir: Path, file_path: Path) -> bool:
    try:
        relative_path = file_path.resolve().relative_to(project_dir.resolve())
    except ValueError:
        return False

    return relative_path.parts[:1] == ("specs",) and relative_path.suffix.lower() == ".md"


def _print_context(message: str, *, block: bool = False) -> None:
    payload: dict[str, object] = {}
    if block:
        payload["decision"] = "block"
        payload["reason"] = message
    else:
        payload["hookSpecificOutput"] = {
            "hookEventName": "PostToolUse",
            "additionalContext": message,
        }

    print(json.dumps(payload))


def main() -> None:
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as exc:
        print(f"Error: Invalid JSON input: {exc}", file=sys.stderr)
        sys.exit(1)

    cwd = input_data.get("cwd", "")
    tool_input = input_data.get("tool_input", {})
    if not isinstance(tool_input, dict):
        sys.exit(0)

    file_path = _resolve_file_path(cwd, tool_input)
    if file_path is None:
        sys.exit(0)

    project_dir = Path(cwd) if cwd else file_path.parent
    if not _is_specs_markdown_file(project_dir, file_path):
        sys.exit(0)

    plannotator = shutil.which("plannotator")
    if not plannotator:
        _print_context(
            f"Plannotator was not run for `{file_path}` because the `plannotator` executable is not installed."
        )
        sys.exit(0)

    result = subprocess.run(
        [plannotator, "annotate", str(file_path), "--hook"],
        capture_output=True,
        text=True,
        env={**os.environ, "NO_COLOR": "1"},
    )

    stdout = result.stdout.strip()
    stderr = result.stderr.strip()

    if result.returncode != 0:
        message = (
            f"Plannotator failed for `{file_path}` with exit code {result.returncode}."
        )
        if stderr:
            message = f"{message}\n\n{stderr}"
        _print_context(message, block=True)
        sys.exit(0)

    if not stdout:
        sys.exit(0)

    try:
        payload = json.loads(stdout)
    except json.JSONDecodeError:
        _print_context(
            f"Plannotator returned non-JSON hook output for `{file_path}`.\n\n{stdout}",
            block=True,
        )
        sys.exit(0)

    print(json.dumps(payload))


if __name__ == "__main__":
    main()
