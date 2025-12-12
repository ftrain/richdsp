# Month 8: First Module

*"Hardware is hard. Module hardware is harder."*
*— Marcus Chen, 3 AM email to the team*

---

## The New Hires

Two engineers joined in the first week—the module specialists Victoria had authorized.

**Dr. Kenji Yamamoto** came from Fostex in Japan, where he'd spent fifteen years designing portable audio equipment. He spoke softly, thought carefully, and had forgotten more about analog layout than most engineers ever learned.

**Lisa Tran** arrived from Intel's mobile division, an expert in power management and thermal design. She took one look at the module thermal budget and started calculating immediately.

"3 watts in a 65mm × 45mm × 12mm volume," she said. "That's 100 watts per liter. Laptop CPU territory."

"Is it doable?"

"With direct conduction to the main enclosure, yes. Without it, you'll cook the DAC in ten minutes."

She began sketching thermal solutions before her badge was printed.

---

## The Rev B Main Board

The Rev B boards arrived on schedule—four pristine green rectangles representing six months of cumulative learning. Dmitri Volkov inspected each one personally, comparing every trace to his design files.

"Perfect," he pronounced. "Even the via fills are centered."

Jin-Soo Park powered the first board at 2 PM. The current draw was wrong.

"We should see 65 milliamps idle. I'm seeing 280."

They traced the problem for hours, probing voltage rails and examining solder joints under magnification. At 11 PM, Tom Blackwood found it.

"The STM32 isn't booting. It's stuck in reset, and the reset line drives a pull-up that loads the 3.3V rail."

"Why isn't it booting?"

"The BOOT0 pin is floating. The new board needs it grounded, but we only added a test point in Rev B—no pull-down."

A single missing resistor. 10k ohms. $0.001 in component cost. It had stopped a $400 board from functioning.

"Rework?"

"Easy. Just bodge a resistor to ground."

Jin-Soo soldered the fix in five minutes. The current dropped to 68 milliamps. The STM32 booted. By midnight, they had audio.

Dmitri added "BOOT0 pull-down" to the Rev C errata list, which was already growing.

---

## Hardware Team Report

### Director of Hardware Engineering: Marcus Chen

**Status**: Rev B main board functional with rework. First module PCB in layout.

**Rev B Errata (Updated)**

| Item | Severity | Fix | Rev C Status |
|------|----------|-----|--------------|
| STM32 BOOT0 floating | High | Bodge resistor | Added pull-down |
| Debug header pinout reversed | Low | Swap cable | Corrected |
| Module power LED too bright | Low | Increase resistor | Changed |
| Thermal pad undersized | Medium | Add compound | Enlarged |

Despite the errata, Rev B is functional for development. We're proceeding with the Month 9 demo while fixing issues for Rev C.

**Module PCB Status**

Kenji has completed the AK4499 module schematic. The design uses dual AK4499 chips in true dual-mono configuration—each channel has its own DAC with independent power supply filtering.

Key specifications:
- THD target: <0.00003% (-130 dB)
- SNR target: >130 dB (A-weighted)
- Output voltage: 4.5 Vrms single-ended, 9 Vrms balanced
- Power consumption: 2.8W typical

Layout begins Monday. Target completion: Week 3.

---

### Module Analog Engineer: Dr. Kenji Yamamoto

**Status**: AK4499 Reference module schematic complete

In Japan, we have a concept: *kaizen*—continuous improvement. This module represents improvement on twenty years of DAC design.

**Dual-Mono Architecture**

Most stereo DACs share a clock and power supply between channels. This introduces crosstalk—the left channel slightly affects the right.

Our design isolates channels completely:

```
┌────────────────────────────────────────────────────────────┐
│                   AK4499 REFERENCE MODULE                  │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌─────────────────────┐   ┌─────────────────────┐        │
│  │   LEFT CHANNEL      │   │   RIGHT CHANNEL     │        │
│  │                     │   │                     │        │
│  │  ┌─────────────┐    │   │    ┌─────────────┐  │        │
│  │  │   AK4499    │    │   │    │   AK4499    │  │        │
│  │  │  (LRCK=low) │    │   │    │ (LRCK=high) │  │        │
│  │  └──────┬──────┘    │   │    └──────┬──────┘  │        │
│  │         │           │   │           │         │        │
│  │    ┌────┴────┐      │   │      ┌────┴────┐    │        │
│  │    │  I/V    │      │   │      │  I/V    │    │        │
│  │    │ Stage   │      │   │      │ Stage   │    │        │
│  │    └────┬────┘      │   │      └────┬────┘    │        │
│  │         │           │   │           │         │        │
│  │    ┌────┴────┐      │   │      ┌────┴────┐    │        │
│  │    │ Filter  │      │   │      │ Filter  │    │        │
│  │    └────┬────┘      │   │      └────┬────┘    │        │
│  │         │           │   │           │         │        │
│  │    ┌────┴────┐      │   │      ┌────┴────┐    │        │
│  │    │ Output  │      │   │      │ Output  │    │        │
│  │    └────┬────┘      │   │      └────┬────┘    │        │
│  │         │           │   │           │         │        │
│  └─────────┼───────────┘   └───────────┼─────────┘        │
│            │                           │                  │
│      LEFT OUTPUT                 RIGHT OUTPUT             │
│                                                            │
│  Power: Each channel has dedicated LDOs                   │
│  Ground: Channels share star point only                   │
│  Clock: Shared MCLK (unavoidable)                         │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

**Critical Component Selection**

After extensive listening tests and measurements, I've selected:

| Component | Part | Reason |
|-----------|------|--------|
| I/V op-amp | Sparkos Labs SS3602 | Discrete, lower noise than OPA1612 |
| Feedback resistor | Vishay Z201 590Ω | 0.01%, 2ppm/°C, zero noise index |
| Filter capacitor | Kemet C0G 100pF | 1%, low microphonics |
| Output buffer | Custom discrete | Based on Nelson Pass design |

The Sparkos Labs op-amp is controversial—it's a boutique product from a small company. But it measures better and sounds better than anything from TI or Analog Devices. In high-end audio, we follow performance, not brand names.

**Power Supply Filtering**

The module receives ±15V from the main board. This voltage carries switching noise from Elena's converter—perhaps 3mV of ripple. Our target is <10µV at the DAC.

Filtering cascade:
1. Input: 3mV ripple at 250kHz
2. π filter (22µH, 100µF, 22µH): −60dB → 3µV
3. Ultra-low-noise LDO (LT3093): −50dB → 0.1µV

Total attenuation: 110dB. The DAC sees essentially DC.

---

### Module Thermal Engineer: Lisa Tran

**Status**: Thermal analysis complete. Design is marginal.

I ran a full CFD simulation on the module in its bay. The results are concerning.

**Heat Sources**

| Component | Power (W) | Notes |
|-----------|-----------|-------|
| AK4499 × 2 | 0.6 | DAC chips |
| I/V stage × 2 | 0.4 | Op-amps |
| Output buffer × 2 | 1.6 | Class-A bias |
| LDOs | 0.2 | Regulation losses |
| **Total** | **2.8W** | |

**Thermal Analysis (Without Intervention)**

With the module sitting in the bay, no direct thermal path to enclosure:

| Component | Junction Temp (25°C ambient) | Limit |
|-----------|------------------------------|-------|
| AK4499 | 95°C | 105°C |
| SS3602 | 112°C | 125°C |
| Output transistors | 138°C | 150°C |

Everything is within absolute limits, but margins are thin. At 35°C ambient (warm room), the output transistors exceed safe operating area.

**Thermal Solution**

The module housing must conduct heat to the main enclosure:

```
┌─────────────────────────────────────────────────────────────┐
│                    MODULE CROSS-SECTION                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│         Aluminum top cover (1.5mm)                          │
│    ┌─────────────────────────────────────────────────────┐  │
│    │░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│  │
│    │░░░░░░░░░░ Thermal pad (1.0mm, 5 W/mK) ░░░░░░░░░░░░░│  │
│    │░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│  │
│    └────────────────────────┬────────────────────────────┘  │
│                             │                               │
│    ┌────────────────────────┼────────────────────────────┐  │
│    │        PCB (1.6mm)     │                            │  │
│    │                        │                            │  │
│    │    ┌───────────────────┼───────────────────────┐    │  │
│    │    │ Thermal vias (25) │                       │    │  │
│    │    │      ┌────────────┼────────────────┐      │    │  │
│    │    │      │ Output transistors (hot)    │      │    │  │
│    │    │      │     Q1, Q2, Q3, Q4          │      │    │  │
│    │    │      └────────────┴────────────────┘      │    │  │
│    │    └───────────────────────────────────────────┘    │  │
│    │                                                     │  │
│    └─────────────────────────────────────────────────────┘  │
│                                                             │
│         Aluminum base (2.0mm, contact to main enclosure)    │
│    ┌─────────────────────────────────────────────────────┐  │
│    │                                                     │  │
│    │          ↓↓↓ Heat flow to enclosure ↓↓↓            │  │
│    │                                                     │  │
│    └─────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

With thermal vias under hot components and direct conduction to the main enclosure:

| Component | Junction Temp (25°C ambient) | Junction Temp (35°C ambient) |
|-----------|------------------------------|------------------------------|
| AK4499 | 68°C | 78°C |
| SS3602 | 82°C | 92°C |
| Output transistors | 98°C | 108°C |

All within safe limits with adequate margin.

**Concern**

The thermal solution depends on good contact between module base and enclosure. Any gap—from manufacturing tolerance, dust, or misalignment—degrades performance. We need springs to maintain pressure.

---

## Software Team Report

### Senior HAL Engineer: Priya Nair

**Status**: Hot-swap demonstration ready. Edge cases remain.

We've reached the point where I can insert a module during playback and music continues (after a brief interruption). Removing a module during playback mutes cleanly. The basic demo works.

**Demo Sequence for Month 9**

1. Boot device with no module installed
2. Show "No module detected" on screen
3. Insert AK4499 module
4. Show module detection, initialization
5. Play high-resolution audio file (96kHz/24-bit)
6. Remove module during playback
7. Show mute, "Module removed" message
8. Re-insert module
9. Resume playback

Total demo time: ~3 minutes.

**Known Issues (Won't Fix for Demo)**

1. **Module removal during rate switch**: If the user removes the module while the system is switching sample rates, the state machine can deadlock. Solution: Add timeout watchdog. ETA: Month 10.

2. **Fast insertion after removal**: If a module is reinserted within 500ms of removal, the detection debounce can miss it. Solution: Increase debounce carefully. ETA: Month 10.

3. **EEPROM corruption handling**: If the EEPROM CRC fails, the system shows "Unknown module" but doesn't retry. Some users may think the module is broken. Solution: Add retry with user prompt. ETA: Month 10.

**Code Metrics**

```
Module: hardware/richdsp/audio/
Lines of code: 8,412
Files: 24
Test coverage: 67%

HAL core: 2,891 lines
Module management: 1,847 lines
DAC drivers: 2,134 lines
Clock management: 1,540 lines
```

---

### DSP Algorithm Engineer: Dr. Wei Zhang

**Status**: Room correction engine functional

The room correction system uses FIR convolution to compensate for room acoustics. A user measures their room using a calibration microphone, and our software generates correction filters.

**The Calibration Process**

1. Play logarithmic sweep (20Hz-20kHz) through speakers
2. Record response with calibration microphone
3. Compute frequency response of room
4. Design inverse filter to flatten response
5. Apply filter during playback

**Filter Implementation**

The FIR filter can reach 65,536 taps at 96kHz—a 680ms impulse response. This captures room reflections out to 230 meters (1.5× the length of a football field).

Performance on ARM Cortex-A53:

| Taps | Latency | CPU Load (single core) |
|------|---------|------------------------|
| 1,024 | 10.7 ms | 4% |
| 4,096 | 42.7 ms | 15% |
| 16,384 | 170.7 ms | 55% |
| 65,536 | 682.7 ms | 100% (cannot sustain) |

The full 65,536-tap filter exceeds one core's capacity. Solution: frequency-domain convolution with overlap-save, running on two cores.

**Optimized Implementation**

```c
// Overlap-save convolution
void convolve_overlap_save(
    float *input,    // Input samples
    float *output,   // Output samples
    float *ir_fft,   // FFT of impulse response (precomputed)
    float *buffer,   // Overlap buffer
    int block_size,  // FFT block size
    int ir_length    // Impulse response length
) {
    float fft_in[block_size];
    float fft_out[block_size];
    float product[block_size];

    // Copy overlap from previous block
    memcpy(fft_in, buffer, (block_size - ir_length) * sizeof(float));

    // Copy new input
    memcpy(fft_in + (block_size - ir_length), input, ir_length * sizeof(float));

    // FFT
    fft_forward(fft_in, fft_out, block_size);

    // Complex multiply
    complex_multiply(fft_out, ir_fft, product, block_size / 2 + 1);

    // Inverse FFT
    fft_inverse(product, fft_in, block_size);

    // Copy valid output (last ir_length samples)
    memcpy(output, fft_in + (block_size - ir_length), ir_length * sizeof(float));

    // Save overlap for next block
    memcpy(buffer, input, (block_size - ir_length) * sizeof(float));
}
```

With FFT optimization:
- 65,536-tap filter: 45% CPU on two cores
- Latency: 170ms (acceptable for playback, not for live monitoring)

---

## The Investor Demo Prep

Week 4 was consumed by preparation. The demo had to be flawless.

Marcus assembled a "demo rig"—a single system with every component verified:
- Rev B main board (with bodge fixes)
- Prototype AK4497 module (using evaluation DAC, custom analog section)
- Prototype enclosure (3D printed, non-functional thermal)
- 5" display running Android
- Custom music player app

They rehearsed the demo thirty times. Every click, every insertion, every possible failure point.

"What if the module doesn't detect on first insertion?" Victoria asked.

"We wait three seconds and try again. If it still fails, I'll say 'This sometimes happens with early prototypes' and move on."

"What if the audio glitches?"

"We have three demo tracks. If one glitches, we switch to another."

"What if the board catches fire?"

"We have a fire extinguisher under the table."

Victoria smiled grimly. "That's not a joke, is it?"

"Elena's first power supply taught us to be prepared."

---

## Technical Deep Dive: The I2S Bus

*How digital audio travels from processor to DAC*

### I2S: The Universal Audio Bus

Inter-IC Sound (I2S) was developed by Philips in 1986. It's now the standard for digital audio connections within devices.

Three signals:
- **BCLK** (Bit Clock): Clocks each bit
- **LRCK** (Left/Right Clock): Indicates channel (low=left, high=right)
- **DATA**: Serial audio data

```
BCLK:   ▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲▔╲
LRCK:   ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔╲▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
DATA:   ─M─┬─D23┬─D22┬─D21┬─D20┬─D19┬─D18┬─D17┬─D16┬─...─

        ▲     ▲
        │     │
        │     └── MSB of left channel sample
        └── One bit clock period
```

### Timing Relationships

For 192 kHz, 24-bit stereo:

```
Sample rate:    192,000 samples/second
Bits per sample: 24
Channels:        2

LRCK frequency = 192,000 Hz
BCLK frequency = 192,000 × 24 × 2 = 9.216 MHz
MCLK frequency = 192,000 × 256 = 49.152 MHz (256× oversampling)
```

At 768 kHz sample rate (our maximum):
- BCLK = 49.152 MHz
- MCLK = 196.608 MHz

These frequencies approach the limits of standard CMOS logic. Signal integrity becomes critical.

### Signal Integrity at 50 MHz

A 49 MHz square wave has significant energy content at the third harmonic (147 MHz) and fifth harmonic (245 MHz). At these frequencies:

1. **Trace inductance matters**: 10 nH (1 cm of trace) has 15Ω reactance at 245 MHz
2. **Ground return path matters**: Any gap creates radiation
3. **Termination matters**: Reflections can corrupt data

Our I2S interface uses:
- Differential signaling (LVDS): Reduces EMI, improves noise immunity
- 100Ω matched traces: No reflections
- Continuous ground plane: Clean return path

### The Master Clock

The DAC needs a master clock (MCLK) to operate its oversampling filters. This clock determines the sample rate:

| MCLK (MHz) | Rate Family | Sample Rates |
|------------|-------------|--------------|
| 22.5792 | 44.1 kHz | 44.1, 88.2, 176.4, 352.8, 705.6 kHz |
| 24.576 | 48 kHz | 48, 96, 192, 384, 768 kHz |

Our dual-OCXO architecture provides both frequencies. The clock multiplexer selects the appropriate oscillator based on the requested sample rate.

Switching takes approximately 10 ms:
1. Mute output (1 ms)
2. Stop I2S clocks
3. Switch MCLK source (1 ms for multiplexer)
4. Wait for OCXO stability (5 ms)
5. Reconfigure DAC dividers
6. Start I2S clocks
7. Unmute (3 ms ramp)

This happens between tracks during gapless playback. If tracks have the same sample rate, no switching occurs.

---

## End of Month Status

**Budget**: $1.89M of $4.0M spent (47.3%)
**Schedule**: On track for Month 9 demo
**Team**: 24 engineers
**Morale**: Tense but determined

**Key Achievements**:
- Rev B main board functional
- Module PCB layout started
- Hot-swap demo ready
- Room correction implemented

**Key Risks**:
1. Module thermal design unvalidated (HIGH)
2. Demo depends on prototype hardware (HIGH)
3. EEPROM edge cases unhandled (MEDIUM)

---

**[Next: Month 9 - The Demo](./09_MONTH_09.md)**
