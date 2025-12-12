# Month 5: Rebuilding

*"The master has failed more times than the beginner has tried."*
*— Stephen McCranie*

---

## Knowledge Transfer

Carlos Mendez had two weeks to transfer six months of architectural knowledge. Aisha Rahman cleared her calendar and sat with him for eight hours a day, absorbing the labyrinthine complexity of Android audio.

"The HAL has three entry points," Carlos explained, whiteboard marker in hand. "adev_open creates the device context. open_output_stream creates a stream for a specific format and route. start/write/stop handle the actual audio data."

He drew boxes and arrows, a taxonomy of callbacks and state machines.

"The direct output path is critical—that's the bit-perfect route for audiophile apps. When UAPP requests 192 kHz output, it passes AUDIO_OUTPUT_FLAG_DIRECT. The HAL checks if we can accommodate that format without resampling."

"What if we can't?"

"We return an error and AudioFlinger falls back to the mixer path. The app will complain, but it won't crash."

"What about DSD?"

Carlos's marker paused. "DSD is... complicated. The HAL doesn't really understand DSD. We wrap it in DoP—DSD over PCM—with marker codes in the padding bits. The HAL thinks it's sending 24-bit PCM at 176.4 kHz when it's actually 64× DSD."

"That's a hack."

"Everything in Android audio is a hack. We're building a precision instrument on top of a framework designed for phone calls."

By the end of week one, Aisha had a 50-page document titled "RichDSP Audio HAL Internals." By the end of week two, she could modify and rebuild the HAL herself.

Carlos left on a Friday, shaking hands and promising to answer emails. The door closed behind him, and the team faced the reality of being one engineer lighter in a race against time.

---

## The Second Prototype

The revised clock PCB arrived on a gray morning in week three. Jin-Soo Park assembled it with surgical precision—tweezers manipulating 0402 capacitors, hot air rework station reflowing QFN packages.

He powered it up at 3 PM. By 4 PM, he had measurements.

"Thirty-one femtoseconds," he announced to the team gathered around his bench. "Better than simulated."

The spectrum analyzer showed a clean noise floor, free of the switching spurs that had plagued version one. The dual OCXO architecture worked exactly as designed.

Sarah Okonkwo studied the display. "Can we see it at different temperatures?"

Jin-Soo looked up. "Why?"

"OCXOs have warm-up characteristics. I want to know how long until we achieve rated jitter."

They set up a thermal chamber—a modified cooler with a heat gun and temperature controller. The board went in at room temperature.

| Temperature | Time | Jitter |
|-------------|------|--------|
| 25°C (start) | 0 min | 31 fs |
| 0°C | 10 min | 89 fs |
| 0°C | 30 min | 42 fs |
| 0°C | 60 min | 35 fs |
| 45°C | 10 min | 38 fs |
| 25°C | 10 min | 32 fs |

"Cold start takes thirty minutes to settle," Jin-Soo observed. "We need a warm-up indicator in the UI."

"Or we keep the oscillators powered in standby," Marcus suggested.

"That's 500 milliwatts each. A watt of continuous draw." Elena shook her head. "Battery life goes from 10 hours to 6."

"Can we duty-cycle them?"

"OCXOs hate duty cycling. The oven takes time to stabilize—that's the whole point."

They debated for an hour, eventually settling on a hybrid approach: keep one oscillator warm for the common sample rate (48 kHz family), power down the other until needed, accept 30-minute warm-up for rate family switching.

It wasn't elegant, but it was acceptable.

---

## Hardware Team Report

### Director of Hardware Engineering: Marcus Chen

**Status**: Clock validation complete. Main board integration pending.

The OCXO investment was correct. We've achieved 31 femtoseconds RMS jitter—a factor of three better than specification. This provides margin for temperature variation, aging, and board-to-board variation.

**Integration Status**

| Subsystem | Prototype Status | Notes |
|-----------|------------------|-------|
| Clock generation | Validated | 31fs jitter achieved |
| I2S routing | Ready for PCB | Simulation complete |
| Module connector | Qualification underway | Mechanical stress testing |
| Power supply | Revision 2 in fab | Push-pull topology |
| Analog section | Breadboard validated | Ready for integration |
| Processor section | Eval board working | Waiting for custom PCB |

**Main Board Schedule**

The main board design is 60% complete. Dmitri is routing the critical paths—clock distribution, I2S to module, analog supplies. The schedule:

- Week 1-2: Complete routing
- Week 3: Design review
- Week 4: Final DRC/DFM checks
- Week 5: Fabrication
- Week 6-7: Assembly
- Week 8: Bring-up

Target for first powered main board: Month 7, Week 2.

---

### Lead PCB Design Engineer: Dmitri Volkov

**Status**: Critical routing in progress

The main board is my most complex design in thirty years. 1,847 components. 8 layers. Three voltage domains. Clock traces measured in millimeters, signal integrity measured in femtoseconds.

**Routing Challenges**

*Challenge 1: Clock Distribution*

The OCXO outputs must reach three destinations—the I2S block, the DAC on the module, and a test point—with matched propagation delay. Different trace lengths create phase offset; a 10mm length difference equals 50 picoseconds of skew.

Solution: Serpentine length matching. Every clock trace is exactly 42mm long, achieved through meandered routing.

```
OCXO ────┬──────[snake]────── I2S_MCLK (42mm)
         │
         ├──────[snake]────── MODULE_MCLK (42mm)
         │
         └──────[snake]────── TEST_MCLK (42mm)
```

*Challenge 2: I2S to Module*

The module connector is at the edge of the board. The I2S signals originate near the center. That's 35mm of transmission line carrying differential signals at up to 49 MHz.

At these frequencies, trace impedance matters. A discontinuity—a via, a bend, a gap in the ground plane—creates reflections that corrupt data.

Solution: 100Ω differential pairs with continuous reference plane. Via fencing on either side. No layer transitions except at carefully impedance-matched via structures.

*Challenge 3: Analog Isolation*

The analog section needs complete isolation from digital noise. But it also needs to connect to the module connector—which carries both analog outputs and digital control.

Solution: Split ground planes with a single-point bridge at the connector:

```
┌─────────────────────────────────────────────────────────┐
│                    DIGITAL DOMAIN                        │
│    ┌─────────┐                         ┌─────────┐      │
│    │Processor│                         │ Clock   │      │
│    │ Section │                         │ Section │      │
│    └─────────┘                         └─────────┘      │
│                                                          │
├──────────────────────┬───────────────────────────────────┤
│        Ground Bridge │ (2mm wide, directly under         │
│        ◄─────────────┤  module connector)                │
├──────────────────────┴───────────────────────────────────┤
│                                                          │
│                    ANALOG DOMAIN                         │
│    ┌─────────┐                         ┌─────────┐      │
│    │  Power  │                         │ Output  │      │
│    │ Section │                         │ Stage   │      │
│    └─────────┘                         └─────────┘      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Progress**

- Layer 1 (top): 90% routed
- Layer 4 (internal signal): 75% routed
- Layer 7 (internal signal): 50% routed
- Layer 8 (bottom): 40% routed

Completion target: End of week 4.

---

### Lead Mechanical Engineer: Robert Tanaka

**Status**: Enclosure design and thermal analysis

I joined the team last week, recruited from a consumer electronics company in Japan. My specialty is thermal management in constrained spaces—exactly what RichDSP needs.

**Enclosure Concept**

The player will use a CNC-machined aluminum unibody, similar to high-end smartphones but larger:

- Dimensions: 130mm × 75mm × 22mm
- Material: 6061-T6 aluminum, anodized finish
- Weight: ~250g

The aluminum serves dual purposes: premium aesthetics and heat dissipation. The output stage generates up to 17W during sustained high-power playback. Without adequate thermal paths, junction temperatures will exceed safe limits within minutes.

**Thermal Analysis (Preliminary)**

Using CFD simulation with 25°C ambient:

| Component | Power | Junction Temp (no sink) | Junction Temp (with heatsink to enclosure) |
|-----------|-------|------------------------|---------------------------------------------|
| ARM SoC | 2W | 78°C | 52°C |
| Output transistors | 17W | 145°C (DANGER) | 85°C |
| Voltage regulators | 3W | 95°C | 62°C |
| DAC | 1W | 65°C | 48°C |

Without thermal management, the output stage would reach 145°C—far above the 125°C absolute maximum. The enclosure heatsinking brings it to a manageable 85°C.

**Thermal Interface Strategy**

```
┌─────────────────────────────────────────────────────────┐
│            Aluminum Enclosure (Top Half)                 │
│                                                          │
│    ┌──────────────────────────────────────────────┐     │
│    │ Thermal Pad (0.5mm, 5 W/mK)                  │     │
│    │     ┌────────────────────────────────────┐   │     │
│    │     │ Copper Heat Spreader (1mm)         │   │     │
│    │     │     ┌───────────────────────────┐  │   │     │
│    │     │     │ Output Stage (Q1-Q8)      │  │   │     │
│    │     │     │ Thermal vias to copper    │  │   │     │
│    │     │     └───────────────────────────┘  │   │     │
│    │     └────────────────────────────────────┘   │     │
│    └──────────────────────────────────────────────┘     │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Module Bay Design**

The hot-swap module bay requires:
- Robust connector (rated for 10,000 cycles)
- Dust sealing (IP52 minimum)
- Secure latching (resistant to accidental removal)
- Aesthetic integration

I'm designing a spring-loaded ejector mechanism with a sliding dust cover. The user presses a button, the module rises 5mm, and can be removed. Insertion is simple push-to-seat.

---

## Software Team Report

### Lead Software Architect: Aisha Rahman

**Status**: HAL architecture stabilization post-departure

Carlos is gone. The HAL remains.

I've spent three weeks internalizing his work, and I have a new appreciation for the complexity we've undertaken. The Android Audio HAL interface looks simple—a handful of function pointers—but the implementation must handle:

- Multiple simultaneous streams (system + music)
- Asynchronous sample rate changes
- Module hot-swap events
- Error recovery
- Power state transitions

**Code Review Findings**

Carlos wrote solid code, but documentation was sparse. I've added inline comments and created an architectural overview:

```
┌──────────────────────────────────────────────────────────┐
│                    RICHDSP HAL ARCHITECTURE              │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─────────────────────┐                                │
│  │  Module Manager     │  ◄── Detects modules, reads    │
│  │  (module_manager.c) │      EEPROM, manages state     │
│  └──────────┬──────────┘                                │
│             │                                            │
│  ┌──────────▼──────────┐                                │
│  │  Device Context     │  ◄── Global HAL state:         │
│  │  (audio_hw.c)       │      current rate, module,     │
│  │                     │      volume, mute              │
│  └──────────┬──────────┘                                │
│             │                                            │
│  ┌──────────▼──────────┐                                │
│  │  Stream Manager     │  ◄── Per-stream state:         │
│  │  (stream_out.c)     │      format, buffer,           │
│  │                     │      playback position         │
│  └──────────┬──────────┘                                │
│             │                                            │
│  ┌──────────▼──────────┐                                │
│  │  DAC Drivers        │  ◄── Per-chip register         │
│  │  (dac/dac_*.c)      │      configuration,            │
│  │                     │      volume tables             │
│  └──────────┬──────────┘                                │
│             │                                            │
│  ┌──────────▼──────────┐                                │
│  │  Clock Manager      │  ◄── Sample rate switching,    │
│  │  (clock/clock_*.c)  │      OCXO selection            │
│  └──────────┬──────────┘                                │
│             │                                            │
│  ┌──────────▼──────────┐                                │
│  │  Kernel Drivers     │  ◄── I2S, I2C, SPI,            │
│  │  (Linux ALSA)       │      platform specifics        │
│  └──────────────────────┘                                │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

**Hiring Status**

We've opened a req for a senior HAL engineer. Until filled, I'm splitting my time between architecture work and HAL development. It's not sustainable, but it's necessary.

---

### DSP Algorithm Engineer: Dr. Wei Zhang

**Status**: EQ engine implementation complete

The parametric EQ engine is ready for integration. Ten bands, each independently configurable:

```c
typedef struct {
    float fc;       // Center frequency (Hz)
    float gain_dB;  // Gain (-12 to +12 dB)
    float Q;        // Quality factor (0.5 to 10)
    int type;       // LOWSHELF, PEAKING, HIGHSHELF
} eq_band_t;

typedef struct {
    eq_band_t bands[10];
    int enabled;
    float preamp_dB;
} eq_config_t;
```

**Implementation Details**

Each band uses a biquad IIR filter in Direct Form II Transposed:

```c
void process_biquad(biquad_state_t *s, float *in, float *out, int n) {
    float b0 = s->coeffs.b0;
    float b1 = s->coeffs.b1;
    float b2 = s->coeffs.b2;
    float a1 = s->coeffs.a1;
    float a2 = s->coeffs.a2;

    float z1 = s->z1;
    float z2 = s->z2;

    for (int i = 0; i < n; i++) {
        float x = in[i];
        float y = b0 * x + z1;
        z1 = b1 * x - a1 * y + z2;
        z2 = b2 * x - a2 * y;
        out[i] = y;
    }

    s->z1 = z1;
    s->z2 = z2;
}
```

**Performance**

On the ARM Cortex-A53 (single core):

| Operation | Samples | Time | Throughput |
|-----------|---------|------|------------|
| 10-band EQ | 256 | 18 µs | 14 million samples/sec |
| 10-band EQ | 1024 | 68 µs | 15 million samples/sec |

At 768 kHz stereo (1.536M samples/sec), EQ consumes 10% of one core. Plenty of headroom for additional processing.

**Coefficient Calculation**

The EQ coefficients update when the user adjusts settings. I've implemented the Audio EQ Cookbook formulas:

For peaking EQ:
```
A  = sqrt(10^(dB_gain/20))
w0 = 2*pi*fc/fs
alpha = sin(w0)/(2*Q)

b0 =   1 + alpha*A
b1 =  -2*cos(w0)
b2 =   1 - alpha*A
a0 =   1 + alpha/A
a1 =  -2*cos(w0)
a2 =   1 - alpha/A

(normalize by dividing all by a0)
```

Updates are atomic—the new coefficients are calculated in a separate buffer, then swapped in during the next block boundary. No clicks, no glitches.

---

## The Budget Reckoning

Victoria Sterling spread the financial summary across the conference table. Red numbers glowed on her laptop screen.

"We've spent $1.15 million in five months. At this rate, we'll exhaust our runway in Month 12."

Marcus studied the breakdown. Engineering salaries were the largest line item—nineteen people at an average of $180,000 fully loaded. Component costs were higher than projected. The board respins had added $180,000 in unplanned expense.

"What's our burn rate going forward?"

"$210,000 per month, assuming no new hires and no more surprises." Victoria laughed without humor. "We both know there will be surprises."

"Can we extend the runway without new funding?"

"Three options. Cut headcount by 30%—delay the schedule by six months minimum. Reduce component quality—lower specifications, higher risk of market rejection. Or raise a Series A."

"What's the Series A look like?"

"I've been talking to Horizon Ventures. They're interested but cautious. They want to see a working prototype before committing."

"Our first integrated prototype is Month 7."

"Then we need to survive until Month 7." Victoria closed her laptop. "I'm cutting contractor budgets by 40%. Travel freeze for non-essential trips. Conference attendance suspended. And everyone takes a 10% salary deferral, recoverable on funding."

The room fell silent.

"Including me," Victoria added. "Including the board. We're all in this together."

---

## Technical Deep Dive: Why PCB Layout Determines Audio Quality

*The hidden art of high-performance board design*

### The Invisible Antennas

Every trace on a PCB is an antenna. It radiates electromagnetic energy and receives it from neighbors. At audio frequencies, these effects are small. At clock frequencies—49 MHz for 768 kHz audio—they dominate.

Consider a simple clock trace:

```
OCXO ────────────────────────────────────────► I2S
          30mm trace, 5mm above ground plane
```

This trace has inductance (~10 nH/cm = 30 nH) and capacitance to ground (~1 pF/cm = 3 pF). It forms a transmission line with characteristic impedance:

```
Z0 = √(L/C) = √(30nH / 3pF) = 100Ω
```

If the source and load impedances don't match 100Ω, reflections occur. A reflection traveling 30mm takes:

```
t = distance / velocity = 0.03m / (2×10^8 m/s) = 150 picoseconds
```

These reflections add to the jitter budget. Multiple reflections compound.

### The Return Current Path

Current flows in loops. When signal current travels from A to B, return current must flow from B to A. In a properly designed board, return current flows directly under the signal trace on an adjacent ground plane—the lowest-inductance path.

```
Signal Layer:    A ──────────────────────────► B
Ground Layer:    A ◄────────────────────────── B
                 (current flows directly under signal)
```

But if the ground plane has a slot or gap:

```
Signal Layer:    A ──────────────────────────► B
Ground Layer:    A ◄─────╲                ╱──── B
                         ╲              ╱
                          ╲   GAP     ╱
                           ╲        ╱
                            ╲──────╱
                 (current must detour around gap)
```

The detoured return current increases loop area. Larger loop = more inductance = more radiated emission = more susceptibility to external noise.

Dmitri's design rule: **Never route signals over ground plane gaps.**

### Crosstalk

Two parallel traces form a coupled pair. Fast edges on one trace induce signals on the other:

```
Aggressor: ────────[rising edge]────────►
           ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─ ─
                    │ (coupling)
           ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─ ─
Victim:    ────────[induced glitch]────►
```

Crosstalk has two components:
- **Backward crosstalk**: Appears at the near end of the victim, proportional to rise time
- **Forward crosstalk**: Appears at the far end, proportional to coupled length

For high-speed digital signals, crosstalk is measured in millivolts. For sensitive analog signals—like DAC outputs at -120 dB—even microvolts matter.

Dmitri's design rule: **Minimum 3× trace spacing between digital and analog. Guard traces on sensitive signals. Never route clock next to analog.**

### The Star Ground

At audio frequencies, impedance between ground points is negligible. At RF frequencies, it's significant. A 10 nH inductance (1 cm of ground trace) at 100 MHz:

```
Z = 2π × f × L = 2π × 100MHz × 10nH = 6.3Ω
```

If 100 mA of digital return current flows through that 6.3Ω impedance, it creates 630 mV of ground bounce. That bounce appears on the analog ground—injecting noise.

The star ground topology forces all return currents to converge at a single point:

```
              Digital Current Return
                      │
                      │
    ┌─────────────────┴─────────────────┐
    │                                   │
    │            STAR POINT             │
    │                                   │
    └─────────────────┬─────────────────┘
                      │
                      │
              Analog Current Return
```

No shared impedance. No ground bounce coupling. The domains are electrically isolated except at DC.

### Why It All Matters

Sarah's analog section achieved 131 dB SNR on a breadboard with laboratory supplies. Maintaining that performance on a production PCB requires:

1. No ground plane violations under signal traces
2. Matched trace lengths for clock distribution
3. Adequate spacing between domains
4. Proper termination at high-speed interfaces
5. Star grounding at the domain boundary

Miss any one requirement, and the noise floor rises. Miss multiple, and the product fails to meet specifications. The difference between a $300 DAP and a $1,500 DAP is often invisible—hidden in the copper layers where only the electrons know.

---

## End of Month Status

**Budget**: $1.15M of $2.5M spent (46%)
**Schedule**: 5 weeks behind (clock redesign impact)
**Team**: 19 engineers (1 HAL position open)
**Morale**: Guarded optimism

**Key Achievements**:
- Clock architecture validated (31fs jitter)
- EQ engine complete
- Thermal management design underway

**Key Risks**:
1. HAL development velocity reduced (HIGH)
2. Budget runway shrinking (HIGH)
3. Main board complexity may cause delays (MEDIUM)

---

**[Next: Month 6 - First Light](./06_MONTH_06.md)**
