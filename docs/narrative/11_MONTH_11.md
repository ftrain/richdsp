# Month 11: Pre-Compliance

*"FCC certification is where good products go to die."*
*— Anonymous hardware engineer*

---

## The Testing Chamber

The pre-compliance testing facility occupied a converted warehouse in Sunnyvale—a featureless beige building hiding a million dollars of electromagnetic measurement equipment.

Inside the anechoic chamber, copper mesh walls absorbed every stray radio wave. The floor was a raised grating over more absorber. In the center, on a rotating turntable, sat the RichDSP prototype.

Elena Vasquez watched through the shielded window as the chamber technician powered up the spectrum analyzer.

"First scan is radiated emissions, 30 MHz to 1 GHz," he explained. "We're looking for anything that exceeds FCC Part 15 Class B limits."

The turntable rotated slowly as the antenna swept through frequency bands. The spectrum analyzer painted a waterfall display—frequency versus time versus amplitude.

Blue. Blue. Blue.

Then, at 250 MHz, a spike of yellow.

"Got something," the technician said. "Let me zoom in."

The spike resolved into a cluster of harmonics, centered on 250 MHz and extending to 750 MHz. The strongest peak was 8 dB over the limit.

"That's your switching power supply," Elena said immediately. "Second harmonic of 125 MHz. Damn."

"You're close on the edge at some other frequencies too." The technician highlighted several points. "The 49 MHz clock is radiating. And there's something at 400 MHz I can't identify."

Elena studied the display. The 250 MHz spike was the killer—8 dB over meant halving the emissions, which meant redesigning the power supply layout or adding more shielding.

"Can we pass with modifications?"

"Maybe. You'd need ferrite on the power supply outputs, better shielding on the module bay, and probably a common-mode choke on the display cable."

"How long to rescan?"

"Two hours setup each time. At $400/hour."

Elena calculated. They had three days of chamber time booked. Three days to find and fix every emission problem before committing to Rev C.

"Let's start with ferrite on the power supply."

---

## The 400 MHz Mystery

The 250 MHz fix was straightforward—ferrite beads on the power supply outputs, added shielding on the flyback transformer. The respcan showed the spike had dropped to 3 dB under the limit. Pass.

The 49 MHz clock was trickier. The module bay connector radiated I2S signals like an antenna. They added a conductive gasket around the bay opening. The emission dropped, but not enough.

Jin-Soo Park suggested spreading the clock spectrum with intentional jitter.

"Spread spectrum clocking," he explained. "Instead of a pure 49 MHz, we modulate the frequency ±1% at 30 kHz. The energy spreads across the band instead of spiking at one frequency."

"Won't that affect audio quality?"

"The jitter is deterministic and slow compared to audio frequencies. The DAC's PLL tracks it out."

They implemented spread spectrum in firmware. The clock emission dropped by 6 dB. Marginal pass.

The 400 MHz spike remained mysterious. It appeared only during audio playback, which suggested a signal-dependent source. But no component in the system operated at 400 MHz.

Elena traced signal paths with a near-field probe. The emission was strongest near the display connector.

"The display runs at 148.5 MHz pixel clock for 1080p," Tom Blackwood observed. "But that's not 400 MHz."

"148.5 × 2.7 = 401 MHz," Dmitri calculated. "It's a harmonic mixing product. The pixel clock mixing with something else."

They probed further. The "something else" was the 49 MHz audio clock. 148.5 MHz + 3 × 49 MHz = 295.5 MHz. Then 295.5 MHz beating with 148.5 MHz...

"This is a nightmare," Elena groaned. "We have intermodulation between completely unrelated systems."

The fix required shielding the display cable and adding a common-mode filter. The emission dropped below the limit.

Day 3: All scans passed. But barely.

---

## Hardware Team Report

### Lead EMC and Compliance Engineer: Marcus Chen (acting)

**Status**: Pre-compliance testing complete. Critical issues identified.

We don't have a dedicated EMC engineer—that position was never funded. I've taken ownership of compliance issues, with Elena supporting on power supply aspects.

**Pre-Compliance Summary**

| Test | Limit | Initial | After Fixes | Status |
|------|-------|---------|-------------|--------|
| Radiated 30-230 MHz | 40 dBµV/m | 38 dBµV/m | 35 dBµV/m | PASS |
| Radiated 230-1000 MHz | 47 dBµV/m | 55 dBµV/m | 44 dBµV/m | PASS |
| Conducted 150 kHz-30 MHz | 60 dBµV | 52 dBµV | 48 dBµV | PASS |
| Harmonic current | Class D | Class D | Class D | PASS |
| ESD (contact) | ±4 kV | Fail | ±6 kV | PASS |
| ESD (air) | ±8 kV | Fail | ±10 kV | PASS |

The ESD failures required adding TVS diodes to all external connectors and improving the enclosure grounding.

**Design Changes Required for Rev C**

1. **Power supply**: Add ferrite beads (0.47µH) on flyback output
2. **Module bay**: Conductive EMI gasket around perimeter
3. **Display cable**: Shielded FFC with common-mode choke
4. **Audio clock**: Spread spectrum enabled by default
5. **All connectors**: TVS diodes for ESD protection

**Budget Impact**

Additional BOM cost: $3.20 per unit
Additional tooling: $8,000 (EMI gasket mold)

These costs weren't in the original budget. We're dipping into contingency.

---

### Lead Power Electronics Engineer: Elena Vasquez

**Status**: Power supply EMI fixes validated

The flyback converter was the primary radiated emissions source. The fix was surprisingly simple—but only after understanding the mechanism.

**Root Cause Analysis**

The flyback transformer has parasitic capacitance between primary and secondary windings (~10pF). When the primary switch opens, the voltage spike couples through this capacitance to the secondary.

```
Primary side:        |SWITCH|
      ┌──────────────┤      ├──────────────┐
      │              └──────┘              │
      │                                    │
      │    ┌───────────────────────────┐   │
      │    │                           │   │
     ===   │     ╔═══════════════╗     │  ===
     ───   │     ║  Transformer   ║     │  ───
           │     ║               ║     │
           │     ║ ~10pF parasitic║     │
           │     ╚═══════════════╝     │
           │              │             │
           │              │ (coupled    │
           │              │  noise)     │
           │              ▼             │
           │    Secondary side         │
           │    (radiates!)            │
           └───────────────────────────┘
```

The coupled noise appears on the secondary outputs, which connect to the module via the 80-pin connector—effectively an antenna.

**Solution**

1. **Ferrite bead**: 0.47µH on secondary output adds impedance at high frequencies
2. **Y-capacitor**: 1nF from secondary to primary ground provides low-impedance path for common-mode noise
3. **Snubber**: RC network on primary switch reduces voltage spike amplitude

**Results**

| Frequency | Before | After | Improvement |
|-----------|--------|-------|-------------|
| 250 MHz | +8 dB over | -3 dB under | 11 dB |
| 500 MHz | +4 dB over | -5 dB under | 9 dB |
| 750 MHz | +2 dB over | -7 dB under | 9 dB |

The ferrite bead costs $0.08. The Y-capacitor costs $0.12. Total fix cost: $0.20 per unit.

---

## Software Team Report

### BSP/Embedded Linux Engineer: Tom Blackwood

**Status**: Spread spectrum clock implementation complete

The spread spectrum feature required kernel driver changes and coordination with the audio HAL.

**Implementation**

The Si5351 supports spread spectrum modulation through its PLL feedback registers. We added a driver interface:

```c
// clock_spread.c
int richdsp_clock_set_spread(struct richdsp_clock *clk, int enable) {
    if (enable) {
        // Enable center spread, ±1%, 30kHz rate
        si5351_write_reg(clk, SI5351_SPREAD_CFG,
                         SPREAD_ENABLE | SPREAD_CENTER |
                         SPREAD_PCT(100) | SPREAD_RATE(30000));
    } else {
        si5351_write_reg(clk, SI5351_SPREAD_CFG, 0);
    }

    return 0;
}
```

**Audio Impact Testing**

We measured audio quality with and without spread spectrum:

| Parameter | Spread Off | Spread On | Delta |
|-----------|------------|-----------|-------|
| THD+N @ 1kHz | 0.000027% | 0.000028% | +0.00001% |
| SNR | 131.8 dB | 131.6 dB | -0.2 dB |
| IMD (SMPTE) | 0.00048% | 0.00049% | +0.00001% |
| Jitter (measured) | 31 fs | 43 fs | +12 fs |

The degradation is within measurement noise. Listening tests detected no difference.

**Power-On Default**

Spread spectrum is enabled by default. Users can disable it via Settings → Advanced → Audio Clock → "Minimum Jitter Mode" for absolute purist playback.

---

### Lead Software Architect: Aisha Rahman

**Status**: OTA update system design complete

Production devices need firmware updates. We've designed a robust OTA system:

**A/B Partition Scheme**

```
┌─────────────────────────────────────────────────────────┐
│                    eMMC Storage Map                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   Partition           │ Size    │ Purpose              │
│  ─────────────────────┼─────────┼────────────────────  │
│   bootloader          │ 16 MB   │ U-Boot (fixed)       │
│   boot_a             │ 64 MB   │ Kernel + initrd (A)  │
│   boot_b             │ 64 MB   │ Kernel + initrd (B)  │
│   system_a           │ 2 GB    │ Android system (A)   │
│   system_b           │ 2 GB    │ Android system (B)   │
│   vendor_a           │ 256 MB  │ HAL + drivers (A)    │
│   vendor_b           │ 256 MB  │ HAL + drivers (B)    │
│   userdata           │ 24 GB   │ Music + settings     │
│                                                         │
│   Total: 32 GB eMMC                                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Update Flow**

1. Device downloads update to inactive partition (B if running A)
2. User continues using device normally during download
3. Download completes, device verifies signature
4. User prompted to reboot
5. Bootloader marks B as active, boots B
6. If B fails (crash loop detected), rollback to A

**Security**

- Updates signed with RSA-4096 key
- Public key embedded in bootloader (immutable)
- Downgrade protection via version counter in secure storage
- Full partition verification before boot (dm-verity)

**Module Firmware Updates**

DAC modules may contain microcontrollers (for advanced modules). The update protocol:

1. Main board detects module with updatable firmware
2. Queries current firmware version
3. If newer version available, prompts user
4. Streams update over I2C to module
5. Module verifies, reboots, reports success

This ensures modules stay compatible with main firmware.

---

## The Budget Crisis (Again)

Month 11's expenses exceeded projections by 40%. The pre-compliance testing had been budgeted at $15,000; the actual cost, including chamber time, modifications, and retesting, reached $34,000.

Victoria Sterling convened an emergency finance meeting.

"We have $1.59 million remaining," she reported. "At current burn rate, we run out in Month 16. Production was scheduled for Month 18."

The room was silent.

"Options?"

James Morrison spoke first. "We can delay production by two months. Use the time to stretch the budget."

"Delay means missing holiday season. Our pre-orders assumed December delivery."

"Better late than never delivered."

"What about cutting features?" asked Marcus.

"Which features? Everything in the current design is either essential for audio quality or required for compliance."

"The room correction DSP. That's complex, and it's not a launch requirement."

Aisha shook her head. "Room correction is already done. Cutting it saves development cost we've already spent, not future cost."

"The R2R module?"

"That's $40,000 in development we haven't started. Cutting it saves real money."

Victoria made notes. "What else?"

"We could reduce the headcount," James said quietly. "Two or three engineers, post-design-freeze."

The temperature in the room dropped.

"Who?"

"The DSP team is overstaffed for maintenance. The second module engineer isn't needed until we develop additional modules."

Victoria nodded slowly. "Draw up scenarios. Show me the numbers. We'll decide next week."

---

## The Personal Cost

That night, Dr. Kenji Yamamoto sat in his apartment, staring at his phone. The email from James was clear: *"Your position may be affected by upcoming organizational changes. Please keep this confidential."*

He'd moved from Japan for this job. Sold his house in Tokyo. Ended a fifteen-year career at Fostex. For a startup that might not survive.

His wife had stayed in Japan, planning to join him once the visa cleared. Now he wondered if he should tell her to stop the process.

The module design was nearly complete—his life's work distilled into sixty-five square millimeters of perfection. Another engineer could maintain it. Another engineer could probably improve it.

But another engineer hadn't spent thirty years learning why certain resistor brands sounded different, or why star grounding patterns mattered, or why the capacitor closest to the DAC should be C0G while the one closest to the power connector could be X7R.

He opened his laptop and began writing. Not a resignation letter—a document. "AK4499 Reference Module: Design Philosophy and Implementation Notes." Forty pages of everything he knew, formatted for the engineer who would inherit his work.

If he was leaving, he'd leave the knowledge behind.

---

## Technical Deep Dive: EMC and the Physics of Noise

*Why electromagnetic compatibility is so hard*

### The Invisible World

Every current flow creates a magnetic field. Every voltage change creates an electric field. These fields propagate outward at the speed of light, carrying energy that can interfere with other systems.

At audio frequencies (20 Hz - 20 kHz), wavelengths are enormous:
```
λ = c / f = 3×10⁸ / 20000 = 15,000 meters
```

A 15-kilometer wavelength doesn't couple efficiently to centimeter-scale circuits. Audio frequencies rarely cause EMI problems.

At switching power supply frequencies (100 kHz - 1 MHz):
```
λ = c / f = 3×10⁸ / 500000 = 600 meters
```

Still large, but harmonics extend the problem. A 500 kHz square wave contains energy at 1.5 MHz, 2.5 MHz, 3.5 MHz... Each harmonic has a shorter wavelength.

At the problematic 250 MHz:
```
λ = 3×10⁸ / 250000000 = 1.2 meters
```

A 1.2-meter wavelength couples efficiently to cables and PCB traces that are λ/4 long (30 cm). Our module connector cable is exactly that length. Oops.

### The Antenna You Didn't Design

Every conductor is an antenna. The efficiency depends on the relationship between conductor length and wavelength:

```
Monopole antenna efficiency vs length:

Length (λ) | Efficiency
-----------|-----------
  0.01     |   0.001%
  0.1      |   0.1%
  0.25     |   10%
  0.5      |   50%
  1.0      |   80%
```

A 30 cm trace is an efficient antenna at 250 MHz (λ/4). At 50 MHz, it's much less efficient (λ/6).

This explains why our 49 MHz clock was a lesser problem than the 250 MHz power supply harmonic, despite the clock being a larger signal.

### Common Mode vs. Differential Mode

EMI currents come in two flavors:

**Differential mode**: Current flows on one conductor, returns on the paired conductor. The fields largely cancel.

**Common mode**: Current flows in the same direction on both conductors, returning through a distant ground. Fields add instead of canceling.

```
Differential mode:
  ─────→─────  Current
  ─────←─────  Return (close by)
  Fields cancel. Low radiation.

Common mode:
  ─────→─────  Current
  ─────→─────  Current (same direction!)
  ══════════   Return through chassis/earth
  Fields add. High radiation.
```

The 400 MHz mystery was a common-mode problem. The display signal and audio clock, though unrelated, created a common-mode current through the shared ground plane.

### Shielding and Grounding

A shield works by providing a low-impedance path for noise currents:

```
Without shield:
  Signal ─────────────────────── Signal
  Noise couples through air
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

With shield:
  Signal ═══════════════════════ Signal
  ─────  Shield (grounded)  ─────
  Noise induced in shield, returns to source
  Most energy stays in shield circuit
```

The shield only works if it's properly grounded. A floating shield can actually increase emissions by acting as an antenna.

Our module bay shield failed initially because the gasket had high contact resistance. The gasket "looked" grounded but wasn't—3Ω of contact resistance blocked high-frequency currents.

The fix: Conductive gasket with multiple contact points, reducing total resistance to <0.1Ω.

### The Design Philosophy

Good EMC design follows principles:

1. **Contain energy at the source**: Don't let switching noise escape the power supply
2. **Minimize loop areas**: Every current needs a return path; make paths short and direct
3. **Shield thoughtfully**: Shields without good grounds make things worse
4. **Filter at boundaries**: Every cable entering or leaving is a potential antenna

These principles conflict with other design goals (cost, assembly ease, signal integrity). EMC engineering is the art of finding acceptable compromises.

We didn't budget enough time or expertise for EMC. The pre-compliance testing revealed gaps that should have been caught earlier. For Rev D—if there is a Rev D—we'll do better.

---

## End of Month Status

**Budget**: $2.76M of $4.0M spent (69%)
**Schedule**: On track for Month 12 design freeze
**Team**: 24 engineers (potential reductions pending)
**Morale**: Anxious about job security

**Key Achievements**:
- Pre-compliance testing passed
- EMI fixes identified and validated
- OTA update system designed

**Key Risks**:
1. Budget runway critically short (CRITICAL)
2. Team morale declining (HIGH)
3. Additional EMC issues may emerge at certification (MEDIUM)

---

**[Next: Month 12 - Design Freeze](./12_MONTH_12.md)**
