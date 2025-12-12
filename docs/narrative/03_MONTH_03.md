# Month 3: Growing Pains

*"Everyone has a plan until they get punched in the mouth."*
*— Mike Tyson, quoted by James Morrison during supply chain review*

---

## The First Prototype

The evaluation boards arrived on a gray Tuesday morning—four Rockchip RK3399 development platforms, each worth $299 and representing the first tangible progress toward a product.

Tom Blackwood had them running Linux within hours, the kernel booting to a blinking cursor in 3.2 seconds. By evening, he'd cross-compiled the PREEMPT_RT patch set and begun the slow process of identifying and eliminating latency sources.

"We're looking at 150 microseconds worst-case under load," he reported to the software team. "Down from 247. Still not where we need to be."

"What's causing the remaining spikes?" Aisha asked.

"GPU driver. The Mali blob doesn't yield gracefully." He pulled up a trace file, yellow spikes punctuating a mostly-flat line. "Every time Android renders a frame, we see a 50-100 µs hit."

"Can we pin audio to different cores?"

"Already tried. The problem is memory bandwidth. When the GPU is blasting, the ARM cores stall waiting for cache fills." He sighed. "We might need a dedicated audio MCU."

Marcus, listening from the doorway, wrote something in his notebook. Another line item. Another cost increase.

---

## The Recruiter's Call

Sarah Okonkwo was in her lab, oscilloscope probes buried in a prototype I/V stage, when her phone buzzed with a Cupertino area code.

"Dr. Okonkwo? This is Rebecca Chen from Apple's hardware recruiting team."

Sarah muted the oscilloscope and moved to a quieter corner. "I'm not looking."

"We know you just started at RichDSP. But we're building something special. The next generation of spatial audio processing. Your expertise in low-noise analog design—"

"I said I'm not looking."

"The base compensation is $380,000 with a $200,000 signing bonus. RSUs vesting over four years, currently worth approximately $800,000."

Sarah closed her eyes. Her RichDSP salary was $185,000 with 0.5% equity in a company currently worth nothing.

"Send me the details. I'll think about it."

She hung up and stared at the oscilloscope trace—the gentle sine wave that represented months of optimization, decades of knowledge, a career's worth of passion for the art of analog.

Was passion enough?

---

## Hardware Team Report

### Lead Analog Audio Engineer: Dr. Sarah Okonkwo

**Status**: I/V stage breadboard validation complete. Results exceed expectations.

*Attachment: Internal measurement only—do not distribute*

The breadboard I/V stage achieved 131 dB SNR on the audio analyzer—6 dB better than simulation predicted. The key insights:

**Topology Selection**

I chose a discrete JFET input stage cascaded with an OPA1612 gain stage:

```
            ┌─────────────────────────────────────────────┐
            │                                             │
            │         2.2kΩ                               │
    I_in ───┤     ┌────┴────┐                             │
    (DAC)   │     │         │                             │
            │    ─┴─       ─┴─                            │
            │   │   │     │   │                           │
            │   │ J1│     │ J2│  (LSK170 matched pair)    │
            │   │   │     │   │                           │
            │    ─┬─       ─┬─                            │
            │     │         │                             │
            │     └────┬────┘                             │
            │          │                                  │
            │      ┌───┴───┐                              │
            │      │  CCS  │  (Constant current source)   │
            │      └───┬───┘                              │
            │          │                                  │
            │        -15V                                 │
            │                                             │
            │     From JFET stage                         │
            │          │                                  │
            │     ┌────┴────┐                             │
            │     │    ┌────┤                             │
            │     │    │  R │ (590Ω)                      │
            │     │    │  fb│                             │
            │ ────┼────┤-   │                             │
            │     │    │ OP ├───── V_out (±4.5V)          │
            │     └────┤+AMP│                             │
            │          │    │                             │
            │          GND  │                             │
            └─────────────────────────────────────────────┘
```

The JFET stage provides near-zero input impedance (essential for current sources) with lower voltage noise than any op-amp. The OPA1612 second stage handles the voltage gain.

**Key Component Selections**

| Component | Part Number | Specification | Cost |
|-----------|-------------|---------------|------|
| Input JFETs | LSK170B-matched | 0.9 nV/√Hz | $8/pair |
| Feedback resistor | Vishay Z201 | 590Ω, 0.01%, 2ppm/°C | $3.50 |
| Second stage op-amp | OPA1612 | 1.1 nV/√Hz | $4.20 |
| CCS transistor | BF862 | Low noise JFET | $0.85 |

**Measurement Results**

Test conditions: 1 kHz sine, 3.5 mA RMS input current, 100 kHz measurement bandwidth

| Parameter | Target | Measured |
|-----------|--------|----------|
| THD+N @ 1kHz | <0.0005% | 0.00032% |
| SNR (A-weighted) | >125 dB | 131 dB |
| Channel separation | >120 dB | 126 dB |
| Output noise floor | <2.5 µV | 1.1 µV |

These results exceed specification. The analog path is not our limiting factor.

**Concerns**

This breadboard uses laboratory power supplies with <1 µV noise. The production power supply must match this performance or we lose our margin.

Also: I received a recruiting call. I've told no one except Victoria, who matched Apple's base salary. The RSUs remain unmatched, but I'm staying. For now.

---

### Lead Digital Hardware Engineer: Jin-Soo Park

**Status**: Clock characterization underway. Results are... concerning.

I connected the Si5351 evaluation board to our Keysight E5052B signal analyzer. The phase noise measurements don't match the datasheet.

**Datasheet vs. Reality**

| Offset Frequency | Datasheet (dBc/Hz) | Measured (dBc/Hz) |
|------------------|-------------------|-------------------|
| 10 Hz            | -72               | -68               |
| 100 Hz           | -97               | -91               |
| 1 kHz            | -117              | -109              |
| 10 kHz           | -140              | -132              |
| 100 kHz          | -147              | -143              |

The close-in phase noise is 6-8 dB worse than specified. Integrated jitter:

```
Datasheet prediction: 2.8 ps RMS
Measured: 6.2 ps RMS
```

6.2 picoseconds is marginal. It should work, but there's no safety margin. Any degradation in production—temperature variation, power supply noise, board layout—could push us over the edge.

**Options**

1. **Proceed with Si5351**: Hope that careful PCB design and filtering keeps us within spec. Risk: high.

2. **Add VCXO + PLL cleanup**: Use Si5351 to lock a low-jitter VCXO. Adds $12 to BOM. Risk: medium.

3. **Switch to dual OCXO**: Guaranteed performance. Adds $45 to BOM. Risk: low.

I've asked Marcus for guidance. He said we'll review at the Month 4 architecture meeting.

**Other Progress**

- I2S interface routing study complete. 50Ω differential pairs, 5mm trace length matching.
- EEPROM specification v1.1 released. Added DAC_OUTPUT_TYPE field per Sarah's requirement.
- Module connector stress testing scheduled for Week 2.

---

### Lead PCB Design Engineer: Dmitri Volkov

**Status**: Stackup design and component placement planning

I've been designing audio PCBs since the Soviet Union. This one is among the most challenging.

**Layer Stackup**

```
Layer 1: Top signal (analog + digital separated)
Layer 2: Ground plane (solid, no splits under signal traces)
Layer 3: Power planes (analog and digital isolated)
Layer 4: Internal signal (clock routing, I2S)
Layer 5: Power planes (module interface)
Layer 6: Ground plane (solid)
Layer 7: Internal signal (control buses)
Layer 8: Bottom signal (connectors, test points)

Total: 8 layers
Thickness: 1.6mm
Material: Isola 370HR (low-Dk, low-loss)
```

**Critical Routing Rules**

1. **Clock signals**: 50Ω single-ended, maximum 3mm length variation between related signals
2. **I2S to module**: Differential 100Ω, 5mm max skew, continuous ground return path
3. **Analog signals**: Minimum 5mm clearance from digital, guard traces on both sides
4. **Power**: Separate analog and digital ground planes, single-point connection at star ground

**Grounding Architecture**

```
                      ┌─────────────────────────┐
                      │   Analog Ground Plane   │
                      │   (Module side)         │
                      └───────────┬─────────────┘
                                  │
                              Star Point
                              (Single via)
                                  │
                      ┌───────────┴─────────────┐
                      │   Digital Ground Plane  │
                      │   (Processor side)      │
                      └─────────────────────────┘
```

The star ground is critical. Without it, return currents from the digital section couple noise into analog. With it, we maintain >80 dB isolation between domains.

**Concerns**

The 80-pin module connector presents challenges. High pin density means tight routing and limited ground pins. I've requested 3D models from Hirose to verify clearances.

---

## Software Team Report

### Android Audio HAL Engineer: Carlos Mendez

**Status**: HAL skeleton complete. Integration testing blocked on hardware.

I've written 2,000 lines of code for hardware that doesn't exist. Welcome to embedded development.

**HAL Implementation Progress**

```c
// audio_hw.c - main HAL entry point
static int adev_open(const hw_module_t *module, const char *name,
                     hw_device_t **device)
{
    struct richdsp_audio_device *adev;

    adev = calloc(1, sizeof(struct richdsp_audio_device));
    if (!adev) return -ENOMEM;

    adev->hw_device.common.tag = HARDWARE_DEVICE_TAG;
    adev->hw_device.common.version = AUDIO_DEVICE_API_VERSION_3_0;
    adev->hw_device.common.module = (hw_module_t *)module;
    adev->hw_device.common.close = adev_close;

    adev->hw_device.init_check = adev_init_check;
    adev->hw_device.set_voice_volume = adev_set_voice_volume;
    adev->hw_device.set_master_volume = adev_set_master_volume;
    adev->hw_device.get_master_volume = adev_get_master_volume;
    adev->hw_device.set_mode = adev_set_mode;
    adev->hw_device.set_mic_mute = adev_set_mic_mute;
    adev->hw_device.get_mic_mute = adev_get_mic_mute;
    adev->hw_device.set_parameters = adev_set_parameters;
    adev->hw_device.get_parameters = adev_get_parameters;
    adev->hw_device.get_input_buffer_size = adev_get_input_buffer_size;
    adev->hw_device.open_output_stream = adev_open_output_stream;
    adev->hw_device.close_output_stream = adev_close_output_stream;
    adev->hw_device.open_input_stream = adev_open_input_stream;
    adev->hw_device.close_input_stream = adev_close_input_stream;
    adev->hw_device.dump = adev_dump;

    // Initialize module detection thread
    pthread_create(&adev->module_detect_thread, NULL,
                   module_detect_loop, adev);

    *device = &adev->hw_device.common;
    return 0;
}
```

**Module Detection State Machine**

The hot-swap requirement means the HAL must handle modules appearing and disappearing at any time:

```
                    ┌──────────────┐
                    │  UNPLUGGED   │
                    └──────┬───────┘
                           │ MODULE_DETECT goes low
                           ▼
                    ┌──────────────┐
                    │   DETECTED   │
                    └──────┬───────┘
                           │ Read EEPROM magic
                           ▼
                    ┌──────────────┐
          ┌─────────│ IDENTIFYING  │─────────┐
          │         └──────────────┘         │
          │ Valid EEPROM                     │ Invalid/timeout
          ▼                                  ▼
   ┌──────────────┐                   ┌──────────────┐
   │CONFIG_LOADING│                   │    ERROR     │
   └──────┬───────┘                   └──────────────┘
          │ DAC initialized
          ▼
   ┌──────────────┐
   │    READY     │
   └──────┬───────┘
          │ Audio stream opened
          ▼
   ┌──────────────┐
   │    ACTIVE    │
   └──────────────┘
```

**Blocking Issues**

1. No I2C driver for module EEPROM access
2. No I2S driver for audio data
3. No clock driver for sample rate switching
4. No hardware to test against

I'm writing unit tests with mock objects. It feels like building a ship in a bottle.

---

### DSP Algorithm Engineer: Dr. Wei Zhang

**Status**: Algorithm prototyping in MATLAB

I joined from Stanford's CCRMA (Center for Computer Research in Music and Acoustics) two weeks ago. My dissertation was on perceptually-motivated audio filtering—making DSP sound good rather than merely measure well.

**Parametric EQ Design**

The spec calls for 10-band parametric EQ. Each band requires:
- Center frequency: 20 Hz - 20 kHz
- Q factor: 0.5 - 10
- Gain: ±12 dB

I'm implementing biquad IIR filters in Direct Form II Transposed:

```
y[n] = b0*x[n] + s1
s1 = b1*x[n] + a1*y[n] + s2
s2 = b2*x[n] + a2*y[n]
```

This form minimizes numerical error in fixed-point implementations. Even though we're targeting floating-point initially, designing for fixed-point keeps future options open.

**FIR Convolution for Room Correction**

The spec mentions "up to 65,536 taps." For a 96 kHz sample rate:

```
Filter length = 65536 / 96000 = 0.68 seconds impulse response
```

This is enough for meaningful room correction. But convolution at this length requires optimization:

**Time-domain (naive):** 65536 multiplies per sample × 96000 samples/sec = 6.3 billion ops/sec

**Frequency-domain (overlap-save):** FFT of 131072 points × 96000/65536 passes/sec = ~50 million ops/sec

The frequency-domain approach is 100× more efficient but introduces latency equal to the block size. For 65536 taps at 96 kHz, that's 340 ms—unacceptable for live monitoring.

**Proposed Solution**: Hybrid architecture
- First 512 taps: Time-domain FIR (immediate response)
- Remaining taps: FFT convolution (high-efficiency tail)

This achieves <6 ms latency while maintaining full impulse response length.

---

## The Supply Chain Meeting

James Morrison, VP of Operations, had spent thirty years watching promising products die in the gap between design and manufacturing. He'd developed a sixth sense for trouble, and it was screaming.

"Let's talk about the AKM situation," he said, pulling up a news article on the conference room display.

**FIRE AT AKM SEMICONDUCTOR FACTORY DISRUPTS AUDIO DAC SUPPLY**
*October 2020 - A fire at AKM's Nobeoka plant has halted production of premium audio DACs...*

"That was three years ago," Marcus said. "They've rebuilt."

"They've rebuilt with reduced capacity. Lead times for AK4499 are currently 52 weeks." James let that sink in. "A year. For our flagship DAC."

"We're also supporting ESS. The 9038PRO is available."

"ESS has their own allocation issues. And their pricing just increased 15%." James flipped to a spreadsheet. "I've been modeling scenarios. If we want to launch in 18 months with 5,000 units, we need to place DAC orders within the next 60 days."

Victoria Sterling looked up from her phone. "How much?"

"$180,000 for DAC silicon alone. Non-refundable."

"We haven't even validated the prototype."

"By the time we validate, the lead time pushes our launch to Month 30."

The room fell silent. This was the startup death spiral—you needed to commit money to hit schedule, but committing money to an unvalidated design was gambling.

"What if we ordered a smaller quantity?" Marcus asked.

"We could do 2,000 units. $72,000. But our per-unit cost goes up 20%, and if we succeed, we hit allocation limits trying to scale."

Victoria made a note. "What's your recommendation?"

James sighed. "Order the 5,000 DAC lot. Accept the risk. But simultaneously—and this is critical—develop a fallback design using the TI PCM1792. It's half the performance, but it's in stock."

"A lesser product."

"A product that exists."

Victoria looked around the table. "We order the AKM. And we start the TI fallback." She closed her notebook. "Parallel development. Welcome to hardware."

---

## Technical Deep Dive: Understanding DAC Architectures

*Why some chips cost $2 and others cost $200*

### The Delta-Sigma Principle

Modern high-performance DACs use delta-sigma modulation. Instead of converting each sample directly to an analog level (as older R2R designs do), they:

1. **Oversample** the input by 64x-256x
2. **Noise-shape** quantization error into ultrasonic frequencies
3. **Low-pass filter** the output to remove shaped noise

The result is exceptional in-band performance—120+ dB SNR—from a relatively simple analog circuit.

### Inside the ES9038PRO

The ESS Sabre ES9038PRO contains eight delta-sigma modulators operating in parallel. Each modulator outputs a 1-bit stream at 50 MHz. These streams are combined with careful timing to average out non-idealities:

```
Modulator 1 ──┐
Modulator 2 ──┤
Modulator 3 ──┤
Modulator 4 ──┼── Current Summing ── Analog Output
Modulator 5 ──┤
Modulator 6 ──┤
Modulator 7 ──┤
Modulator 8 ──┘
```

The current outputs sum to approximately 4 mA full-scale. Small timing differences between modulators create intermodulation products, which ESS mitigates through proprietary calibration.

### Inside the AK4499

The AKM AK4499 takes a different approach—a current-segment architecture with 256 matched current sources:

```
Digital Input → Thermometer Decoder → 256 Current Switches → Summed Output
```

Each switch contributes 1/256 of the full-scale current. Matching between switches is critical; a 0.1% mismatch creates -60 dB spurious tones. AKM achieves better than 0.01% matching through laser trimming.

The result is claimed 128 dB SNR—among the highest in the industry.

### The Voltage-Output Alternative: PCM1792

Texas Instruments' PCM1792 uses an internal I/V stage and outputs voltage directly:

```
Delta-Sigma Core → Internal I/V → Internal Filter → Voltage Output
```

This simplifies external circuitry but limits ultimate performance. The internal op-amps and resistors can't match the quality of optimized external components.

Typical specs:
- SNR: 127 dB
- THD+N: 0.0005%
- Output: 3.5 Vrms

Good. But not the best. The question is whether "good" is good enough for our customers.

### Why We Support Multiple DAC Types

Different listeners prefer different sound signatures:

- **AKM** chips are known for warmth and musicality
- **ESS** chips offer clinical precision and detail
- **R2R** designs provide a vintage, organic character
- **TI** chips balance performance and practicality

By supporting all four architectures, RichDSP lets customers choose their preference. The modular design isn't just a technical feature—it's a philosophical statement about audio subjectivity.

---

## End of Month Status

**Budget**: $620K of $2.5M spent (24.8%)
**Schedule**: On track, but warning signs emerging
**Team**: 18 of projected 25 engineers hired
**Morale**: High, but first conflicts appearing

**Key Risks**:
1. Clock jitter margin inadequate (MEDIUM)
2. Component lead times threatening schedule (HIGH)
3. Key personnel retention uncertain (MEDIUM)

---

**[Next: Month 4 - The Breaking Point](./04_MONTH_04.md)**
