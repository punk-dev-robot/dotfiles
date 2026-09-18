#!/usr/bin/env python3
"""Drive the real tridactyl native messenger once, as the browser does.

Sends {"cmd":"run", command:"$HOME/.local/bin/url-open --route-stdin", content:<url>}
over stdio (4-byte LE length + JSON) and prints "code=<n> elapsed=<s>".
Exits non-zero unless the reply is code 0 and arrives quickly — a slow reply means
the detached app child inherited the messenger's pipes and is holding them open,
which would stall the blocking webRequest listener.

Usage: native-messenger-probe.py /usr/lib/tridactyl/native_main
"""

import json
import struct
import subprocess
import sys
import time

BUDGET_S = 5.0


def main():
    native = sys.argv[1]
    msg = {
        "cmd": "run",
        # Literal $HOME, exactly as tridactylrc ships it: proves the messenger
        # runs the command through a shell that expands it.
        "command": '"$HOME/.local/bin/url-open" --route-stdin',
        "content": "https://www.notion.so/Probe-Page-1f2a3b4c5d6e7f80912a3b4c5d6e7f80",
    }
    blob = json.dumps(msg).encode()
    started = time.monotonic()
    proc = subprocess.Popen([native], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    try:
        out, _ = proc.communicate(struct.pack("<I", len(blob)) + blob, timeout=BUDGET_S)
    except subprocess.TimeoutExpired:
        proc.kill()
        print("no reply within %.1fs (child likely holding the messenger's pipes)" % BUDGET_S)
        return 1
    elapsed = time.monotonic() - started
    size = struct.unpack("<I", out[:4])[0]
    reply = json.loads(out[4 : 4 + size])
    print("code=%s elapsed=%.2fs" % (reply.get("code"), elapsed))
    return 0 if reply.get("code") == 0 and elapsed < BUDGET_S else 1


if __name__ == "__main__":
    sys.exit(main())
