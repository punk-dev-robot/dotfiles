# TLP Thermal Tuning Guide for Framework 13 (AMD Ryzen 7 7840U)

## After Thermal Paste Replacement - Performance Testing Order

### Testing Order (Most Conservative → Most Performance)

#### 1. **Baseline Test First**
Keep current conservative settings and run a stress test to measure improvement from paste alone:
```bash
# Run stress test
stress-ng --cpu 8 --timeout 300s

# Monitor temps in another terminal
watch -n 1 "sensors | grep -E 'cpu@4c|fan1|PPT'"
```
Note the max temp and fan speed for comparison.

---

#### 2. **Platform Profile** (Biggest safe impact)
Edit `/etc/tlp.conf`:
```bash
PLATFORM_PROFILE_ON_AC=balanced  # from low-power
```
- Increases sustained power by 5-10W
- Apply with: `sudo tlp start`
- Test thermals again with stress-ng

---

#### 3. **Max Frequency on AC**
Edit `/etc/tlp.conf`:
```bash
CPU_SCALING_MAX_FREQ_ON_AC=4500000  # from 3500000
```
- Allows higher clocks but still no boost
- Should stay safe with good paste
- Apply and test

---

#### 4. **Governor on AC** (if temps still good)
Edit `/etc/tlp.conf`:
```bash
CPU_SCALING_GOVERNOR_ON_AC=performance  # from powersave
```
- More responsive, jumps to max freq faster
- Watch for temperature spikes
- Apply and test

---

#### 5. **CPU Boost** (Last - biggest thermal impact)
Edit `/etc/tlp.conf`:
```bash
CPU_BOOST_ON_AC=1  # from 0
```
- Enables up to 5.1GHz boost
- Can add 15-20°C to peak temps
- Only enable if staying under 85°C sustained
- Apply and test

---

#### 6. **EPP Tuning** (Fine-tuning)
Edit `/etc/tlp.conf`:
```bash
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance  # from balance_power
```
- More aggressive boosting behavior
- Final optimization step

---

## Testing Method

After each change:
1. Apply settings: `sudo tlp start`
2. Run stress test: `stress-ng --cpu 8 --timeout 300s`
3. Monitor temps: `watch -n 1 "sensors | grep -E 'cpu@4c|fan1|PPT'"`
4. Check current settings: `sudo tlp-stat -p | grep -E "governor|max_freq|boost|platform_profile"`
5. If temps stay under 80°C sustained, proceed to next step

---

## Temperature Thresholds

| Temperature Range | Status | Action |
|------------------|--------|--------|
| **Under 75°C** | Excellent | Continue to next setting |
| **75-85°C** | Good | Monitor closely, can continue |
| **85-90°C** | Warm | Consider backing off |
| **Over 90°C** | Too Hot | Revert to previous setting |

---

## Expected Results

With new thermal paste, you should gain 5-10°C headroom, likely enabling:
- Steps 1-3: Almost certainly safe
- Step 4: Probably safe
- Step 5 (Boost): Depends on paste quality and ambient temperature
- Step 6: Fine-tuning based on your results

---

## Current Conservative Settings (for reference)

```bash
# Current thermal-optimized settings
CPU_DRIVER_OPMODE_ON_AC=guided
CPU_DRIVER_OPMODE_ON_BAT=guided
CPU_SCALING_GOVERNOR_ON_AC=powersave
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_SCALING_MIN_FREQ_ON_AC=400000
CPU_SCALING_MAX_FREQ_ON_AC=3500000
CPU_SCALING_MIN_FREQ_ON_BAT=400000
CPU_SCALING_MAX_FREQ_ON_BAT=2200000
CPU_ENERGY_PERF_POLICY_ON_AC=balance_power
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
CPU_BOOST_ON_AC=0
CPU_BOOST_ON_BAT=0
PLATFORM_PROFILE_ON_AC=low-power
PLATFORM_PROFILE_ON_BAT=low-power
```

---

## Quick Commands Reference

```bash
# Apply TLP settings
sudo tlp start

# Check current settings
sudo tlp-stat -p

# Monitor thermals
sensors | grep -E "cpu@4c|fan1|PPT"

# Stress test
stress-ng --cpu 8 --timeout 300s

# Watch CPU frequencies
watch -n 1 "grep 'cpu MHz' /proc/cpuinfo | head -4"

# Check boost status
cat /sys/devices/system/cpu/cpufreq/boost
```

---

## Notes
- Always test under your typical ambient temperature conditions
- Battery settings remain conservative for longevity
- Consider your workload - compilation/encoding may need different settings than gaming
- Framework 13 is designed to handle up to 95°C safely, but 80-85°C is more comfortable