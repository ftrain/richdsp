# Month 6: First Light

*"The first time a new piece of hardware produces sound, you know if it has soul."*
*— Dr. Sarah Okonkwo*

---

## The Main Board Arrives

The FedEx truck arrived at 7:43 AM, carrying four small boxes from the assembly house in Shenzhen. Inside: the first production-representative main boards for RichDSP.

Dmitri Volkov inspected them with a jeweler's loupe, examining solder joints, via fills, layer alignment. Twenty-three years of PCB experience condensed into a thirty-minute ritual.

"Clean," he pronounced. "Very clean. Better than I expected from expedited manufacturing."

Jin-Soo Park connected the power supply—nervously, given Elena's previous prototype—and measured the current draw. 42 milliamps in standby, exactly as simulated.

By noon, the Linux kernel was booting. By evening, they had I2S signals on the oscilloscope—clean square waves, proper clock relationships, no reflections or glitches.

But no sound.

"The module connector isn't populated," Marcus explained. "We're waiting on the breakout boards for initial testing. They arrive tomorrow."

That night, the board sat on Jin-Soo's bench, LEDs blinking softly, clock oscillators warming, waiting for its first notes.

---

## The First Sound

The breakout board was ugly—a green rectangle with flying wires connecting an AK4497 evaluation module to the main board's 80-pin connector. Nothing about it suggested audio excellence.

Tom Blackwood loaded a test file—a 1 kHz sine wave at -20 dBFS, 44.1 kHz sample rate—and typed the playback command.

The oscilloscope showed... nothing.

"I2S data is transmitting," Jin-Soo confirmed. "DAC is receiving."

"Check the analog output."

Sarah Okonkwo probed the DAC's current output. A tiny sine wave, barely visible. "The DAC is converting. But our I/V stage isn't connected."

The breakout board had bypassed Sarah's carefully designed analog section. They were looking at the DAC's raw current output, milliamps into the oscilloscope's megaohm input impedance.

"We need to connect the main board's analog section."

Another hour of soldering, connecting the DAC outputs to the I/V stage inputs. Another moment of anticipation.

Tom typed the command again.

The oscilloscope displayed a perfect sine wave. 0.997 kHz. -20.1 dBFS. Textbook.

"Let's measure it properly," Sarah said. She connected her Audio Precision analyzer, ran the full test suite, and stared at the numbers.

```
THD+N @ 1kHz, -3dBFS: 0.00041%
SNR (A-weighted): 128.4 dB
Channel separation @ 1kHz: 121 dB
Frequency response @ 20kHz: -0.03 dB
```

Numbers that exceeded specification. Numbers that matched the breadboard results. Numbers that meant the design was real.

Marcus pulled out his phone and recorded a short video—the oscilloscope trace, Sarah's smile, the ungainly pile of boards and wires that represented two years of planning and six months of execution.

"We have audio," he said to the camera. "First light."

Later, after the measurements and the congratulations, they connected headphones. Jin-Soo played his reference track—Keith Jarrett's Köln Concert, a piano recording he'd heard a thousand times.

The opening notes rang out, and the room went silent. Not because the sound was surprising, but because it was right. The piano occupied space between the headphones. The decay of each note lingered exactly as long as it should. The silence between notes was genuinely silent—a black background against which the music floated.

"It has soul," Sarah said softly.

---

## Hardware Team Report

### Director of Hardware Engineering: Marcus Chen

**Status**: Main board Rev A validated. Module interface testing underway.

First light represents a milestone, but not the finish line. The Rev A boards have known issues:

**Rev A Errata**

1. **Clock multiplexer footprint reversed**: Pin 1 indicator placed incorrectly. Reworked manually—production boards will have corrected footprint.

2. **Analog supply undervoltage**: LDO dropout higher than expected, causing -13.8V rail instead of -15V under load. Solution: Replace input capacitor with lower-ESR type.

3. **Module DETECT debounce insufficient**: 1ms debounce causes false triggers on mechanically noisy insertions. Solution: Increase to 10ms in firmware.

4. **Test point inaccessible**: TP47 (I2S_BCLK monitor) placed under component. Relocate in Rev B.

**Module Interface Validation**

We've tested with:
- AK4497 evaluation module (temporary breakout)
- ES9038PRO evaluation module (temporary breakout)
- PCM1792A evaluation module (temporary breakout)

All three DAC types produce audio. Sample rate switching works from 44.1 to 192 kHz. Higher rates await clock distribution validation.

**Rev B Planning**

- Fix errata items 1-4
- Add onboard audio MCU (STM32G4) for real-time control
- Improve module connector EMI shielding
- Add production test points

Target Rev B release: Month 8.

---

### Lead Analog Audio Engineer: Dr. Sarah Okonkwo

**Status**: Audio validation complete. Results exceed specification.

The first integrated measurements validate our design choices:

**Performance Summary (AK4497 module, 1kHz test signal)**

| Parameter | Specification | Measured | Margin |
|-----------|---------------|----------|--------|
| THD+N @ -3dBFS | <0.0005% | 0.00041% | +1.7 dB |
| SNR (A-weighted) | >125 dB | 128.4 dB | +3.4 dB |
| Dynamic range | >130 dB | 131.2 dB | +1.2 dB |
| Crosstalk @ 1kHz | >120 dB | 121 dB | +1 dB |
| IMD (SMPTE) | <0.0006% | 0.00048% | +1.9 dB |

The system achieves our targets with headroom. More importantly, subjective listening confirms the measurements—the soundstage is stable, transients are clean, and the noise floor is genuinely inaudible.

**Concerns**

The current design uses wired connections between the DAC evaluation boards and our analog stage. The production module interface may introduce:

1. **Connector resistance**: 80-pin connector has approximately 20mΩ contact resistance per pin. For current-output DACs, this creates a small but measurable voltage drop.

2. **Crosstalk at connector**: High-density connector places digital and analog pins within 2mm. EMI coupling is possible.

3. **Mechanical reliability**: Hot-swap implies thousands of insertion cycles. We need qualification testing.

**Next Steps**

1. Design first production module (AK4499-based)
2. Qualify connector for audio performance
3. Develop module calibration procedure

---

### Lead Power Electronics Engineer: Elena Vasquez

**Status**: Push-pull converter validated. Thermal performance acceptable.

The revised power supply survived its first week of testing without explosion. Progress.

**Thermal Measurements**

With enclosure mockup, 25°C ambient, sustained 10W output:

| Component | Temperature |
|-----------|-------------|
| Switching FETs | 62°C |
| Transformer | 58°C |
| Output rectifiers | 55°C |
| Analog LDO | 48°C |

All temperatures are within safe margins. The heatsinking to the enclosure works as designed.

**Efficiency**

| Load | Input Power | Output Power | Efficiency |
|------|-------------|--------------|------------|
| 1W | 1.4W | 1.0W | 71% |
| 5W | 6.2W | 5.0W | 81% |
| 10W | 11.8W | 10.0W | 85% |
| 15W | 18.2W | 15.0W | 82% |

Peak efficiency of 85% at 10W matches simulation. The efficiency droop at high power is expected—switching losses dominate.

**Battery Life Projection**

With 4700mAh battery at 3.7V nominal (17.4 Wh):

| Use Case | Power | Runtime |
|----------|-------|---------|
| Idle (screen off) | 0.8W | 22 hours |
| Music (no DSP) | 1.5W | 12 hours |
| Music (EQ active) | 2.0W | 9 hours |
| Music (high power headphones) | 4.0W | 4.5 hours |
| Maximum output | 17W | 1 hour |

Typical usage (mixed playback with occasional DSP) should achieve 8-10 hours. Competitive with existing high-end DAPs.

---

## Software Team Report

### BSP/Embedded Linux Engineer: Tom Blackwood

**Status**: Custom kernel stable. Audio driver development progressing.

The RK3399-based BSP is running on Rev A hardware. Key milestones:

**Kernel Configuration**

```
Linux richdsp-prototype 5.15.89-rt56-richdsp #1 SMP PREEMPT_RT
```

PREEMPT_RT is stable. Worst-case latency on production board:

```
cyclictest --mlockall --priority=99 --interval=200 -D 12h
T: 0 Min: 2 Act: 7 Avg: 5 Max: 38
```

38 microseconds maximum over 12 hours. Better than eval board due to cleaner power supply.

**I2S Driver**

The RK3399 has three I2S interfaces. We use I2S1 for the module connection, configured as master:

```c
static const struct snd_soc_dai_ops richdsp_i2s_ops = {
    .startup = richdsp_i2s_startup,
    .shutdown = richdsp_i2s_shutdown,
    .hw_params = richdsp_i2s_hw_params,
    .set_fmt = richdsp_i2s_set_fmt,
    .set_sysclk = richdsp_i2s_set_sysclk,
    .trigger = richdsp_i2s_trigger,
};
```

The driver supports:
- PCM rates: 44.1 to 768 kHz
- Bit depths: 16, 24, 32
- DSD: DoP mode (native in progress)

**Clock Driver**

Sample rate switching requires coordination between I2S clocks and the OCXO multiplexer:

```c
int richdsp_set_sample_rate(struct richdsp_clock *clk, unsigned int rate) {
    int family = rate_to_family(rate);  // 44.1kHz or 48kHz family

    if (family != clk->current_family) {
        // Switch OCXO
        gpio_set_value(clk->ocxo_sel_gpio, family);

        // Wait for stabilization
        usleep_range(5000, 10000);
    }

    // Set I2S dividers
    return richdsp_i2s_set_dividers(clk->i2s, rate);
}
```

Switching time: <10ms. Inaudible during gapless playback.

---

### Lead Software Architect: Aisha Rahman

**Status**: HAL integration complete. First playback achieved.

The Audio HAL successfully played music through the production hardware today. This is the result of two months of parallel development—writing code for hardware that didn't exist, then integrating in a single intensive week.

**Integration Challenges**

1. **Sample rate negotiation**: AudioFlinger requests rates in a specific order that didn't match our capabilities. Solution: Custom sample rate priority list in audio policy.

2. **Buffer sizing**: Default ALSA buffer (4096 samples) caused underruns at 768 kHz. Solution: Dynamic buffer sizing based on sample rate.

3. **Volume control**: The AK4497 has a digital volume control with 0.5dB steps. Integrating with Android's 0-100 volume scale required mapping tables.

**HAL Status**

| Feature | Status |
|---------|--------|
| Primary output (48kHz) | Complete |
| Direct PCM (44.1-192kHz) | Complete |
| Direct PCM (352.8-768kHz) | Partial (buffer optimization needed) |
| DSD (DoP) | In progress |
| Module detection | Partial (state machine, no hardware) |
| Volume control | Complete |

**New HAL Engineer**

We've hired Priya Nair, formerly of Sony Mobile. She starts next week and will own module detection and DSD support. Finally, sustainable staffing.

---

## The Series A Meeting

Victoria Sterling flew to San Francisco on a Thursday, carrying a briefcase full of data and a prototype board wrapped in anti-static foam.

Horizon Ventures occupied the top floor of a glass tower in SOMA, where venture capitalists decided the fate of companies over espresso and spreadsheets. Three partners sat across the conference table: two in suits, one in a startup-casual fleece.

"We've achieved first light," Victoria began, placing the prototype on the table. "This board produces audio that exceeds our specifications. 128 dB signal-to-noise ratio. 0.0004% distortion. Measurably better than any portable product on the market."

"Measurably," repeated the partner in the fleece. "How does it sound?"

Victoria connected headphones to the prototype and played Keith Jarrett. The partner listened for two minutes, eyes closed, then nodded.

"That's impressive. What's the ask?"

"$2 million for 18% equity. This funds us through production and initial sales."

The partners conferred in low voices. The lead partner spoke.

"Your burn rate is concerning. You've spent $1.2 million in six months—nearly half your seed funding. At that rate, you'll exhaust the new funds in 15 months."

"We're past the major R&D expenses. The clock redesign was costly but one-time. Going forward, we're primarily spending on salaries and component procurement."

"Component procurement. Yes." He pulled out a tablet. "Your BOM shows $430 per unit. At $1,499 retail, with typical margin structures, that's... tight."

"We've identified cost reductions for volume production. $380 per unit at 5,000 units, $340 at 10,000."

"And your competition?"

"The Chord Hugo 2 is $2,195 with inferior specifications. The Sony NW-WM1A is $1,199 but doesn't allow component upgrades. Our modular approach is unique."

The partners excused themselves. Victoria waited, watching San Francisco's skyline blur through the floor-to-ceiling windows.

When they returned, the lead partner was smiling.

"We'll commit $1.5 million for 15% equity, contingent on a working prototype with hot-swap functionality by Month 9."

Victoria did the math. $1.5 million gave them runway through Month 18. It was less than asked, but enough.

"We'll have hot-swap working by Month 8," she said.

They shook hands. Outside, the sun was setting over the bay, painting the water in shades of gold and promise.

---

## Technical Deep Dive: How Digital Becomes Analog

*Inside the delta-sigma DAC*

### The Quantization Problem

Digital audio is a series of numbers—96,000 per second for a 96 kHz file. Each number represents the instantaneous air pressure that the speakers should reproduce.

A 24-bit number can represent 16,777,216 distinct levels. But the actual voltage range is small—perhaps ±5V. The difference between adjacent levels is:

```
LSB = 10V / 16777216 = 0.6 microvolts
```

Building an analog circuit that accurately distinguishes 0.6 microvolt steps is nearly impossible. Resistors drift. Op-amps have offset voltages. Temperature changes everything.

### The Delta-Sigma Solution

Instead of converting the full 24-bit value at once, delta-sigma DACs convert a 1-bit stream at very high speed. Each bit represents only "high" or "low"—a trivial distinction.

The magic is in how that 1-bit stream is generated.

Consider a simple example: converting the value 0.5 to a 1-bit stream:

```
Desired output: 0.5 (half-scale)

Time:  1   2   3   4   5   6   7   8
1-bit: 0   1   0   1   0   1   0   1

Average = 4/8 = 0.5 ✓
```

For 0.75:
```
Time:  1   2   3   4   5   6   7   8
1-bit: 1   1   0   1   1   1   0   1

Average = 6/8 = 0.75 ✓
```

The 1-bit stream's long-term average equals the desired value.

### Noise Shaping

The 1-bit representation introduces quantization error—the difference between the rounded 1-bit output and the true value. In a naive converter, this error appears as broadband noise.

Delta-sigma modulators use feedback to shape this error, pushing it into ultrasonic frequencies where it can be filtered out:

```
Input ─────┐
           │     ┌───────┐      ┌───────────┐
           ├────►│  Σ    │─────►│ Quantizer │──┬──► 1-bit out
           │     │(adder)│      │ (1-bit)   │  │
     ┌─────┤     └───────┘      └───────────┘  │
     │     │           ▲                       │
     │     │           │                       │
     │     │     ┌─────┴─────┐                 │
     │     │     │  z^-1     │◄────────────────┘
     │     │     │(delay)    │
     │     │     └───────────┘
     │     │           │
     │     └───────────┘
     │           (feedback)
     │
(Error spectrum is shaped to high frequencies)
```

The result: in-band noise (20 Hz - 20 kHz) of -120 dB or better, while out-of-band noise may reach -60 dB. A low-pass filter removes the ultrasonic content, leaving pure signal.

### Multi-Bit Output

High-performance DACs like the ES9038PRO use multiple 1-bit streams in parallel, slightly offset in time. This "multi-bit" approach has several advantages:

1. **Reduced clock speed**: Eight parallel bits at 6.144 MHz equals one bit at 49 MHz
2. **Error averaging**: Manufacturing variations in the eight paths cancel statistically
3. **Lower ultrasonic energy**: Less filtering required

The DAC internally interleaves eight delta-sigma modulators:

```
       ┌─────────────────┐
Input ─┤ Delta-Sigma #1  ├──► Current output 1
       └─────────────────┘
       ┌─────────────────┐
Input ─┤ Delta-Sigma #2  ├──► Current output 2
       └─────────────────┘
            ...
       ┌─────────────────┐
Input ─┤ Delta-Sigma #8  ├──► Current output 8
       └─────────────────┘

All eight current outputs sum at the I/V node
```

The summed output averages to the desired voltage, with errors averaging toward zero.

### Why Clock Matters (Again)

The 1-bit stream must be converted at precise, regular intervals. If the clock has jitter, the "average" calculation goes wrong—the DAC integrates noise.

The relationship is direct: 1 picosecond of jitter adds approximately 0.001 dB of noise at 20 kHz. That seems trivial, but professional measurements are made at 0.001 dB resolution. Audiophile reviewers notice.

Our 31 femtosecond clock contributes:
```
Jitter noise = 0.001 dB × (31 / 1000) = 0.00003 dB
```

Immeasurable. Imperceptible. Perfect.

---

## End of Month Status

**Budget**: $1.4M of $2.5M spent (56%) + $1.5M Series A committed
**Schedule**: 3 weeks behind (recovered from 5 weeks)
**Team**: 20 engineers (Priya Nair joining)
**Morale**: High after first light

**Key Achievements**:
- First integrated audio playback
- Performance exceeds specification
- Series A funding secured

**Key Risks**:
1. Hot-swap functionality unproven (HIGH)
2. Module design not started (MEDIUM)
3. Remaining technical debt (LOW)

---

**END OF PHASE 1: FOUNDATION**

*The first six months established the foundation—clock architecture, analog design, power supply, BSP, and HAL. The next six months would test whether that foundation could support a real product.*

---

**[Next: Month 7 - The Module Challenge](./07_MONTH_07.md)**
