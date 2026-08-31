// Applies tools.json (sibling config): deactivates tools listed in "inactive".
// tools.json shape: { "active": [...], "inactive": [...] } — only "inactive" is
// enforced (subtractive), so tools unknown to the file stay untouched.
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

export default function (pi: any) {
  pi.on("session_start", () => {
    let inactive: string[];
    try {
      const cfg = JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), "..", "tools.json"), "utf8"));
      inactive = Array.isArray(cfg.inactive) ? cfg.inactive : [];
    } catch {
      return; // no tools.json / unparsable: leave defaults
    }
    if (!inactive.length) return;
    const drop = new Set(inactive);
    pi.setActiveTools(pi.getActiveTools().filter((name: string) => !drop.has(name)));
  });
}
