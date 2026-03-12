# GPU VRAM Exhaustion During Video Calls (2026-03-12)

## Hardware Context

- **GPU:** AMD Phoenix1 integrated (Ryzen 7840U) — shares system RAM via UMA
- **VRAM allocated:** 2GB (BIOS `UMA_automatic` setting)
- **Monitors:** eDP-1 (2256x1504) + DP-3 Philips ultrawide (5120x1440)
- **Compositor:** Hyprland with blur enabled (size=12, passes=3)
- **Kernel:** 6.19.6-zen1-1-zen

## Symptoms

During a Google Meet interview (15:00-16:30):
- Video froze completely
- General system slowness / heavy load
- Audio worked fine (previous PipeWire fixes held up)

## Root Cause

GPU VRAM exhaustion. **243 framebuffer pin failures** (error -12 = ENOMEM) in a 90-second burst (15:53-15:54):

```
amdgpu 0000:c1:00.0: amdgpu: pin failed
[drm:amdgpu_dm_plane_helper_prepare_fb [amdgpu]] *ERROR* Failed to pin framebuffer with error -12
```

The 2GB VRAM couldn't accommodate the combined allocation from:
- Dual-monitor scanout buffers (5120x1440 + 2256x1504, double/triple buffered)
- Hyprland blur intermediate framebuffers (3 passes at full resolution per monitor)
- Chrome GPU compositor surfaces (WebRTC video decode/encode via VA-API)
- Portal screencopy buffers for screen sharing

### Why display freezes, not degrades

`amdgpu_dm_plane_helper_prepare_fb` pins framebuffers into VRAM for KMS display planes. When VRAM is full, the kernel can't evict pinned scanout buffers (actively being displayed), so new frames fail entirely. GTT (system RAM fallback, 32GB available) doesn't work for scanout buffers — they must be in VRAM.

### Why audio was unaffected

PipeWire runs on CPU with RT scheduling (SCHED_FIFO:88), independent of GPU. The previous fixes (quantum=2048, link.max-buffers=64) are working correctly.

## BIOS VRAM Options (Framework 13 AMD 7040)

| BIOS Setting | VRAM with 64GB RAM | Notes |
|---|---|---|
| `UMA_automatic` | 2GB | Current setting, conservative default |
| `UMA_game_optimized` | 4GB | Official option, should resolve the issue |
| `UMA_specified` (hidden) | Configurable | Requires Smokeless UEFI tool, not in official BIOS |

### How to change

1. Power on, rapidly press **F2** to enter BIOS
2. Arrow to **Setup Utility** (left arrow once, down once, Enter)
3. Arrow down to **Advanced**
4. Arrow right to **iGPU Configuration**
5. Select **UMA_game_optimized**, press Enter
6. **F10** to save, confirm Yes
7. System reboots (may pause at black screen briefly, normal)

**Important:** After changing, back out to the main menu and use the boot manager rather than directly saving and rebooting, to prevent the system from reverting to defaults.

## Fix

**Pending:** Switch BIOS from `UMA_automatic` to `UMA_game_optimized` (2GB -> 4GB). Likely that BIOS 3.18 update (2026-01-21) reset this setting to defaults.

## Verification

After BIOS change, confirm VRAM allocation:

```sh
# Check VRAM total (should show 4294967296 = 4GB)
cat /sys/class/drm/card0/device/mem_info_vram_total

# Monitor for pin failures during next video call
journalctl -k --since "now" | rg 'pin failed'
```

## Diagnostics

```sh
# Current VRAM usage
cat /sys/class/drm/card0/device/mem_info_vram_used

# GTT (system RAM used by GPU) usage
cat /sys/class/drm/card0/device/mem_info_gtt_used

# GPU clock state
cat /sys/class/drm/card0/device/pp_dpm_sclk
```

## Escalation Path

If 4GB is still insufficient:
1. Use Smokeless UEFI to set `UMA_specified` to 8GB (community-tested, unofficial)
2. Reduce Hyprland blur passes from 3 to 1 during calls
3. Toggle laptop display off during calls (`hyprctl keyword monitor eDP-1, disable`)
