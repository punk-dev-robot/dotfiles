# system/

Host-level state that dotter does not manage.

- `pkglist-arch.txt` — explicit packages from core/extra/multilib + `[omarchy]`. `sudo pacman -S --needed - < system/pkglist-arch.txt`
- `pkglist-aur.txt` — AUR packages. `yay -S --needed - < system/pkglist-aur.txt`
- `polkit/` — polkit rules, installed to `/etc/polkit-1/rules.d/` by `.dotter/post_deploy.sh`.

Both lists end with commented-out judgement calls / unverified workflows; uncomment to opt in.
Omarchy's own dependencies are not listed — `omarchy` meta package owns them.
Triage rationale: `docs/.scratch/research-KUB-82-package-triage.md` (KUB-82).
Dropped omarchy defaults (and how to re-drop them after a reinstall): `docs/reference/omarchy-diet.md`.
