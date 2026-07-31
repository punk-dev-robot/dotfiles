/**
 * Stops pi's startup clear from erasing the terminal scrollback buffer.
 *
 * Measured cause, not inferred. With extensions loaded pi emits ESC[3J ("erase saved
 * lines") three times during startup; `pi -ne` emits it zero times. ESC[3J deletes the
 * terminal's saved history outright, so a herdr pane pre-filled with 2500 lines drops to
 * max_offset_from_bottom=18 under `pi` but keeps 2526 under `pi -ne`. The chat history
 * is not scrolling away — it is being destroyed. No scroll-position fix can apply.
 *
 * Why process.stdout.write and not ProcessTerminal.prototype.write: an earlier version
 * patched the latter (as pi-startup-redraw-fix does) and caught only 2 of the 3 clears.
 * A marker written at registration landed at byte 0 of the stream while the surviving
 * ESC[3J landed at byte 8556 and never flowed through the patched method — so it is a
 * bypass, not a load-order problem. stdout is the shared chokepoint both paths funnel to.
 *
 * Related: pi-startup-redraw-fix is inert here. It rewrites "\x1b[3J\x1b[2J\x1b[H", but
 * the forms actually emitted are "\x1b[2J\x1b[3J\x1b[H" and "\x1b[2J\x1b[H\x1b[3J", so
 * its target matched zero times in captured output.
 *
 * ponytail: strips ESC[3J unconditionally instead of matching a full clear triple —
 * one replace, no sequence state machine, and order-independent w.r.t. other patches.
 * Known ceiling: a deliberate user-initiated "clear and drop scrollback" is defanged too,
 * and a sequence straddling two write() calls is not caught (never observed in captures;
 * add a pending-suffix buffer if it ever shows up).
 */
const ERASE_SCROLLBACK = "\x1b[3J";
const ERASE_SCROLLBACK_BYTES = Buffer.from(ERASE_SCROLLBACK, "binary");
const FLAG = "__preserveScrollbackPatched__";

type WriteArgs = [chunk: unknown, encoding?: unknown, callback?: unknown];

export default function preserveScrollback(): void {
	const stream = process.stdout as NodeJS.WriteStream & { [FLAG]?: boolean };
	if (stream[FLAG]) return;

	const originalWrite = stream.write;
	if (typeof originalWrite !== "function") return;

	stream.write = function (this: unknown, ...args: WriteArgs) {
		const chunk = args[0];
		try {
			if (typeof chunk === "string") {
				if (chunk.includes(ERASE_SCROLLBACK)) {
					args[0] = chunk.split(ERASE_SCROLLBACK).join("");
				}
			} else if (Buffer.isBuffer(chunk) && chunk.includes(ERASE_SCROLLBACK_BYTES)) {
				// split/join on a Buffer needs a round-trip; "binary" is byte-preserving
				args[0] = Buffer.from(
					chunk.toString("binary").split(ERASE_SCROLLBACK).join(""),
					"binary",
				);
			}
		} catch {
			// never let a rewrite failure break terminal output
		}
		return (originalWrite as (...a: WriteArgs) => boolean).apply(this, args);
	} as typeof stream.write;

	stream[FLAG] = true;
}
