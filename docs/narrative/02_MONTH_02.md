# Month 2: First Blood

*"The analog section isn't a circuit. It's a meditation on noise."*
*— Dr. Sarah Okonkwo, Lead Analog Audio Engineer*

---

## The Hire That Changed Everything

Dr. Sarah Okonkwo arrived on a Tuesday, carrying a worn copy of Walt Jung's *Op Amp Applications Handbook* and twenty years of experience converting electrons into music.

She'd spent the last decade at ESS Technology, architecting the analog stages for the Sabre series DACs—the ES9018, ES9028, ES9038. Chips that defined the state of the art. When Marcus pitched her the role over dinner in Milpitas, she listened quietly, asked three questions about the power supply architecture, and accepted on the spot.

"ESS is becoming a features company," she told him. "More channels, more digital processing, more integration. Nobody there wants to talk about the analog anymore. I want to remember why I became an engineer."

Her first day, she spent six hours reading the architecture documents. Her second day, she called a meeting.

---

## The Analog Reckoning

The conference room fell silent as Sarah connected her laptop to the projector. The screen displayed a single block diagram—the signal path from DAC output to headphone jack.

"This," she said, pointing at the diagram, "is not an analog section. It's a sketch on a napkin."

Marcus shifted in his chair. "We've specified the major blocks. I/V conversion, filtering, output stage—"

"You've specified *that blocks exist*. You haven't specified how they work." She advanced to the next slide. "Let's start with the I/V stage. Your spec says 'transimpedance amplifier.' What topology?"

Silence.

"Discrete JFET? Op-amp with feedback resistor? Transformer-based? Each has different noise characteristics, different bandwidth, different linearity."

"We assumed op-amp based," Marcus offered. "Industry standard."

"Which op-amp? The OPA1612 has 1.1 nV/√Hz input noise. The LME49990 has 0.9 nV/√Hz but higher distortion. The AD797 has better PSRR but needs careful compensation." She pulled up a SPICE simulation. "I modeled your signal path with generic components. Here's the noise analysis."

The graph showed a flat line at -122 dB.

"Your target is -125 dB. With generic components, you're already 3 dB short—and this doesn't include power supply noise, PCB coupling, or thermal drift."

Jin-Soo leaned forward. "What do you need?"

"Time. Budget. And the freedom to design this properly." She looked at Victoria Sterling, who had been watching silently from the corner. "I need to specify every component to 0.01% tolerance. I need to prototype each stage independently. And I need to kill the universal I/V stage."

"What do you mean, kill it?" Marcus asked.

"Your architecture shows one I/V topology for all DAC modules. But DACs have different output characteristics." She switched slides again.

```
DAC OUTPUT TYPES:

CURRENT OUTPUT (most high-end):
  - AK4497/AK4499: ±3.5 mA full scale
  - ES9038PRO: ±4.0 mA full scale
  - Requires transimpedance stage (I/V conversion)

VOLTAGE OUTPUT:
  - PCM1792A: 3 Vrms differential
  - Requires only buffering, NO I/V stage

TRANSFORMER COUPLED (rare, vintage):
  - Some R2R designs: Current into transformer primary
  - Requires specific load impedance
```

"If you run a voltage-output DAC through an I/V stage designed for current output, you'll saturate the amplifier. Massive distortion. If you run a current-output DAC into a buffer designed for voltage input, you'll see noise and bandwidth degradation."

"So each module needs its own analog section?"

"Each module *category* needs appropriate interfacing. At minimum, the module EEPROM must specify output type, and the main board needs switchable topology—or the analog section lives entirely on the module."

Victoria spoke for the first time. "What's the cost impact?"

Sarah paused. "If we put premium analog on the main board, add $25-40 to the BOM. If we push analog to the modules, the flagship module alone will cost $150 in components."

"Our module price target is $299 retail. $150 in components—"

"Would make it unprofitable. I know." Sarah closed her laptop. "Welcome to high-end audio."

---

## Hardware Team Report

### Lead Analog Audio Engineer: Dr. Sarah Okonkwo

**Status**: Architecture assessment complete. Critical deficiencies identified.

My first two weeks have confirmed suspicions formed during the interview process. The digital architecture is solid; the analog architecture is dangerously underspecified.

**Immediate Issues**

1. **No I/V Topology Defined**

   Current-output DACs (AK4499, ES9038PRO) require transimpedance conversion. The critical component is the feedback resistor—it sets both gain and noise floor.

   For the AK4499 (±3.5 mA output, 4.5 Vrms target):
   ```
   R_feedback = V_out / I_in = 4.5V / 3.5mA = 1.286 kΩ
   ```

   This resistor's thermal noise contribution:
   ```
   V_noise = √(4 × k × T × R × BW)
           = √(4 × 1.38e-23 × 300 × 1286 × 100000)
           = 1.46 µV RMS
   ```

   With 4.5 Vrms signal, that's -130 dB noise floor from the resistor alone. Acceptable, but no margin. Every other noise source pushes us over budget.

2. **No Filter Topology Defined**

   The DAC's digital filter removes most out-of-band energy, but ultrasonic content remains. An analog reconstruction filter is essential.

   Options:
   - Passive LC: Lowest noise, but impedance-sensitive
   - Active Sallen-Key: Flexible, but op-amp noise adds
   - Multiple feedback (MFB): Better stopband, worse phase

   I recommend a second-order Sallen-Key at 70 kHz cutoff—aggressive enough to remove DAC artifacts, conservative enough to preserve phase response.

3. **No Power Supply Noise Budget**

   Our 125 dB SNR target allows total noise of:
   ```
   V_noise_total = V_signal / 10^(125/20) = 4.5V / 1.78e6 = 2.5 µV RMS
   ```

   The power supply must contribute less than 0.5 µV RMS to maintain headroom. That requires:
   - Post-regulation ripple: <1 mV
   - LDO noise: <1 µV/√Hz
   - PSRR at 100 kHz: >60 dB

   This is achievable only with premium regulators (TPS7A4700, LT3093) and careful PCB layout.

**Recommended Actions**

1. Freeze analog architecture for 2 weeks while I complete detailed design
2. Procure evaluation samples of premium components
3. Build breadboard prototypes of I/V and filter stages
4. Measure, iterate, repeat

**Timeline Impact**: 4-6 weeks delay to analog specification. Hardware prototype pushed from Month 4 to Month 6.

---

### Lead Power Electronics Engineer: Elena Vasquez

**Status**: Power architecture preliminary design

I joined from SpaceX, where power systems could kill astronauts. Audio seems almost quaint by comparison—until you look at the noise specifications.

**Power Architecture Overview**

```
USB-C PD Input (5-20V) ──┬── Battery Charger ──── Li-Po 4700mAh
                         │
                         └── System Power
                               │
              ┌────────────────┼────────────────┐
              │                │                │
         Digital Rail    Analog Rail(+)   Analog Rail(-)
           3.3V/1.8V        +5 to +15V      -5 to -15V
              │                │                │
         ┌────┴────┐      ┌────┴────┐      ┌────┴────┐
         │DCDC Buck│      │Isolated │      │Isolated │
         │ 2A max  │      │ Flyback │      │ Flyback │
         └────┬────┘      └────┬────┘      └────┬────┘
              │                │                │
         ┌────┴────┐      ┌────┴────┐      ┌────┴────┐
         │ LDO     │      │Ultra-low│      │Ultra-low│
         │(standard)      │noise LDO│      │noise LDO│
         └─────────┘      └─────────┘      └─────────┘
```

**The Isolation Challenge**

Digital circuits generate noise—clock edges create broadband EMI, processor activity modulates supply current. This noise couples into analog circuits through shared power supply impedance.

Solution: Galvanic isolation. The analog supplies derive from the battery through a flyback converter with transformer isolation. No copper connection between digital ground and analog ground.

But isolation creates new problems:
- Flyback converters generate switching noise at 200 kHz-2 MHz
- Transformer leakage inductance limits efficiency
- Multiple isolated rails increase complexity and cost

**Noise Budget Analysis**

Sarah's requirement: <0.5 µV RMS noise contribution from power supply.

The flyback converter outputs approximately 10 mV ripple at 500 kHz. After the LDO:

| LDO | Noise Density | Bandwidth | Total Noise | PSRR @ 500kHz |
|-----|---------------|-----------|-------------|---------------|
| TPS7A4700 | 4 µV RMS | DC-100kHz | 4 µV | 40 dB |
| LT3093 | 2.2 µV RMS | DC-100kHz | 2.2 µV | 50 dB |
| ADM7154 | 1.7 µV RMS | DC-100kHz | 1.7 µV | 55 dB |

The ADM7154 looks promising, but 1.7 µV is still above our budget. We need additional filtering—likely a passive LC network between flyback and LDO.

**Cost Impact**

Premium power design adds approximately $20 to BOM:
- Isolated flyback controller: $3
- Transformer: $4
- ADM7154 (x2): $6
- Passive filtering: $3
- Additional PCB area: $4 equivalent

Victoria won't be happy. But physics doesn't negotiate.

---

## Software Team Report

### BSP/Embedded Linux Engineer: Tom Blackwood

**Status**: Kernel evaluation and RT requirements analysis

I've been running Linux on ARM since 2005. Built kernels for everything from Raspberry Pis to surgical robots. This project has a unique challenge: running Android while maintaining hard real-time guarantees for audio.

**The Real-Time Problem**

Android runs on Linux, but stock Linux is not real-time. The kernel can preempt user processes, but kernel code itself runs to completion. If a disk I/O operation takes 50ms, audio can glitch.

Solution: PREEMPT_RT patch set. This converts most kernel spinlocks to priority-inheriting mutexes, allowing even kernel code to be preempted by high-priority tasks.

Current status on our evaluation board (RK3399):
```
# cyclictest --mlockall --priority=99 --interval=200 --distance=0
T: 0 ( 1234) P:99 I:200 C: 100000 Min: 3 Act: 12 Avg: 8 Max: 247
```

Max latency: 247 microseconds. For 44.1 kHz audio with 256-sample buffers:
```
Buffer time = 256 / 44100 = 5.8 ms
```

247 µs is acceptable—but that's on a quiet system. Under load (UI rendering, file I/O), I've seen spikes to 2ms. We need to identify and eliminate latency sources.

**Kernel Configuration Work**

Key settings for audio optimization:
```
CONFIG_PREEMPT_RT=y
CONFIG_NO_HZ_FULL=y          # Tickless operation on audio cores
CONFIG_RCU_BOOST=y           # RCU callback priority boosting
CONFIG_HIGH_RES_TIMERS=y     # Microsecond-resolution timers
CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y  # No frequency scaling
```

I'm also working on CPU affinity—pinning audio threads to dedicated cores that never run UI code.

**Timeline**: BSP bring-up targeting Month 3. Audio driver development begins Month 4.

---

### Android Audio HAL Engineer: Carlos Mendez

**Status**: Week 2 of onboarding

I left Qualcomm for this. Fourteen years building audio HALs for Snapdragon, and I left for a startup that doesn't have working hardware.

My wife thinks I'm having a midlife crisis. Maybe she's right.

**HAL Architecture Planning**

The HAL must present multiple output streams to Android:

```c
// audio_policy_configuration.xml excerpt
<mixPort name="primary_out" role="source">
    <profile format="AUDIO_FORMAT_PCM_24_BIT"
             samplingRates="48000"
             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
</mixPort>

<mixPort name="direct_pcm" role="source"
         flags="AUDIO_OUTPUT_FLAG_DIRECT">
    <profile format="AUDIO_FORMAT_PCM_16_BIT,
                     AUDIO_FORMAT_PCM_24_BIT,
                     AUDIO_FORMAT_PCM_32_BIT"
             samplingRates="44100,48000,88200,96000,
                           176400,192000,352800,384000,
                           705600,768000"
             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
</mixPort>

<mixPort name="dsd_out" role="source"
         flags="AUDIO_OUTPUT_FLAG_DIRECT">
    <profile format="AUDIO_FORMAT_DSD"
             samplingRates="2822400,5644800,11289600,22579200"
             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
</mixPort>
```

The challenge is sample rate switching. When the user plays a 192 kHz file after a 44.1 kHz file, we must:

1. Mute the output
2. Stop the I2S clock
3. Reconfigure the clock generator (different frequency family)
4. Wait for clock stabilization
5. Reconfigure the DAC
6. Restart I2S
7. Unmute

This must happen in <10 ms to avoid audible gaps during gapless playback. The clock architecture is critical—and I'm hearing rumors it might need redesign.

**Concerns**

The module hot-swap requirement scares me. Android's audio framework doesn't expect output devices to appear and disappear during playback. I've seen crashes in AudioFlinger when USB DACs are disconnected. Our internal modules must be more robust.

I need to talk to Jin-Soo about the detection mechanism.

---

## The Budget Meeting

Friday afternoon. Victoria Sterling convened the leadership team in the small conference room that smelled of stale coffee and stress.

"Let's talk numbers," she said, pulling up a spreadsheet. "We budgeted $400K for hardware development. Current burn rate projects $620K."

Marcus started to respond, but Victoria raised a hand.

"I understand there are technical reasons. Sarah's analog redesign, Elena's power supply upgrades, the premium clock options—I've read the proposals." She turned to face them. "What I need to understand is: can we build this product at all with the money we have?"

Silence.

David Park, the CTO, spoke carefully. "We have contingency in the software budget. Kernel and HAL work is coming in under estimate—"

"How under?"

"Twenty percent. About $80K."

"That still leaves us $140K short."

Jin-Soo cleared his throat. "There might be a way to reduce clock costs. I've been analyzing the Si5351 more carefully. With careful PCB design—isolated grounds, dedicated LDO filtering—we might achieve acceptable jitter without switching to OCXO."

Sarah shook her head. "I've worked with Si5351 on ESS evaluation boards. The phase noise is fundamentally limited by the PLL architecture. No amount of filtering fixes that."

"The datasheet says—"

"Datasheets are measured in ideal conditions. Production is different."

"We won't know until we try."

Victoria made a note. "How much does the OCXO solution add?"

"$45 BOM cost. At our projected volumes—" Jin-Soo calculated quickly "—$225K over 5,000 units."

"And if the Si5351 fails?"

"Then we respin the board. Add two months and $150K."

Victoria stared at the numbers. "Let's prototype with Si5351. If it fails, we find more money."

Marcus looked uncomfortable but nodded. Sarah's jaw tightened, but she said nothing.

Some battles aren't won in meetings.

---

## Technical Deep Dive: The I/V Conversion Stage

*Understanding how DACs produce analog signals*

### Why Current Output?

High-performance DACs like the AK4499 and ES9038PRO use current-output architectures. The reason is fundamental to how digital-to-analog conversion works.

A typical delta-sigma DAC contains a current-steering switch array. At each sample, the DAC turns on a specific combination of current sources, summing to the target output level. Current sources are inherently more linear than voltage sources—they maintain constant output regardless of load.

The output looks like this:

```
Inside the DAC:
                 ┌──────┐
                 │I-ref │ (Current source, ~10 µA per bit)
                 └──┬───┘
                    │
              ┌─────┴─────┐
              │  Switch   │ (Controlled by digital input)
              │  Array    │
              └─────┬─────┘
                    │
           I_out = ±3.5 mA (varies with signal)
                    │
              DAC Output Pin
```

### The Transimpedance Amplifier

To convert this current to a voltage, we use a transimpedance amplifier (TIA):

```
             R_feedback (1.3 kΩ)
            ┌────────────┐
            │    ┌───────┤
            │    │       │
    I_in ───┼────┤-  OP  ├─── V_out = I_in × R_feedback
            │    │  AMP  │
            └────┤+      │
                 └───────┘
                    │
                   GND

V_out = -I_in × R_feedback
      = -3.5mA × 1.3kΩ
      = -4.55V (for full-scale positive input)
```

The op-amp maintains its inverting input at virtual ground, forcing all input current through the feedback resistor. The output voltage equals current times resistance—Ohm's law, elegantly applied.

### Noise Analysis

Every component adds noise. In the I/V stage:

1. **Feedback resistor thermal noise**:
   ```
   V_n = √(4kTR × BW) = √(4 × 1.38e-23 × 300 × 1300 × 100000) = 1.47 µV
   ```

2. **Op-amp voltage noise**:
   ```
   For OPA1612: 1.1 nV/√Hz × √100000 = 0.35 µV
   ```

3. **Op-amp current noise**:
   ```
   For OPA1612: 1.7 pA/√Hz × 1300Ω × √100000 = 0.70 µV
   ```

4. **DAC current noise**:
   ```
   Typically ~1 pA/√Hz × 1300Ω × √100000 = 0.41 µV
   ```

Total (RSS): √(1.47² + 0.35² + 0.70² + 0.41²) = **1.70 µV RMS**

With 4.5 Vrms signal: 20 × log10(4.5 / 1.70e-6) = **128 dB SNR**

This meets our 125 dB target with 3 dB margin—but only if everything else is perfect.

### Why Component Selection Matters

That 0.01% tolerance on the feedback resistor isn't about matching left/right channels (though that helps). It's about:

1. **Temperature coefficient**: A cheap resistor might drift 100 ppm/°C. Over 30°C operating range, that's 0.3% gain error—audible as channel imbalance.

2. **Voltage coefficient**: Some resistors change value with applied voltage. At 4.5V across 1.3kΩ, a 1 ppm/V coefficient creates 4.5 ppm nonlinearity—measurable distortion.

3. **Noise index**: Carbon composition resistors generate excess noise (1/f noise). Metal film is better. Vishay Z-foil is best.

Sarah's insistence on premium components isn't audiophile snake oil. It's engineering necessity.

---

**[Next: Month 3 - Growing Pains](./03_MONTH_03.md)**
