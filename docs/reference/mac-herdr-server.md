# Mac as headless herdr server

Company code stays on company hardware: `kubas-mac` runs the herdr **server** for
work repos; the Linux box runs the herdr **client** and is the daily driver. Linear
project *Mac herdr server* (KUB-134…146).

## Architecture

```
Linux (client)                              kubas-mac (server)
herdr TUI ── saved machine "kubas-mac" ──ssh mac──▶ remote-client-bridge ──▶ herdr server
  ▲  sidebar: Local + kubas-mac                    (default session, detached daemon)
  │                                                  panes: shells, pi/claude, lazygit…
zsh: hm <herdr args> ─────────────────────ssh mac──▶ herdr <args>   (mac CLI, mac socket)
```

- **Saved machine**: `herdr machine list` → one profile, label `kubas-mac`, target = SSH
  alias `mac`, remote session `default`. Stored in
  `~/.local/state/herdr/client/endpoints.json`. Re-add: `herdr machine add mac --label kubas-mac`
  (interactive terminal — it may ask to install/restart a server).
- **SSH alias `mac`**: dotter template `config/custom/ssh/config`, `mac_host = "10.10.40.90"`
  in gitignored `.dotter/local.toml` — OPNsense static lease for the mac's Wi-Fi MAC
  (`5c:9b:a6:86:f6:62`). mDNS (`kubasmac.local`) was tried (KUB-136) and dropped: the dock
  ethernet MAC gets one lease whichever machine holds the dock, so after a dock switch the
  mac's stale `KubasMac.local → dock IP` record points at the Linux box for ~2 min (KUB-139).
  Key pinned to `kuba.dev.pub` (1P agent holds 6 keys, macOS sshd cuts off at MaxAuthTries).
- **Sockets are per machine.** Local `herdr …` and the `herdr_*` MCP tools only see the Linux
  server. For the mac: `hm pane list`, `hm agent prompt <name> "…"`, `hm pane split w8:p4
  --direction down`. IDs (`w8:p4`, agent names) are scoped to the mac server.
- **Headless auth on the mac (KUB-140).** The 1P desktop agent cannot prompt on the
  invisible screen, so nothing that runs over `ssh mac` may depend on it. Git: file keys
  only — `~/.ssh/kuba.mac-agent` (swap SSO, `Host github-swap`) and
  `~/.ssh/kuba.mac-agent-personal` (punk-dev-robot, `Host github.com`), `IdentitiesOnly yes`
  in the `{{#if is_macos}}` part of the ssh template; ssh offers agent keys *before* file
  keys, so no agent identity may be listed for those hosts. `op`: `OP_SERVICE_ACCOUNT_TOKEN`
  in `.zshenv.priv`; the agentgateway plist runs `zsh -lc 'exec op run …'` to pick it up.

## Server lifecycle (verified KUB-135)

No launchd unit. Herdr handles it:

- The background bridge from the Linux client **starts a stopped server** on the mac within
  ~20 s, non-interactively (tested with `herdr session stop`).
- The server is a **detached daemon** (ppid 1); killing the bridge / dropping SSH leaves it
  running, bridge reconnects in ~5 s.
- Mac TUI (`herdr` in Ghostty) attaches to the running server; detach with `ctrl+b q`. Only
  `herdr server stop` kills the server and its pane processes.
- **Never start a server by hand** (`nohup herdr server`) — herdr flags it as "may not survive
  SSH connection loss" and offers to restart it, killing panes.

**Reboot story**: FileVault pre-boot login → user login (login items: 1Password, Karabiner, WARP;
launchd: agentgateway) → Linux bridge connects → server starts. Manual login is the accepted
cost; no auto-login on a corp mac. Session restore is off — both the global **and** the per-host
default (`defaults write com.apple.loginwindow TALLogoutSavesState -bool false` and the same with
`-currentHost`); otherwise every app open at shutdown relaunches, ignoring Login Items (first M2
reboot brought back Obsidian, zen, Spotify, SoundID…). Spotify additionally autostarts from its
own pref: `app.autostart-mode="off"` in `~/Library/Application Support/Spotify/prefs`. The sidebar
shows **Attention** after every mac reboot (bridge stops retrying while the host is down); see
runbook.

## Agent topologies

1. **Agent on the mac, local to the code** — default for company code. pi/claude runs in a
   mac pane; drive it from the Linux sidebar or `hm agent prompt …`. Repo, toolchain and
   secrets never leave the mac.
2. **Agent on Linux controlling the mac** — a Linux-side agent uses `hm`/`ssh mac herdr …`
   to create panes, run commands, prompt mac agents. For orchestration, cross-repo work, or
   Linux-only tooling. Only control traffic crosses; code stays on the mac.

## Physical setup

Both machines on one TB4 KVM dock (kb/mouse/screen/ethernet follow the button). Server mode =
mac lid closed, on AC, on WiFi. Requires (owner tickets):

- `sudo pmset -c sleep 0 disablesleep 1` — lid-closed awake on AC (KUB-138).
- Wi-Fi first in `networksetup -ordernetworkservices` so a dock switch doesn't change the mac's
  route/IP (KUB-137).

## Runbook

| symptom | fix |
|---|---|
| sidebar **Attention** | first try `herdr machine disable <id> && herdr machine enable <id>` (id from `herdr machine list`) — clears stale Attention after a mac reboot or a transient auth failure, no prompts. If it comes back: a real interactive step (host key, auth, incompatible server) — run `herdr --remote mac` in a terminal, answer prompts, restart the Linux client. |
| sidebar dimmed / Reconnecting | normal after sleep/network blip; bounded backoff. Check `ssh mac uptime`, then `hm status server`. |
| `ssh mac` connection refused / timeout | mac asleep or off Wi-Fi; `ping 10.10.40.90`. If the lease changed, check OPNsense static mapping for `5c:9b:a6:86:f6:62`. |
| auth fails from Linux | 1P agent locked on Linux — unlock, `ssh-add -l`. Background bridge cannot answer prompts. |
| mac-side git/`op` hangs | something reached the 1P desktop agent (prompt on the invisible screen). Git hosts must resolve to a file key (`ssh -G git@github.com`); `op` needs `OP_SERVICE_ACCOUNT_TOKEN` (login zsh). Wrap probes in `perl -e 'alarm 10; exec @ARGV' --`. |
| version skew after `brew upgrade herdr` | client/server negotiate; don't stop a running server just because versions differ. Update the server explicitly when you need new server features. |

## Web UIs on the mac

Dev servers on the mac (repowise UI, Next dev, …) bind loopback; the mac has no screen. Two
ways in from Linux, both verified with `repowise serve --port 8000 --ui-port 3001` in the
shopai workspace (`hm pane run w9:p1 'repowise serve …'` — the herdr server is a daemon, the
pane survives ssh drops; no launchd, start per need):

- **Default — terminal-browser through the mac** (in a **plain Ghostty window**, see below):
  `terminal-browser open --ssh mac localhost:3001 --split right`. `--ssh` spawns
  `ssh -f -N -M -S /tmp/tb-ssh/<id> -D 127.0.0.1:<port> … mac` and points the browser at that
  SOCKS proxy, so `localhost` resolves *on the mac*; nothing to install remotely, ssh-config
  aliases work. Agents drive it with `terminal-browser action -- snapshot|click|eval …` (use
  `--browser <key>` from `terminal-browser ls --all` when calling from another pane). Uses the
  1P agent key like any interactive `ssh mac`; unlock first.
  **Not inside a herdr pane until herdr > 0.9.0**: herdr #3785 — the 0.9.0 client rejects its
  own direct-kitty image IDs (`boot_id` vs `local:<boot_id>`), so terminal-browser falls back to
  inline PTY graphics after frame 1 and ~12 MB RGBA frames make it unusable (seconds per
  scroll). Fixed on master 2026-09-11, unreleased as of 2026-09-16; fix is client-side, so the
  mac server can stay 0.9.0. Watch `herdr channel set preview` + `herdr update`. Ruled out
  meanwhile (don't re-investigate): herdr-pet plugin, SOCKS/Wi-Fi latency, `TERMINAL_BROWSER_FPS`,
  bypassing the herdr backend via `unset HERDR_PANE_ID` (same PTY path, same lag).
- **Fallback — real browser:** `ssh -f -N -o ExitOnForwardFailure=yes -L 3001:localhost:3001 mac`
  then `http://localhost:3001`. Don't put `LocalForward` under `Host mac` — the bridge and `hm`
  share that alias and every connection would fight over the port.

Only the **UI port** needs to cross: the repowise Next.js UI rewrites `/api/*` server-side to
the API on mac loopback (`REPOWISE_API_URL=http://localhost:8000`). Never `--host 0.0.0.0` —
that hands the company repo UI + proxied API to the LAN (repowise itself warns without
`REPOWISE_API_KEY`).

## Open

- KUB-139 reconnect matrix (owner cases: dock switch, lid, mac TUI, Linux reboot).
- KUB-143 SMAppService "Open at Login" items (Ghostty, Granola, Wispr, macshot, PortalBox,
  Logi, Spotify helper) — System Settings only. KUB-146 before/after measurement.

## Lean boot (M2)

Kept on the mac: 1Password (+ssh-agent), agentgateway, Karabiner, corp (JumpCloud, SentinelOne,
WARP), git maintenance. Audio (Spotify, SoundID, Roland interface) moved to omarchy; SoundID and
Roland launchd plists parked in `~/.disabled-launchagents/` on the mac (vendor-installed, not
repo-managed).
Removed: launchd `com.user.{tmux,colima,borders}`, `homebrew.mxcl.borders`, llm-wiki,
raindrop, vexp, Pearcleaner autoupdate (plists parked in `config/.disabled/launchagents/`);
login items AeroSpace, Amphetamine, a-bar, MiddleClick, Menuwhere (Raycast kept); Allow in
Background off for Logi Options+/Logitech Inc.; O+Connect agents `launchctl disable`d (gui +
system domain). `mac-desktop` (`local/bin`) brings the tiling + utility set back for a laptop day;
`colima start` on demand. Baseline 736 procs / 14 G used (KUB-142) → **601 procs** after
M2 (memory is noisy on macOS; process count is the honest metric).
- Remote access from outside home: parked (Tailscale vs Cloudflare WARP tunnel).
- terminal-browser inside herdr panes: blocked on herdr #3785 release (see Web UIs).
