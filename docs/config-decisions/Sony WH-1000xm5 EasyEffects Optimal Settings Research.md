---
title: Sony WH-1000xm5 EasyEffects Optimal Settings Research
type: note
permalink: audio/sony-wh-1000xm5-easy-effects-optimal-settings-research
---

# Sony WH-1000xm5 EasyEffects Optimal Settings Research

## Current Setup Analysis
- **Headphones**: Sony WH-1000xm5 with full ANC enabled
- **Codec**: LDAC (high quality)
- **Current EQ**: AutoEQ flat target with -13.49 dB input gain
- **Largest EQ boost**: +13.5 dB at 10kHz (Hi-shelf)
- **Goal**: Audiophile setup with reference/flat tuning

## 1. Crossfeed Settings (BS2B)

### Optimal Settings for Closed-Back ANC Headphones

**Cutoff Frequency**:
- **Recommended: 650-750 Hz** for closed-back headphones
- BS2B default presets:
  - Default (700 Hz / 4.5 dB feed)
  - Chu Moy (700 Hz / 6.0 dB feed)
  - Jan Meier (650 Hz / 9.5 dB feed)
- For IEMs/closed designs, lower cutoff (400-500 Hz) is sometimes preferred
- Higher cutoff frequencies (900+ Hz) can create "sound behind head" effect

**Feed Level**:
- **Recommended: 4.5-6.0 dB** for natural soundstage
- Too high (>9 dB) can collapse stereo image excessively
- Too low (<3 dB) may not provide enough crossfeed benefit
- Sweet spot: 4.5-5.0 dB for subtle, natural effect

**Placement in Chain**:
- **Before EQ** is generally preferred for headphone listening
- Rationale: Crossfeed simulates speaker acoustics, EQ corrects frequency response
- Alternative: After EQ if you want crossfeed to work on already-corrected response

### EasyEffects Implementation
- Plugin name: "Stereo Tools" (includes crossfeed functionality)
- Enable "Balance" and crossfeed options
- Conservative settings recommended: 700 Hz / 4.5-5.0 dB

## 2. Limiter Settings

### Optimal Settings for Headphone Protection

**Threshold**:
- **Recommended: -1.0 to -0.5 dB** for headphone safety
- With +13.5 dB boost at 10kHz, conservative limiting is essential
- Start at -1.0 dB and adjust by ear
- Goal: Prevent clipping from EQ boosts, not loudness maximization

**Attack Time**:
- **Recommended: 0.5-1.0 ms** for transparent limiting
- Fast enough to catch transient peaks
- Slow enough to avoid audible artifacts
- EasyEffects LSP Limiter: Use "Fast" or "Medium" attack mode

**Release Time**:
- **Recommended: 50-100 ms** for natural recovery
- Longer release (100-200 ms) for more transparent limiting
- Shorter release (<50 ms) can cause pumping artifacts
- Auto-release can work well for varied content

**Additional Parameters**:
- **Lookahead**: Enable if available (5-10 ms typical)
- **True Peak Limiting**: Enable to prevent inter-sample peaks
- **Gain Reduction**: Should rarely exceed 2-3 dB for headphones
- **Output Ceiling**: Set to -0.1 dB for safety margin

### EasyEffects Limiter Plugin
- Use LSP Limiter (high quality) or built-in Limiter
- Mode: Brickwall or Modern
- Oversampling: Enable for best quality
- **Important**: This is protective limiting, not mastering limiting

## 3. Bass Enhancer Settings

### Optimal Settings for Flat/Reference Tuning

**Frequency Range**:
- **Recommended: 20-150 Hz** for sub-bass enhancement
- Avoid extending above 200 Hz to prevent muddiness
- Focus on sub-bass (20-60 Hz) for added depth without coloring mids
- Sony XM5 already has good bass extension with ANC

**Harmonics Generation**:
- **Recommended: Very subtle (10-20% blend)** for audiophile use
- Too much harmonic generation defeats "flat" target
- Purpose: Add perceived warmth without EQ bumps
- Consider making this bypassable for critical listening

**Amount/Drive**:
- **Recommended: Start at 0-3 dB boost equivalent**
- Can disable entirely if flat response is paramount
- Best used sparingly for genres lacking low-end presence
- Monitor for phase issues and bloat

### EasyEffects Implementation
- Plugin: "Bass Enhancer" or "Exciter"
- **Alternative approach**: Use very gentle low-shelf boost (1-2 dB at 60 Hz) instead
- **Bypassability**: Make this optional/switchable for different content
- For true flat response: Skip bass enhancement entirely

**Recommendation**: Given flat/reference goal, **consider omitting Bass Enhancer** or keep it extremely subtle and bypassable.

## 4. Optimal Plugin Order

### Recommended Signal Chain

```
1. EQ (AutoEQ correction) - Already configured
2. Crossfeed (700 Hz / 4.5 dB) - Add spatial realism
3. Bass Enhancer (optional, subtle) - Very light if used
4. Limiter (-1.0 dB threshold) - Safety/protection
```

### Rationale

**Why this order?**

1. **EQ First**: Corrects frequency response to flat target baseline
2. **Crossfeed Second**: Works on corrected frequency response, adds natural stereo image
3. **Bass Enhancer Third** (optional): Subtle enhancement after correction
4. **Limiter Last**: Catches any peaks created by processing chain

### Alternative Orders to Consider

**For maximum transparency**:
```
1. Crossfeed
2. EQ
3. Limiter
```

**For creative enhancement**:
```
1. Bass Enhancer (very subtle)
2. EQ
3. Crossfeed
4. Limiter
```

### General Principles
- **Corrective processing** (EQ) before creative processing
- **Dynamic processors** (compression/limiting) typically last
- **Spatial processors** (crossfeed) can go before or after EQ
- **Less is more** for audiophile/reference listening

## 5. Additional Recommendations

### For High-Quality Headphone Listening

**What to AVOID**:
- ❌ Heavy compression (defeats dynamic range)
- ❌ Excessive bass boost (muddies flat response)
- ❌ Multiple limiters/compressors (stacking artifacts)
- ❌ Aggressive settings (prioritize transparency)

**What to ENABLE**:
- ✅ High-quality resampling (if needed)
- ✅ Oversampling in plugins
- ✅ True peak limiting
- ✅ Gentle, transparent settings

### Input Gain Management
- Current -13.49 dB input gain is correct for AutoEQ
- This compensates for positive EQ boosts
- Prevents clipping before limiter
- Keep this setting as-is

### Testing Methodology
1. Start with EQ only (current setup)
2. Add crossfeed, adjust to taste (700 Hz / 4.5 dB starting point)
3. Add limiter for protection (-1.0 dB threshold)
4. Test bass enhancer separately (may not need it)
5. Compare A/B with original
6. Monitor for artifacts, fatigue, loss of dynamics

### Specific to Sony WH-1000xm5
- Already has good bass response with ANC
- Closed-back design benefits from crossfeed
- LDAC codec preserves processing quality
- ANC can slightly alter frequency response
- May want different presets for ANC on/off

## Summary Configuration

**Minimal Audiophile Setup**:
```json
{
  "plugins_order": [
    "equalizer#0",      // Current AutoEQ (-13.49 dB input)
    "stereo_tools#0",   // Crossfeed: 700Hz, 4.5dB
    "limiter#0"         // Threshold: -1.0dB, Attack: 1ms, Release: 100ms
  ]
}
```

**Enhanced Setup** (if desired):
```json
{
  "plugins_order": [
    "equalizer#0",      // Current AutoEQ
    "stereo_tools#0",   // Crossfeed
    "bass_enhancer#0",  // Very subtle: 20-150Hz, 10% blend
    "limiter#0"         // Protection
  ]
}
```

## References
- BS2B (Bauer stereophonic-to-binaural): Official documentation
- Crossfeed best practices: Hydrogen Audio forums
- Limiter settings: iZotope mastering guides
- Signal chain order: SonicScoop mastering chain best practices
- EasyEffects: Official documentation on plugin ordering

## Notes
- This is for **listening/playback**, not mastering
- Settings should be transparent and fatigue-free
- With flat target, preserve dynamic range
- Test with variety of music genres
- Trust your ears over measurements