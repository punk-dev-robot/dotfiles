# Proton Mail → Google Calendar Invite Flow

Meeting invites arrive in Proton Mail but the primary calendar is Google Calendar. Proton Calendar has no CalDAV or API, so there's no native bridge. This doc covers the workaround.

## Strategy

Two layers, primary + fallback:

1. **Auto-forward** — Proton Mail filter sends invite emails to Gmail. Gmail's "Events from Gmail" feature auto-adds them to Google Calendar.
2. **MIME handler fallback** — When forwarding doesn't auto-add (attendee email mismatch), download the `.ics` from Proton Mail and `xdg-open` it. The `text/calendar` MIME handler opens Google Calendar with the event pre-populated.

## Auto-Forward Setup (Proton Mail Web UI)

Proton Mail's built-in forwarding supports conditional rules. Sieve `redirect` is NOT supported — forwarding must use the web UI.

Requires a paid Proton Mail plan.

1. Go to **Settings → All settings → Proton Mail → Auto-reply and forward → Forward emails → Add forwarding rule**
2. Set **Forward from** = your Proton address, **Forward to** = your Gmail address
3. Click **Add condition** and add sender-based rules:
   - If Sender contains `calendar-notification@google.com`
   - If Sender contains `calendar-notify@google.com`
   - If Sender contains `no-reply@zoom.us`
   - If Sender contains `noreply@teams.microsoft.com`
4. Click **Next** → **Send confirmation email**
5. Go to Gmail and **accept the forwarding request** from the confirmation email
6. In Gmail, verify **Settings → General → Events from Gmail** is set to "Events are automatically added to my calendar"

### Limitations

- Conditions match on sender/subject/recipient — no attachment MIME type matching, so filter by known invite senders
- Forwarding to non-Proton addresses disables E2E encryption for that forwarding address (other Proton addresses unaffected)
- Gmail may not auto-add events where the attendee email doesn't match the Gmail address — this is the main uncertainty and why the MIME handler fallback exists

## MIME Handler (xdg-open Fallback)

When auto-forward doesn't create the event, download the `.ics` from Proton Mail and run `xdg-open invite.ics`.

### How it works

- `mimeapps.list` maps `text/calendar` → `gcal-import.desktop`
- `gcal-import.desktop` calls `~/.local/bin/gcal-import`
- `gcal-import` parses the ICS file, extracts SUMMARY/DTSTART/DTEND/LOCATION/DESCRIPTION, and opens a Google Calendar `eventedit` URL with pre-populated fields
- The browser opens with the event ready to save (one click)

### Files

| File | Purpose |
|------|---------|
| `config/mimeapps.list` | MIME type → desktop entry mapping |
| `local/share/applications/gcal-import.desktop` | Desktop entry for text/calendar |
| `local/bin/gcal-import` | Shell script: ICS → GCal eventedit URL |

## Escalation Path

If forwarding proves unreliable, the next step is:

1. Install **Proton Bridge** (provides local IMAP access to Proton Mail)
2. Write a Python script that connects to Bridge via IMAP, watches for emails with `.ics` attachments, and uses the Google Calendar API to create events
3. Run as a systemd user service

This is significantly more complex and has a dependency on Proton Bridge being stable, so it's deferred unless the simpler approach doesn't work.

## Out of Scope

- **Proton Calendar share link** — 12-24h sync delay makes it unreliable for same-day invites
- **khal / vdirsyncer** — not needed since browser-based GCal viewing is sufficient
- **neomutt** — not needed for this workflow
