#!/usr/bin/env bash
# Regression test for local/bin/url-open (Notion / Linear / Meet link routing) and the
# Tridactyl DocStart hook that calls it. Real binaries are replaced by
# mocks that log their argv, so nothing launches.
#
# Run: tests/url-open.test.sh   (needs python3 + node)
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
router="$repo/local/bin/url-open"
rc="$repo/config/omarchy/tridactyl/tridactylrc"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mockbin="$tmp/bin"
mkdir -p "$mockbin"
log="$tmp/log"

cat >"$mockbin/notion-app" <<'EOF'
#!/bin/sh
printf 'notion-app %s\n' "$*" >>"$MOCK_LOG"
[ -n "${MOCK_NOTION_FAIL:-}" ] && exit 1
exit 0
EOF
cat >"$mockbin/firefoxpwa" <<'EOF'
#!/bin/sh
printf 'firefoxpwa %s\n' "$*" >>"$MOCK_LOG"
[ -n "${MOCK_PWA_FAIL:-}" ] && exit 1
exit 0
EOF
cat >"$mockbin/zen-bin" <<'EOF'
#!/bin/sh
printf 'zen %s\n' "$*" >>"$MOCK_LOG"
exit 0
EOF
cat >"$mockbin/xdg-open" <<'EOF'
#!/bin/sh
printf 'RECURSION xdg-open %s\n' "$*" >>"$MOCK_LOG"
exit 0
EOF
chmod +x "$mockbin"/*
export MOCK_LOG="$log"
# Sandboxed $HOME so the rc hook's "$HOME/.local/bin/url-open" resolves to the repo
# copy instead of needing a deployed symlink.
fakehome="$tmp/home"
mkdir -p "$fakehome/.local/bin"
ln -s "$router" "$fakehome/.local/bin/url-open"

fails=0
pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n     %s\n' "$1" "$2"; fails=$((fails + 1)); }

# run <name> <expected-exit> <expected-log> -- args...
run() {
  local name=$1 want_code=$2 want_log=$3 stdin_data=$4
  shift 4
  : >"$log"
  local out code
  if [[ $stdin_data == "-" ]]; then
    out=$(PATH="$mockbin:/usr/bin:/bin" "$router" "$@" 2>&1)
  else
    out=$(printf '%s' "$stdin_data" | PATH="$mockbin:/usr/bin:/bin" "$router" "$@" 2>&1)
  fi
  code=$?
  local got
  got=$(tr '\n' '|' <"$log")
  if [[ $code != "$want_code" ]]; then
    fail "$name" "exit $code, want $want_code (output: $out)"
  elif [[ $got != "$want_log" ]]; then
    fail "$name" "dispatch [$got], want [$want_log]"
  else
    pass "$name"
  fi
}

# A real Notion page URL ends in its page ID; these are the only URLs we route.
pid=1f2a3b4c5d6e7f80912a3b4c5d6e7f80
uuid=1f2a3b4c-5d6e-7f80-912a-3b4c5d6e7f80
# The registered firefoxpwa site IDs the router is pinned to.
lin=01M2V2Q68ZJ85SFA5CY5V6Q5KW
meet=01M2TW5QXGJWY46NTDR6Z21WJG

echo "— argv mode: routing (page-ID allowlist)"
run "titled page -> notion-app" 0 "notion-app notion://www.notion.so/Page-Title-$pid|" - \
  "https://www.notion.so/Page-Title-$pid"
run "apex notion.so bare page id -> notion-app" 0 "notion-app notion://notion.so/$pid|" - \
  "https://notion.so/$pid"
run "workspace-scoped page -> notion-app" 0 \
  "notion-app notion://www.notion.so/myteam/Page-$pid|" - \
  "https://www.notion.so/myteam/Page-$pid"
run "hyphenated UUID page id -> notion-app" 0 "notion-app notion://www.notion.so/Page-$uuid|" - \
  "https://www.notion.so/Page-$uuid"
run "app.notion.com preserved path/query/fragment" 0 \
  "notion-app notion://app.notion.com/p/Page-$pid?v=1&b=2#blk|" - \
  "https://app.notion.com/p/Page-$pid?v=1&b=2#blk"

echo "— argv mode: host allowlist is exact"
for url in \
  "https://mysite.notion.site/Public-$pid" \
  "https://sub.notion.so/Page-$pid" \
  "https://notion.so.evil.com/Page-$pid" \
  "https://evilnotion.so/Page-$pid" \
  "https://www.notion.com/Page-$pid"; do
  run "browser keeps $url" 0 "zen $url|" - "$url"
done

echo "— argv mode: anything without a page ID stays in the browser"
# Marketing / product pages, workspace roots, and *every* auth callback shape —
# including ones we have never heard of. No deny-list to keep up to date.
for url in \
  "https://www.notion.so/" \
  "https://www.notion.so/pricing" \
  "https://www.notion.so/product/ai" \
  "https://www.notion.so/blog/whats-new" \
  "https://www.notion.so/desktop" \
  "https://www.notion.so/help/keyboard-shortcuts" \
  "https://www.notion.so/myteam" \
  "https://www.notion.so/googlepopupredirect?state=xyz" \
  "https://www.notion.so/oauth2callback?code=abc" \
  "https://app.notion.com/some-new-sso-callback?code=abc"; do
  run "browser keeps $url" 0 "zen $url|" - "$url"
done

echo "— argv mode: hardening"
run "auth flow stays in browser" 0 'zen https://www.notion.so/login?next=/x|' - \
  "https://www.notion.so/login?next=/x"
run "oauth stays in browser" 0 'zen https://api.notion.com/v1/oauth/authorize|' - \
  "https://api.notion.com/v1/oauth/authorize"
run "credentials in URL stay in browser" 0 "zen https://u:p@www.notion.so/P-$pid|" - \
  "https://u:p@www.notion.so/P-$pid"
run "nonstandard port stays in browser" 0 "zen https://www.notion.so:8443/P-$pid|" - \
  "https://www.notion.so:8443/P-$pid"
run "non-http scheme stays in browser" 0 'zen file:///etc/passwd|' - "file:///etc/passwd"
run "notion: scheme is not ours (existing desktop handler owns it)" 0 \
  "zen notion://www.notion.so/P-$pid|" - "notion://www.notion.so/P-$pid"
run "shell metacharacters not interpreted" 0 \
  "notion-app notion://www.notion.so/P-$pid#;touch /tmp/pwned|" - \
  "https://www.notion.so/P-$pid#;touch /tmp/pwned"
run "metacharacters in the path are not even routed" 0 \
  "zen https://www.notion.so/P-$pid;touch /tmp/pwned|" - \
  "https://www.notion.so/P-$pid;touch /tmp/pwned"
[[ -e /tmp/pwned ]] && fail "injection" "/tmp/pwned created" || pass "no injection side effect"

echo "— argv mode: fallbacks"
run "no args launches Zen bare" 0 'zen |' -
run "unknown flags pass through untouched" 0 "zen --new-window https://www.notion.so/P-$pid|" - \
  --new-window "https://www.notion.so/P-$pid"
run "non-Notion URL byte-exact" 0 'zen https://example.com/a?b=c%20d#e|' - \
  "https://example.com/a?b=c%20d#e"
# notion-app that dies immediately -> browser gets the link
MOCK_NOTION_FAIL=1 run "notion-app failure falls back to Zen" 0 \
  "notion-app notion://www.notion.so/P-$pid|zen https://www.notion.so/P-$pid|" - \
  "https://www.notion.so/P-$pid"
: >"$log"
# Empty PATH (python3 by absolute path) so neither notion-app nor Zen is findable.
out=$(PATH="$tmp/nonexistent" URL_OPEN_ZEN="$tmp/no-such-zen" \
  /usr/bin/python3 "$router" "https://www.notion.so/P-$pid" 2>&1)
code=$?
if [[ $code == 127 && -z $(cat "$log") && $out == *"refusing to recurse"* ]]; then
  pass "no Zen + no notion-app: errors out, never calls xdg-open"
else
  fail "missing binaries" "exit $code out=$out log=$(cat "$log")"
fi

echo "— argv mode: Linear PWA (narrow workspace-content allowlist)"
for path in \
  "myteam/issue/KUB-12/some-title" \
  "myteam/issue/KUB-12" \
  "issue/KUB-12" \
  "myteam/project/roadmap-x-1a2b" \
  "myteam/projects" \
  "myteam/team/KUB/all" \
  "myteam/view/abc-123" \
  "myteam/initiative/foo" \
  "myteam/cycle/3" \
  "myteam/my-issues" \
  "myteam/inbox" \
  "myteam/settings/members" \
  "myteam/search" \
  "myteam/roadmap"; do
  run "linear /$path -> Linear PWA" 0 "firefoxpwa site launch $lin --url https://linear.app/$path|" - \
    "https://linear.app/$path"
done
run "linear query+fragment preserved byte-exact" 0 \
  "firefoxpwa site launch $lin --url https://linear.app/myteam/issue/KUB-12?tab=activity&a=b#comment-9|" - \
  "https://linear.app/myteam/issue/KUB-12?tab=activity&a=b#comment-9"

echo "— argv mode: Linear marketing/auth/unknown paths stay in the browser"
for url in \
  "https://linear.app/" \
  "https://linear.app/homepage" \
  "https://linear.app/pricing" \
  "https://linear.app/docs/issue" \
  "https://linear.app/blog/whats-new" \
  "https://linear.app/login" \
  "https://linear.app/auth/callback?code=abc" \
  "https://linear.app/oauth/authorize?client_id=x" \
  "https://linear.app/api/graphql" \
  "https://linear.app/myteam" \
  "https://linear.app/myteam/unknown-section/x" \
  "https://linear.app/issue" \
  "https://linear.app:8443/myteam/issue/KUB-12" \
  "https://u:p@linear.app/myteam/issue/KUB-12" \
  "https://linear.app.evil.com/myteam/issue/KUB-12" \
  "https://sub.linear.app/myteam/issue/KUB-12" \
  "https://evillinear.app/myteam/issue/KUB-12"; do
  run "browser keeps $url" 0 "zen $url|" - "$url"
done

echo "— argv mode: Meet PWA (exact host)"
run "meeting code -> Meet PWA" 0 "firefoxpwa site launch $meet --url https://meet.google.com/abc-defg-hij|" - \
  "https://meet.google.com/abc-defg-hij"
run "meet query preserved" 0 \
  "firefoxpwa site launch $meet --url https://meet.google.com/abc-defg-hij?authuser=1#x|" - \
  "https://meet.google.com/abc-defg-hij?authuser=1#x"
for url in \
  "https://meet.google.com.evil.com/abc-defg-hij" \
  "https://mail.google.com/mail/u/0" \
  "https://meet.google.com:8443/abc-defg-hij" \
  "https://u:p@meet.google.com/abc-defg-hij" \
  "http://meet.google.com.co/abc"; do
  run "browser keeps $url" 0 "zen $url|" - "$url"
done

echo "— argv mode: PWA launch failures fail open"
MOCK_PWA_FAIL=1 run "firefoxpwa nonzero exit falls back to Zen" 0 \
  "firefoxpwa site launch $lin --url https://linear.app/myteam/issue/KUB-12|zen https://linear.app/myteam/issue/KUB-12|" - \
  "https://linear.app/myteam/issue/KUB-12"
MOCK_PWA_FAIL=1 run "firefoxpwa nonzero exit signals fail-open (3) in stdin mode" 3 \
  "firefoxpwa site launch $meet --url https://meet.google.com/abc-defg-hij|" \
  "https://meet.google.com/abc-defg-hij" --route-stdin
# No firefoxpwa on PATH at all, and no /usr/bin either, so the real launcher can
# never be reached: the link must land in Zen without any launch attempt.
nopwa="$tmp/bin-nopwa"
mkdir -p "$nopwa"
cp "$mockbin/zen-bin" "$mockbin/xdg-open" "$nopwa/"
: >"$log"
out=$(PATH="$nopwa" MOCK_LOG="$log" /usr/bin/python3 "$router" \
  "https://linear.app/myteam/issue/KUB-12" 2>&1)
code=$?
got=$(tr '\n' '|' <"$log")
if [[ $code == 0 && $got == "zen https://linear.app/myteam/issue/KUB-12|" ]]; then
  pass "missing firefoxpwa: no launch attempt, link goes to Zen"
else
  fail "missing firefoxpwa" "exit $code log=[$got] out=$out"
fi

echo "— --route-stdin mode (browser hook contract)"
run "dispatches and signals handled (0)" 0 "notion-app notion://www.notion.so/P-$pid|" \
  "https://www.notion.so/P-$pid" --route-stdin
run "fragment survives stdin mode" 0 "notion-app notion://www.notion.so/P-$pid#blk|" \
  "https://www.notion.so/P-$pid#blk" --route-stdin
run "skipped URL signals fail-open (3)" 3 '' "https://mysite.notion.site/P-$pid" --route-stdin
run "auth URL signals fail-open (3)" 3 '' "https://www.notion.so/login" --route-stdin
run "unknown callback signals fail-open (3)" 3 '' \
  "https://www.notion.so/googlepopupredirect?state=x" --route-stdin
run "never opens a browser in stdin mode" 3 '' "https://example.com/" --route-stdin
run "linear issue dispatches in stdin mode" 0 \
  "firefoxpwa site launch $lin --url https://linear.app/myteam/issue/KUB-12#c1|" \
  "https://linear.app/myteam/issue/KUB-12#c1" --route-stdin
run "meet dispatches in stdin mode" 0 \
  "firefoxpwa site launch $meet --url https://meet.google.com/abc-defg-hij|" \
  "https://meet.google.com/abc-defg-hij" --route-stdin
run "linear login signals fail-open (3)" 3 '' "https://linear.app/login" --route-stdin
MOCK_NOTION_FAIL=1 run "dispatch failure signals fail-open (3)" 3 \
  "notion-app notion://www.notion.so/P-$pid|" "https://www.notion.so/P-$pid" --route-stdin

echo "— Tridactyl DocStart hook (JS taken from tridactylrc)"
node - "$rc" "$fakehome" "$mockbin" "$log" "$pid" "$lin" "$meet" <<'NODE' || fails=$((fails + 1))
const fs = require("fs");
const { execFileSync } = require("child_process");
const [rcPath, fakehome, mockbin, log, pid, lin, meet] = process.argv.slice(2);

// Same tokenisation tridactyl's rc parser does: split on whitespace, rest args rejoined.
// autocmd DocStart <regex> <excmd>; the excmd must be `js <expression>`.
const hooks = fs
  .readFileSync(rcPath, "utf8")
  .split("\n")
  // ours only — the rc has unrelated `autocmd DocStart <site> mode ignore` lines.
  .filter((l) => l.startsWith("autocmd DocStart ") && l.includes("url-open"))
  .map((l) => {
    const parts = l.trim().split(/\s+/);
    const excmd = parts.slice(3).join(" ");
    if (!excmd.startsWith("js ")) throw new Error(`DocStart excmd is not js: ${excmd}`);
    return { pattern: parts[2], js: excmd.slice(3) };
  });
if (hooks.length === 0) throw new Error("no DocStart autocmd found in tridactylrc");

// autocmd keys are regexes searched against document.location.href
// (content.js loadaucmds: matchTarget.search(key) >= 0).
const matches = (pattern, url) => url.search(pattern) >= 0;

// Mock of the real content-script `tri`: native.run shells out with the URL on
// stdin and replies { code } (verified against tridactyl native_main 0.5.0);
// contentLocation is window.location, so href keeps the #fragment.
const makeTri = (href, state) => ({
  contentLocation: new URL(href),
  excmds: { tabclose: async () => { state.closed = true; } },
  native: {
    run: async (command, content) => {
      state.stdin = content;
      try {
        const out = execFileSync("/bin/sh", ["-c", command], {
          input: content,
          env: { ...process.env, HOME: fakehome, PATH: `${mockbin}:/usr/bin:/bin`, MOCK_LOG: log },
          encoding: "utf8",
        });
        return { code: 0, content: out };
      } catch (e) {
        if (e.status === undefined) throw e; // messenger itself blew up
        return { code: e.status, content: e.stdout || "" };
      }
    },
  },
});

// dispatch: false = must stay in the browser; otherwise the exact argv line the
// mocked app is expected to log (so a Linear link cannot "pass" via notion-app).
const cases = [
  // The whole point of DocStart: the #block fragment reaches the app.
  {
    url: `https://www.notion.so/Page-${pid}#abc`,
    close: false,
    dispatch: `notion-app notion://www.notion.so/Page-${pid}#abc`,
  },
  {
    url: `https://app.notion.com/myteam/Page-${pid}?v=1`,
    close: false,
    dispatch: `notion-app notion://app.notion.com/myteam/Page-${pid}?v=1`,
  },
  {
    url: "https://linear.app/myteam/issue/KUB-12?tab=activity#comment-9",
    close: false,
    dispatch: `firefoxpwa site launch ${lin} --url https://linear.app/myteam/issue/KUB-12?tab=activity#comment-9`,
  },
  {
    url: "https://linear.app/issue/KUB-12",
    close: false,
    dispatch: `firefoxpwa site launch ${lin} --url https://linear.app/issue/KUB-12`,
  },
  // Native PWAsForFirefox auto-launch owns Meet; a DocStart hook would double-dispatch.
  {
    url: "https://meet.google.com/abc-defg-hij?authuser=1",
    close: false,
    dispatch: false,
  },
  // Linear marketing / docs / auth: hook fires, router says no.
  { url: "https://linear.app/", close: false, dispatch: false },
  { url: "https://linear.app/pricing", close: false, dispatch: false },
  { url: "https://linear.app/docs/issue", close: false, dispatch: false },
  { url: "https://linear.app/login", close: false, dispatch: false },
  { url: "https://linear.app/auth/callback?code=x", close: false, dispatch: false },
  { url: "https://linear.app/myteam", close: false, dispatch: false },
  { url: "https://meet.google.com.evil.com/abc-defg-hij", close: false, dispatch: false },
  // Marketing, product and unknown auth callbacks: hook may fire, router says no.
  { url: "https://www.notion.so/pricing", close: false, dispatch: false },
  { url: "https://www.notion.so/product/ai", close: false, dispatch: false },
  { url: "https://www.notion.so/blog/whats-new", close: false, dispatch: false },
  { url: "https://www.notion.so/desktop", close: false, dispatch: false },
  { url: "https://www.notion.so/googlepopupredirect?state=x", close: false, dispatch: false },
  { url: "https://www.notion.so/oauth2callback?code=x", close: false, dispatch: false },
  { url: "https://www.notion.so/login", close: false, dispatch: false },
  // Not our hosts / not our scheme (notion: belongs to the desktop handler).
  { url: `https://mysite.notion.site/Page-${pid}`, close: false, dispatch: false },
  { url: `notion://www.notion.so/Page-${pid}`, close: false, dispatch: false },
  { url: "https://sub.linear.app/myteam/issue/KUB-12", close: false, dispatch: false },
];

(async () => {
  let bad = 0;
  let checked = 0;
  for (const c of cases) {
    const hit = hooks.filter((h) => matches(h.pattern, c.url));
    if (hit.length === 0) {
      // No hook covers this URL: the browser keeps it, which is the wanted outcome.
      if (c.dispatch) {
        console.log(`FAIL no DocStart pattern covers ${c.url} but it must be routed`);
        bad++;
      } else {
        console.log(`ok   no hook fires for ${c.url}`);
        checked++;
      }
      continue;
    }
    for (const h of hit) {
      fs.writeFileSync(log, "");
      const state = { closed: false, stdin: null };
      const tri = makeTri(c.url, state);
      await (function (tri) { return eval(h.js); })(tri); // same eval the js excmd does
      // Any of the mocked apps, logged with its full argv.
      const logged = fs.readFileSync(log, "utf8").trim();
      const want = c.dispatch === false ? "" : c.dispatch;
      const name = `DocStart ${c.url}`;
      checked++;
      if (state.closed !== c.close || logged !== want) {
        console.log(
          `FAIL ${name}: tabclose=${state.closed} want ${c.close}, dispatch=[${logged}] want [${want}]`,
        );
        bad++;
      } else if (c.dispatch && state.stdin !== c.url) {
        console.log(`FAIL ${name}: sent [${state.stdin}] to the router, want the full href`);
        bad++;
      } else {
        console.log(`ok   ${name}`);
      }
    }
  }
  if (checked === 0) {
    console.log("FAIL no hook was exercised");
    bad++;
  }
  // Native messenger unavailable => leave the navigation alone, never throw.
  for (const h of hooks) {
    const state = { closed: false };
    const broken = {
      contentLocation: new URL(`https://www.notion.so/Page-${pid}`),
      excmds: { tabclose: async () => { state.closed = true; } },
      native: { run: async () => { throw new Error("no native messenger"); } },
    };
    await (function (tri) { return eval(h.js); })(broken);
    if (state.closed) {
      console.log(`FAIL ${h.pattern} closed the tab despite native failure`);
      bad++;
    } else {
      console.log(`ok   ${h.pattern} native messenger failure leaves the page loading`);
    }
  }
  process.exit(bad === 0 ? 0 : 1);
})();
NODE

echo "— real tridactyl native messenger (skipped if not installed)"
native=/usr/lib/tridactyl/native_main
if [[ -x $native ]]; then
  # A long-lived mock app: the messenger must still answer immediately, i.e. the
  # detached child must not inherit (and hold open) the messenger's stdio pipes.
  cat >"$mockbin/notion-app" <<'EOF'
#!/bin/sh
printf 'notion-app %s pid=%s\n' "$*" "$$" >>"$MOCK_LOG"
exec sleep 30
EOF
  chmod +x "$mockbin/notion-app"
  : >"$log"
  if out=$(HOME="$fakehome" MOCK_LOG="$log" PATH="$mockbin:/usr/bin:/bin" \
    python3 "$repo/tests/lib/native-messenger-probe.py" "$native" 2>&1); then
    if grep -q notion-app "$log"; then
      pass "messenger answers promptly with a detached app child ($out)"
    else
      fail "native messenger" "no dispatch logged ($out)"
    fi
  else
    fail "native messenger" "$out"
  fi
  kill "$(sed -n 's/.*pid=\([0-9]*\).*/\1/p' "$log" | head -1)" 2>/dev/null
else
  echo "skip $native not installed"
fi

echo
if [[ $fails -eq 0 ]]; then
  echo "all url-open checks passed"
else
  echo "$fails check(s) failed"
fi
exit $((fails > 0))
