# Month 16: Assembly

*"The difference between a pile of parts and a product is about two hundred steps, each of which can go wrong."*
*— Factory floor wisdom*

---

## The Assembly Line

The final assembly took place in a rented facility in San Jose—4,000 square feet of tables, tools, and trained technicians. This wasn't high-volume automation; it was skilled human labor building premium devices one at a time.

James Morrison had hired a team of twelve assembly technicians, each trained on the specific procedures for RichDSP. The assembly process had 47 steps, documented in a 60-page work instruction manual.

**Station 1: Main Board Inspection**

Each board arrived from the SMT assembly house with components soldered but untested. The first station performed visual inspection and basic electrical verification.

- Visual check for obvious defects
- Power-on current measurement (65-75 mA pass range)
- Clock frequency verification (±0.1% tolerance)
- Pass: Board moves to Station 2
- Fail: Board goes to rework bin

**Station 2: Firmware Loading**

A custom fixture connected to the board's test pads, loading:
- Bootloader
- Android system image
- Factory test firmware
- Unique device identity (serial number, MAC addresses)

Loading time: 4 minutes 30 seconds per board.

**Station 3: Functional Test**

The board ran through automated tests:
- I2S loopback (digital audio path)
- Analog output measurement (THD+N, SNR, frequency response)
- WiFi/Bluetooth connection test
- Display initialization
- Touchscreen calibration
- Button and control verification

Test time: 8 minutes per board.

**Station 4: Display Assembly**

The 5" IPS display bonded to the midframe using optically clear adhesive (OCA). This required:
- Clean room conditions (ISO Class 7)
- Precise alignment (±0.2mm)
- Bubble-free lamination
- UV curing (30 seconds)

Assembly time: 6 minutes.

**Station 5: Battery Installation**

The lithium battery secured with double-sided thermal tape and connector. The battery cable routed through guides to prevent pinching.

Critical check: Battery voltage verified before connection (must be 3.4-3.8V). Batteries outside this range indicate storage degradation.

**Station 6: Enclosure Assembly**

The main board assembly inserted into the aluminum enclosure. Eight screws secured the board. Thermal compound applied between output transistor area and enclosure.

Torque specification: 0.5 N·m (±10%). Over-torque strips threads; under-torque allows rattling.

**Station 7: Module Bay Installation**

The module connector installed and verified. Retention mechanism tested—module insertion and ejection 10 times.

**Station 8: Final Assembly**

Back cover attached. Rubber feet applied. Serial number laser-engraved (if not done at enclosure manufacturing).

**Station 9: Final Test**

The complete device underwent final testing:
- Boot to home screen (must complete in <45 seconds)
- Audio playback with reference module (must pass THD+N/SNR)
- Module hot-swap (insert, detect, remove, re-insert)
- Battery charging (verify charge icon and current draw)
- Cosmetic inspection (no scratches, no gaps, no defects)

**Station 10: Packaging**

Device placed in retail box with:
- USB-C cable
- Quick start guide
- Warranty card
- Regulatory documentation

Box sealed with tamper-evident sticker.

---

## Hardware Team Report

### Director of Hardware Engineering: Marcus Chen

**Status**: Assembly ramping. First finished units produced.

**Assembly Statistics (Week 2)**

| Station | Units Processed | Yield | Bottleneck? |
|---------|-----------------|-------|-------------|
| 1. Board Inspection | 2,450 | 95.2% | No |
| 2. Firmware Loading | 2,332 | 99.8% | Yes (time) |
| 3. Functional Test | 2,328 | 97.2% | No |
| 4. Display Assembly | 2,264 | 99.1% | No |
| 5. Battery Install | 2,244 | 99.6% | No |
| 6. Enclosure Assembly | 2,235 | 99.2% | No |
| 7. Module Bay | 2,217 | 99.5% | No |
| 8. Final Assembly | 2,206 | 100% | No |
| 9. Final Test | 2,206 | 98.4% | No |
| 10. Packaging | 2,171 | 100% | No |

**Cumulative yield**: 88.6% (2,171 finished units from 2,450 boards)

The Station 1 yield (95.2%) remains our primary loss point. We're still seeing elevated defect rates from the SMT assembly house.

The Station 9 failures (1.6%) are primarily cosmetic—small scratches on the enclosure that occurred during handling. We've implemented gloves and protective films to reduce this.

**Units Complete**: 2,171
**Units Required for Pre-Orders**: 1,247
**Buffer Units**: 924 (for retail, replacements, press)

We're on track to fulfill pre-orders with margin to spare.

---

### Lead Mechanical Engineer: Robert Tanaka

**Status**: Enclosure quality issues identified and resolved

The first batch of production enclosures had an issue: 8% showed visible machining marks on the interior of the module bay. While not visible when assembled, quality control flagged them.

Root cause analysis revealed tool wear. The end mill used for the module bay pocket was replaced every 200 units; it should have been replaced every 150 units.

The machining shop adjusted their process. The second batch (received this week) has <1% cosmetic defects.

**Fit and Finish Audit**

I personally inspected 50 finished units for fit and finish:

| Criteria | Units Passing |
|----------|---------------|
| Gap uniformity (<0.3mm) | 50/50 |
| Surface finish (no visible scratches) | 48/50 |
| Anodize color consistency | 50/50 |
| Button feel (tactile, no wobble) | 50/50 |
| Module ejection (smooth, consistent) | 49/50 |

The two surface finish failures were traced to handling during final assembly (Station 8). We've added cotton gloves as a requirement.

The one module ejection issue was a tight connector—within spec but at the edge. Unit was passed as acceptable.

---

## Software Team Report

### Lead Software Architect: Aisha Rahman

**Status**: Firmware 1.0.1 released. 1.1 roadmap defined.

**Firmware 1.0.1 Deployment**

The Day-1 update is ready:
- Download size: 380 MB (full system update)
- Installation time: ~5 minutes
- Changelog published on website

We've tested the update path on 100 production units. All updated successfully with no issues.

**Firmware 1.1 Roadmap (Post-Launch)**

Based on beta feedback and our own priorities:

| Feature | Priority | ETA |
|---------|----------|-----|
| UI refresh (custom theme) | High | Month 19 |
| Streaming integration (Tidal, Qobuz) | High | Month 20 |
| Gapless playback improvements | Medium | Month 19 |
| Bluetooth codec expansion (LDAC) | Medium | Month 20 |
| User-loadable EQ presets | Low | Month 21 |
| Custom DSP plugin support | Low | Month 22 |

The UI refresh is the most requested feature. We're working with a design consultant to create a custom Android launcher that feels premium.

---

### DSP Algorithm Engineer: Dr. Wei Zhang

**Status**: Performance validation on production units

I tested 25 randomly selected production units for DSP performance:

**THD+N Distribution (768kHz, -3dBFS)**

```
Range            | Count | Percentage
-----------------|-------|------------
<0.000025%       |   8   | 32%
0.000025-0.00003%|  14   | 56%
0.000030-0.00004%|   3   | 12%
>0.00004%        |   0   |  0%

Mean: 0.0000271%
Std dev: 0.0000034%
Spec limit: <0.00003%
```

All units within specification. The distribution is tight—production consistency is excellent.

**SNR Distribution**

```
Range       | Count | Percentage
------------|-------|------------
>132 dB     |   5   | 20%
131-132 dB  |  16   | 64%
130-131 dB  |   4   | 16%
<130 dB     |   0   |  0%

Mean: 131.4 dB
Spec limit: >130 dB
```

Again, all units pass with margin. The production process is under control.

---

## The Pre-Order Fulfillment Plan

James Morrison presented the fulfillment strategy to the team:

"We have 1,247 pre-orders. They're distributed across three tiers:

| Tier | Price | Includes | Count | Revenue |
|------|-------|----------|-------|---------|
| Player Only | $1,199 | Player | 312 | $374,088 |
| With Module | $1,449 | Player + AK4499 | 687 | $995,463 |
| Collector | $1,649 | Player + Module + Case | 248 | $408,952 |

Total units: 1,247 players, 935 modules
Total revenue: $1,778,503

Fulfillment starts Month 18, Week 2. We'll ship in waves:

Wave 1 (Day 1-3): Collector tier, first 248 units
Wave 2 (Day 4-7): With Module tier, first 400 units
Wave 3 (Week 2): With Module tier, remaining 287 units + Player Only
Wave 4 (Week 3): Any backorders or replacement units

This prioritizes the highest-tier backers while spreading logistics across three weeks."

Victoria approved the plan. The countdown to ship had begun.

---

## The Last-Minute Crisis

Day 22. A technician at Station 9 noticed something strange.

"This unit's serial number doesn't match the box."

The serial number laser-engraved on the enclosure was 00847. The serial number printed on the box label was 00894.

Investigation revealed a sorting error. Units had been mixed between Station 8 and Station 10. Some boxes contained wrong devices.

"How many are affected?" Victoria asked.

"We don't know. Could be a dozen. Could be a hundred."

The assembly line stopped.

For the next twelve hours, technicians opened every sealed box and verified serial number matches. They found 23 mismatches—23 units where the box didn't match the device.

Root cause: The workbench at Station 8 held multiple units simultaneously. During shift change, units were placed in wrong positions.

Fix: Station 8 now processes one unit at a time. Serial number verification added to Station 10 procedure.

Cost: 12 hours of lost assembly time, 46 boxes that needed to be resealed.

Lesson: Never underestimate human error in manufacturing.

---

## Technical Deep Dive: The Art of Final Test

*How to verify audio quality in 8 minutes*

### The Challenge

A full audio characterization takes hours. Twenty-point frequency response, THD versus level, IMD, crosstalk, noise spectrum... The list is endless.

Production testing needs to catch defects in minutes. How?

### The Golden Reference

Every test station has a "golden reference"—a known-good unit characterized to laboratory precision. Production units are compared against this reference.

Instead of measuring absolute THD+N (which requires precise signal generators and analyzers), we measure relative performance:

```
Test procedure:
1. Play 1kHz tone at -3dBFS through UUT (unit under test)
2. Capture output via loopback cable
3. Compute THD+N of captured signal
4. Compare to golden reference (must be within ±3dB)

Pass criteria:
  Golden reference THD+N: 0.000028%
  Pass range: 0.000014% to 0.000056%
```

This approach tolerates test equipment variation. As long as the UUT and golden reference are measured with the same equipment, relative comparison is valid.

### The Signature Test

Audio circuits have "signatures"—characteristic patterns that indicate correct operation.

For example, the frequency response of our reconstruction filter:

```
Frequency | Golden Response | Pass Range
----------|-----------------|------------
100 Hz    | 0.00 dB        | ±0.05 dB
1 kHz     | 0.00 dB        | ±0.05 dB
10 kHz    | -0.02 dB       | ±0.05 dB
20 kHz    | -0.08 dB       | ±0.1 dB
40 kHz    | -0.35 dB       | ±0.2 dB
80 kHz    | -3.12 dB       | ±0.5 dB
```

If a unit measures -0.15 dB at 20 kHz (outside the ±0.1 dB pass range), something is wrong. Maybe a filter capacitor has the wrong value. Maybe the op-amp is damaged. The specific failure doesn't matter for production—what matters is that the unit fails and goes to rework.

### The Quick Sweep

Rather than measuring discrete frequencies, we use a continuous sweep:

```
Test signal: Logarithmic sweep, 20 Hz to 100 kHz, 2 seconds duration
Capture: Record output during sweep
Analysis: FFT-based frequency response extraction
Comparison: Correlate with golden reference

Pass criteria: Correlation coefficient > 0.995
```

A correlation coefficient of 0.995 means the response matches the golden reference within measurement noise. Any significant deviation—wrong component, damaged chip, assembly defect—shows as reduced correlation.

### Channel Match

For stereo equipment, left and right channels must match closely:

```
Test: Apply identical signal to both channels
Measure: Amplitude and phase of each channel

Pass criteria:
  Amplitude match: <0.1 dB (any frequency 20Hz-20kHz)
  Phase match: <1° (any frequency 20Hz-20kHz)
```

Channel mismatch indicates component tolerance issues or assembly defects.

### The Full Test Sequence

In 8 minutes, we test:

| Test | Duration | Detects |
|------|----------|---------|
| DC offset | 5s | Power supply issues, component failures |
| 1 kHz THD+N | 30s | DAC issues, I/V stage problems |
| Frequency sweep | 10s | Filter problems, component values |
| Channel match | 15s | Mismatched components |
| Noise floor | 30s | Power supply noise, ground loops |
| IMD (SMPTE) | 20s | Nonlinearity, clipping |
| High-frequency | 20s | Bandwidth limitations |
| Module detection | 30s | Hot-swap functionality |
| Volume control | 20s | Attenuator operation |
| Headphone output | 60s | Output stage, protection |

Total: 4 minutes of measurement, 4 minutes of setup and data transfer.

This catches 99%+ of defects while maintaining production throughput.

---

## End of Month Status

**Budget**: $3.76M of $4.0M spent (94%)
**Schedule**: On track for Month 18 ship
**Team**: 21 engineers + 12 assembly technicians
**Morale**: Exhausted but excited

**Key Achievements**:
- Assembly line operational
- 2,171 finished units produced
- All remaining certifications complete
- Fulfillment plan approved

**Key Risks**:
1. Assembly throughput bottleneck (MEDIUM)
2. Serial number incident—process improvements needed (LOW)
3. Budget nearly exhausted (HIGH)

---

**[Next: Month 17 - The Final Push](./17_MONTH_17.md)**
