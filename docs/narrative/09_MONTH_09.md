# Month 9: The Demo

*"The demo gods are cruel and capricious."*
*— Silicon Valley proverb*

---

## The Night Before

At 11 PM, Marcus Chen sat alone in the lab, running through the demo sequence for the forty-seventh time.

Insert module. Wait for detection. Tap play. Music flows. Remove module. Silence. Reinsert. Music resumes.

Forty-seven times without failure.

He should go home. Get sleep. Be fresh for tomorrow.

Instead, he ran it again. Forty-eight.

The demo board sat under harsh fluorescent lights, its green PCB and silver components exposed—no enclosure, no polish, just raw engineering. Tomorrow, this pile of circuits would determine whether they received $1.5 million to continue or a polite rejection that would end everything.

Forty-nine.

His phone buzzed. A text from Victoria: *"Go home. It works or it doesn't. We can't change anything now."*

He powered down the board, locked the lab, and drove through empty streets. At home, he lay awake, mentally tracing signal paths until exhaustion pulled him under.

---

## The Demo

The Horizon Ventures conference room was deliberately understated—white walls, glass table, expensive chairs. Three partners sat on one side. Victoria and Marcus sat on the other, the demo rig between them.

"Thank you for making the trip," said Michael Torres, the lead partner. "We're looking forward to seeing your progress."

Marcus connected the power supply. The board booted, LEDs blinking through POST. The Android home screen appeared on the 5" display.

"This is our Rev B main board running production-representative firmware," he began. "The platform supports hot-swappable DAC modules—our key differentiator."

He held up the prototype module. "This module contains an AK4497 DAC, discrete analog stage, and output buffer. In production, this will be one of three launch modules."

Marcus inserted the module into the bay. The display flickered.

**MODULE DETECTED: AK4497 Reference**
**Initializing...**
**Ready**

"The system reads the module's EEPROM, identifies the DAC type, and configures the audio path automatically. Total detection time: about 200 milliseconds."

He tapped the music player icon. A waveform appeared—"La Fille aux Cheveux de Lin" by Debussy, 96 kHz/24-bit.

"This is bit-perfect playback at 96 kilohertz, bypassing Android's audio mixer."

He connected headphones to the module's output and passed them to Michael Torres. The partner listened for thirty seconds, eyebrows slightly raised.

"The sound quality is excellent," Torres admitted. "But we've heard good sound before. Show us the hot-swap."

Marcus nodded. This was the moment.

He reached for the module and pulled.

The display went dark.

Not "muted dark." Not "module removed dark." Actually dark. The entire system had crashed.

The room went silent.

Marcus stared at the blank screen, blood draining from his face. Forty-nine successful rehearsals. Forty-nine. And on the fiftieth—

"I apologize," Victoria said smoothly. "Early prototypes occasionally need a reboot. Let's try again."

Marcus pressed the reset button. Nothing happened. The board was completely unresponsive.

He checked the power supply. Connected. He checked the voltage rails with his phone's multimeter app. 3.3V present. 5V present. The board should be running.

"The MCU isn't responding," he said quietly. "I need to investigate."

Michael Torres leaned back. "We have thirty minutes before our next meeting. Take whatever time you need."

Marcus's hands trembled slightly as he connected his laptop to the debug port. The JTAG interface showed the ARM core was running—in a hard fault handler. Somewhere in the millions of lines of code between boot and crash, something had gone wrong.

He checked the system log. The last entry before the crash:

```
[158.432] module: Removal detected, state=ACTIVE
[158.433] audio: Muting output
[158.434] i2c: Transfer timeout on bus 2
[158.435] KERNEL PANIC: Null pointer dereference at 0x00000004
```

I2C transfer timeout. The module removal had interrupted a register read, and the driver didn't handle the failure gracefully.

"I think I know what happened," Marcus said. "The module was removed during an I2C transaction. The driver crashed on timeout."

"Can you fix it?"

Marcus looked at his watch. Twenty-three minutes. A kernel driver fix, recompile, reflash, test.

"Not properly. But I can patch around it."

He modified the I2C driver to return immediately on timeout instead of propagating the error. A hack. A terrible hack that would cause problems later. But it would survive the demo.

Recompile: 4 minutes.
Flash: 2 minutes.
Boot: 45 seconds.

The screen lit up. MODULE DETECTED.

Marcus inserted the module again. Music played. He yanked the module out—hard, faster than before.

The display showed: **MODULE REMOVED - Muted**

No crash.

He reinserted the module.

**MODULE DETECTED: AK4497 Reference**

Music resumed.

Eighteen minutes had passed. The partners had been watching silently.

"May I?" asked Michael Torres, gesturing at the module.

Marcus handed it over. Torres inserted it. Waited. Removed it. Inserted it again. The system handled each transition cleanly.

"Impressive," he said. "Not the demo itself—the debugging. I've seen a lot of founders panic when things go wrong. You diagnosed the problem, implemented a fix, and recovered in under twenty minutes. That tells me something about your team."

He handed the module back.

"We'll fund the full $1.5 million. Congratulations."

---

## The Aftermath

That night, the team gathered at a bar near the warehouse. Drinks flowed. Tensions released.

"To the demo gods," Tom Blackwood raised his glass. "Who tested us and found us worthy."

"To Marcus," Victoria added. "Who didn't panic."

Marcus shook his head. "I panicked. I just panicked productively."

Aisha Rahman sat apart, laptop open, already writing a proper fix for the I2C crash. When Priya asked why she wasn't celebrating, she shrugged.

"The demo worked. But we shipped a kernel panic to investors. That's not how we should operate."

"We recovered."

"This time. What about next time? What about the customer who yanks a module at exactly the wrong moment?"

She pushed the laptop toward Priya. "Look at the crash path. The module driver holds a mutex, then starts an I2C transaction. If the transaction times out while the module is being removed, the driver tries to access freed memory."

```c
// The bug
int module_read_register(struct module_ctx *ctx, uint8_t reg) {
    mutex_lock(&ctx->lock);

    int ret = i2c_smbus_read_byte_data(ctx->i2c, reg);
    if (ret < 0) {
        // On timeout, ctx may have been freed by removal handler
        mutex_unlock(&ctx->lock);  // CRASH: ctx is NULL
        return ret;
    }

    // ...
}
```

"The fix isn't hard. Check ctx before unlocking. But there are probably other places with the same pattern."

Priya nodded slowly. "We should audit the entire driver."

"We should. Monday."

They returned to the celebration, but the shadow of technical debt lingered. The demo had succeeded. The demo had also revealed how close they were to failure.

---

## Hardware Team Report

### Director of Hardware Engineering: Marcus Chen

**Status**: Demo complete. Post-mortem in progress.

The investor demo succeeded, but not cleanly. We need to address both the immediate issue and the systemic problems it revealed.

**Immediate Issue: I2C Timeout Crash**

Root cause: The module removal interrupt fires asynchronously. If it occurs during an I2C transaction, the removal handler frees the module context while the I2C callback still holds a reference.

Fix: Reference counting on module context. The I2C callback increments a reference count; the removal handler waits for the count to reach zero before freeing.

**Systemic Issue: Insufficient Hot-Swap Testing**

We rehearsed the demo sequence exhaustively, but always with clean insertions and removals. We never tested:
- Removal during I2C register access
- Removal during audio buffer fill
- Removal during sample rate change
- Rapid repeated insertion/removal

Action: Create automated hot-swap stress test. Robotic actuator to insert/remove modules at random intervals during all system states.

**Hardware Implications**

The current MODULE_DETECT signal is a simple GPIO. It doesn't indicate *when* in the removal sequence the module is—contact break can occur over several milliseconds as the connector separates.

For Rev C, I'm considering a pre-break contact: a pin that disconnects 5ms before the main connector, giving the system warning of impending removal.

---

### Lead Digital Hardware Engineer: Jin-Soo Park

**Status**: Module PCB layout 80% complete

Despite the demo drama, module development continues on schedule.

**AK4499 Reference Module Layout**

```
Physical dimensions: 65mm × 45mm × 10mm (PCB only)
Layer count: 6
Material: Rogers 4003C (low-loss for audio)

Layer stack:
  1. Top signal (analog + digital partitioned)
  2. Ground (continuous)
  3. Power (split: AVDD, DVDD)
  4. Signal (I2S, control)
  5. Ground (continuous)
  6. Bottom signal (thermal management)
```

Key layout decisions:

1. **DAC placement**: Both AK4499 chips centered, symmetric about module midline
2. **I/V stage**: Located directly adjacent to DAC outputs (minimize trace length)
3. **Output connectors**: Edge-mounted for easy access when inserted
4. **Thermal vias**: 25 vias under each output transistor (0.3mm drill, filled)

**Outstanding Questions**

1. Output connector type: 4.4mm balanced vs. 2.5mm balanced? Different markets prefer different standards.

   *Decision needed by end of week.*

2. EEPROM placement: Onboard vs. socketed? Socketed allows field updates but adds cost.

   *Recommendation: Onboard for production, socketed for prototypes.*

---

## Software Team Report

### BSP/Embedded Linux Engineer: Tom Blackwood

**Status**: Driver audit initiated after demo incident

The I2C crash was a driver bug, but it was also a kernel bug. The Linux kernel should never panic on a driver error—it should kill the offending process and continue.

**Root Cause Analysis**

The RichDSP I2C driver was derived from the upstream RK3399 driver with modifications for our clock requirements. In making those modifications, we inadvertently removed a NULL check that existed for exactly this scenario.

**Upstream:**
```c
if (!ctx || !ctx->i2c) {
    dev_err(dev, "Invalid context\n");
    return -ENODEV;
}
```

**Our version:**
```c
// Check removed to "simplify" code
```

This is a common failure mode: code simplification that removes safety checks. We need better code review practices.

**Driver Audit Results**

| Driver | NULL checks | Error handling | Race conditions | Grade |
|--------|-------------|----------------|-----------------|-------|
| I2C | 23/31 missing | Incomplete | 3 identified | D |
| I2S | 12/15 present | Complete | 0 identified | B |
| Clock | 8/10 present | Incomplete | 1 identified | C |
| Module | 15/22 missing | Incomplete | 2 identified | D |

The I2C and Module drivers need significant hardening before production.

**Action Plan**

1. Week 1: Fix all identified race conditions
2. Week 2: Add missing NULL checks
3. Week 3: Improve error handling (no silent failures)
4. Week 4: Review by external consultant

---

### Senior HAL Engineer: Priya Nair

**Status**: Hot-swap state machine hardening

The demo revealed weaknesses in our state machine. Module removal during ACTIVE state is handled, but removal during transitional states is not.

**State Transition Matrix (Before)**

| Current State | Event | Next State | Notes |
|---------------|-------|------------|-------|
| UNPLUGGED | Insert | DETECTING | |
| DETECTING | Valid EEPROM | INITIALIZING | |
| DETECTING | Invalid EEPROM | ERROR | |
| INITIALIZING | Init complete | READY | |
| READY | Stream opened | ACTIVE | |
| ACTIVE | Remove | UNPLUGGED | |
| ERROR | Remove | UNPLUGGED | |

**Problem**: What happens if module is removed during INITIALIZING?

Current behavior: State machine hangs waiting for init complete signal that never arrives.

**State Transition Matrix (After)**

| Current State | Event | Next State | Notes |
|---------------|-------|------------|-------|
| UNPLUGGED | Insert | DETECTING | |
| DETECTING | Remove | UNPLUGGED | **NEW** |
| DETECTING | Valid EEPROM | INITIALIZING | |
| DETECTING | Invalid EEPROM | ERROR | |
| DETECTING | Timeout (5s) | ERROR | **NEW** |
| INITIALIZING | Remove | UNPLUGGED | **NEW** |
| INITIALIZING | Init complete | READY | |
| INITIALIZING | Timeout (10s) | ERROR | **NEW** |
| READY | Remove | UNPLUGGED | **NEW** |
| READY | Stream opened | ACTIVE | |
| ACTIVE | Remove | UNPLUGGED | Mute first |
| ERROR | Remove | UNPLUGGED | |
| ERROR | Retry | DETECTING | **NEW** |

The updated matrix handles removal from any state and adds timeout protection against stuck states.

---

## The Burnout

Dr. Wei Zhang hadn't slept properly in weeks.

The room correction engine worked. The EQ worked. The sample rate converter worked. But every fix revealed two more bugs, every optimization exposed a performance bottleneck, and every test uncovered an edge case.

He sat at his desk at 2 AM, staring at a convolution artifact that appeared only at 705.6 kHz sample rate—a subtle click at block boundaries that shouldn't exist.

The FFT was correct. The overlap-save implementation was textbook. The gain normalization was accurate to six decimal places.

And yet, click.

He played the test signal again. Silence, music, silence, cli—

Click.

Wei rewound and played it slower, watching the waveform. The click appeared at exactly the block boundary, a transient spike of approximately +12 dB lasting 23 samples.

Twenty-three samples. Not a power of two. That ruled out FFT artifacts.

He searched the codebase for the number 23. Nothing relevant.

He searched for numbers near 23: 22, 24, 21, 25. Nothing.

He stared at the waveform until his eyes burned. The spike was real. The spike had a cause. The cause was somewhere in 15,000 lines of DSP code, hiding.

At 4 AM, he found it.

The overlap-save algorithm saves the final portion of each input block for the next iteration. The save length was calculated as `fft_size - impulse_response_length`. For 705.6 kHz with 65,536-tap filter:

```
fft_size = 131072
ir_length = 65536
save_length = 131072 - 65536 = 65536

But the buffer allocation was:
float overlap_buffer[fft_size / 2];  // 65536 floats

Exactly equal. No problem... except:
```

The code assumed the impulse response was exactly `fft_size / 2`. At 705.6 kHz, rounding in the sample rate calculation made the impulse response 65513 samples—not 65536.

```
save_length = 131072 - 65513 = 65559
buffer_size = 65536

65559 > 65536 → Buffer overflow by 23 samples
```

Twenty-three samples. Corrupting the buffer. Creating the click.

Wei fixed the buffer allocation to use `fft_size` instead of `fft_size / 2`. The click disappeared.

He pushed the commit at 5:17 AM, wrote a three-sentence commit message, and walked to his car. The sunrise painted the sky orange and pink. He didn't notice.

At home, he didn't eat. He set an alarm for noon and collapsed fully clothed on his bed.

The alarm rang. He silenced it. At 3 PM, his phone buzzed with messages from the team. He silenced that too.

At 6 PM, Aisha Rahman knocked on his apartment door. When he didn't answer, she called building security.

They found him still in bed, awake, staring at the ceiling.

"I can't stop thinking about the code," he said. "Even when I'm not at work. Even when I sleep. The buffer overflow was in my dreams."

Aisha sat on the edge of his bed. "When did you last take a day off?"

"I don't remember."

"When did you last eat a real meal?"

Silence.

"Wei. You need help."

---

## Technical Deep Dive: The Perils of Real-Time DSP

*Why audio processing is harder than it looks*

### The Tyranny of the Sample Rate

At 768 kHz stereo, the system must process 1,536,000 samples per second. Each sample has about 650 nanoseconds of "budget" before the next one arrives.

```
Time budget per sample = 1 / 768000 = 1.302 µs
Processing time per sample (10-band EQ) = 0.18 µs
Remaining budget = 1.122 µs (86% headroom)
```

86% headroom seems comfortable. But then add convolution:

```
Convolution (65536 taps, overlap-save) = 0.72 µs per sample
Remaining budget = 0.40 µs (31% headroom)
```

31% headroom means we can tolerate some variation. But add sample rate conversion:

```
SRC (768kHz → 44.1kHz, high quality) = 0.55 µs per output sample
```

Suddenly we're over budget. Something has to give.

### The Block Processing Paradigm

Real-time audio doesn't process one sample at a time. It processes *blocks*—typically 256 to 4096 samples.

Block processing amortizes overhead. Setup costs (function calls, cache warming, branch prediction) happen once per block instead of once per sample.

```
Per-sample processing:
  Call function: 10 ns
  Load coefficients: 5 ns
  Multiply-accumulate: 1 ns
  Store result: 3 ns
  Total: 19 ns × 768,000 = 14.6 ms/sec

Block processing (256 samples):
  Call function: 10 ns (once)
  Load coefficients: 5 ns (once)
  Multiply-accumulate: 1 ns × 256
  Store results: 3 ns × 256
  Total per sample: 4.06 ns × 768,000 = 3.1 ms/sec
```

Block processing is 4.7× more efficient. But it introduces *latency*—the delay between input and output:

```
Latency = block_size / sample_rate
Block size 256 @ 768kHz = 0.33 ms (imperceptible)
Block size 4096 @ 768kHz = 5.3 ms (barely perceptible)
Block size 65536 @ 768kHz = 85 ms (very noticeable)
```

### The Convolution Latency Problem

FIR convolution is inherently latency-inducing. The output at time *t* depends on inputs from time *t - N* through time *t*, where *N* is the filter length.

A 65,536-tap filter at 96 kHz has 680 ms of latency. For music playback, this is acceptable—the music is simply delayed. For live monitoring (e.g., a musician playing through the system), 680 ms is disastrously late.

The overlap-save technique doesn't reduce fundamental latency. It reduces *computational* cost by using FFT, but the delay remains.

Wei's hybrid solution (time-domain early reflections + frequency-domain tail) achieves:
- First 512 samples: 5.3 ms latency (acceptable for monitoring)
- Remaining 65,024 samples: Full latency (masked by early response)

### The Memory Bandwidth Wall

Modern CPUs are fast. Memory is not.

```
ARM Cortex-A53 throughput: 2.4 GFLOPS (theoretical)
DDR4 memory bandwidth: 25 GB/s

For 768kHz stereo float (32-bit):
  Data rate = 768000 × 2 × 4 = 6.1 MB/s (trivial)

For 65536-tap FIR:
  Coefficients = 65536 × 4 = 256 KB
  Working set = input buffer + output buffer + coefficients = ~1 MB
```

1 MB working set doesn't fit in L2 cache (typically 512 KB on A53). Every filter pass requires main memory access, hitting the bandwidth wall.

The FFT-based approach reduces memory access by working in-place:
- Forward FFT: 131072 × 4 bytes × 1 pass
- Complex multiply: 65536 × 8 bytes × 1 pass
- Inverse FFT: 131072 × 4 bytes × 1 pass

Total: ~1.6 MB per block, executed sequentially. The CPU can predict access patterns and prefetch efficiently.

### The Float Point Precision Trap

IEEE 754 single-precision float has 24 bits of mantissa. That's approximately 144 dB of dynamic range—plenty for our 125 dB SNR target.

But floating point arithmetic isn't exact. Small errors accumulate.

Consider the IIR biquad feedback:
```
y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]
```

If `a1 * y[n-1]` produces a rounding error of 1 bit, and this propagates back to future iterations, the error can grow.

For stable filters (poles inside unit circle), errors decay. For filters near the stability boundary, errors can persist.

Wei's Direct Form II Transposed structure minimizes error accumulation:
```
y[n] = b0*x[n] + s1
s1 = b1*x[n] - a1*y[n] + s2
s2 = b2*x[n] - a2*y[n]
```

The state variables `s1` and `s2` are updated with fresh inputs each iteration, preventing error accumulation.

### Why Wei Burned Out

Building real-time DSP systems requires holding multiple complex constraints simultaneously:

1. Computational budget (must complete before next block)
2. Memory budget (must fit in cache)
3. Latency budget (must not exceed perceptible delay)
4. Precision budget (must not accumulate numerical error)
5. Edge case handling (must not glitch at rate transitions)

Each constraint interacts with others. Optimizing for computation often worsens memory access. Reducing latency increases computation. Improving precision requires more bits, which affects memory.

And every sample rate requires different parameters. Every filter length changes the equations. Every combination creates new edge cases.

The 23-sample overflow was invisible in most configurations. It manifested only at 705.6 kHz with maximum filter length—a combination that occurs in perhaps 0.1% of usage scenarios.

Finding it required understanding all five constraint dimensions simultaneously. No single line of code was wrong; the bug emerged from the interaction of correct components.

This is why DSP engineers burn out. The systems are too complex for conscious analysis. Solutions come from intuition built through exhaustion.

---

## End of Month Status

**Budget**: $2.14M of $4.0M spent (53.5%)
**Schedule**: Demo complete. Month 10 targets locked.
**Team**: 24 engineers (1 on medical leave)
**Morale**: Mixed—celebration shadowed by burnout

**Key Achievements**:
- Investor demo successful (with recovery)
- Series A funding confirmed
- Driver audit initiated

**Key Risks**:
1. Team health and sustainability (HIGH)
2. Module production timeline (MEDIUM)
3. Driver stability (MEDIUM)

**Personnel Note**: Wei Zhang is on two weeks' medical leave by order of management. Dr. Yamamoto covering critical DSP issues.

---

**[Next: Month 10 - Recovery](./10_MONTH_10.md)**
