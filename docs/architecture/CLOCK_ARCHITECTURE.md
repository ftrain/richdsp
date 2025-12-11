# RichDSP Clock Architecture

## 1. Overview

The clock subsystem is critical to achieving the target jitter specification of <100fs. This document specifies a dual-OCXO architecture replacing the original Si5351-based design.

### 1.1 Why Si5351 Was Rejected

| Parameter | Si5351C | Requirement | Verdict |
|-----------|---------|-------------|---------|
| Phase jitter | 300-500fs typical | <100fs | ❌ FAIL |
| Phase noise @ 1kHz | -100 dBc/Hz | <-130 dBc/Hz | ❌ FAIL |
| PLL settling time | 10-100ms | <1ms | ❌ FAIL |
| Cost | $2-3 | N/A | ✅ |

**Conclusion**: Si5351 is unsuitable for high-end audio. PLL-based synthesis introduces excessive jitter.

---

## 2. Dual-OCXO Architecture

### 2.1 Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CLOCK SUBSYSTEM                                      │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                    PRIMARY CLOCK SOURCES                                │ │
│  │                                                                         │ │
│  │   ┌─────────────────────┐         ┌─────────────────────┐              │ │
│  │   │  OCXO #1            │         │  OCXO #2            │              │ │
│  │   │  22.5792 MHz        │         │  24.576 MHz         │              │ │
│  │   │  (44.1k family)     │         │  (48k family)       │              │ │
│  │   │                     │         │                     │              │ │
│  │   │  Crystek CVHD-950   │         │  Crystek CVHD-950   │              │ │
│  │   │  <25fs jitter       │         │  <25fs jitter       │              │ │
│  │   │  ±0.5ppm stability  │         │  ±0.5ppm stability  │              │ │
│  │   └──────────┬──────────┘         └──────────┬──────────┘              │ │
│  │              │                               │                          │ │
│  │              │ MCLK_44K                      │ MCLK_48K                 │ │
│  │              │                               │                          │ │
│  └──────────────┼───────────────────────────────┼──────────────────────────┘ │
│                 │                               │                            │
│  ┌──────────────▼───────────────────────────────▼──────────────────────────┐ │
│  │                    CLOCK MULTIPLEXER                                    │ │
│  │                                                                         │ │
│  │   ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │   │                    SY89545U                                     │  │ │
│  │   │              Ultra-Low Jitter 2:1 Mux                           │  │ │
│  │   │                   (<20fs additive)                              │  │ │
│  │   │                                                                 │  │ │
│  │   │   MCLK_44K ──►┌─────┐                                           │  │ │
│  │   │               │     │                                           │  │ │
│  │   │               │ MUX ├──► MCLK_OUT                               │  │ │
│  │   │               │     │                                           │  │ │
│  │   │   MCLK_48K ──►└─────┘                                           │  │ │
│  │   │                  ▲                                              │  │ │
│  │   │                  │ SEL (GPIO from MCU)                          │  │ │
│  │   └──────────────────┼──────────────────────────────────────────────┘  │ │
│  └──────────────────────┼─────────────────────────────────────────────────┘ │
│                         │                                                    │
│  ┌──────────────────────▼─────────────────────────────────────────────────┐ │
│  │                    CLOCK DISTRIBUTION                                   │ │
│  │                                                                         │ │
│  │   ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │   │                  CDCLVD1208                                     │  │ │
│  │   │           Ultra-Low Jitter Clock Buffer/Fanout                  │  │ │
│  │   │                  (<15fs additive)                               │  │ │
│  │   │                                                                 │  │ │
│  │   │   MCLK_OUT ──►┌────────┐                                        │  │ │
│  │   │               │        ├──► MCLK_I2S (to I2S controller)        │  │ │
│  │   │               │ FANOUT ├──► MCLK_DAC (to module connector)      │  │ │
│  │   │               │        ├──► MCLK_MON (to jitter monitor)        │  │ │
│  │   │               └────────┘                                        │  │ │
│  │   └─────────────────────────────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                    CLOCK CONTROL (MCU)                                  │ │
│  │                                                                         │ │
│  │   • Clock family selection (GPIO → MUX SEL)                             │ │
│  │   • OCXO enable/disable (power saving)                                  │ │
│  │   • Jitter monitoring (optional ADC input)                              │ │
│  │   • Temperature compensation (I2C to OCXO VCTRL)                        │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Component Selection

#### Primary Oscillators

| Parameter | Crystek CVHD-950 | NDK NZ2520SD | Alternative |
|-----------|------------------|--------------|-------------|
| **Type** | VCXO (oven-less) | TCXO | |
| **Jitter (12kHz-20MHz)** | <25fs | <50fs | |
| **Phase noise @ 10Hz** | -105 dBc/Hz | -95 dBc/Hz | |
| **Phase noise @ 1kHz** | -140 dBc/Hz | -130 dBc/Hz | |
| **Stability** | ±0.5ppm | ±0.5ppm | |
| **Voltage control** | Yes (±8ppm) | No | |
| **Power** | 60mW | 15mW | |
| **Cost** | ~$15-20 | ~$8-12 | |
| **Package** | 7x5mm | 2.5x2.0mm | |

**Recommendation**: Crystek CVHD-950 for flagship, NDK NZ2520SD for cost-optimized variant.

#### Clock Mux

| Parameter | SY89545U | CDCUN1208 |
|-----------|----------|-----------|
| **Additive jitter** | <20fs | <30fs |
| **Propagation delay** | 350ps | 500ps |
| **Supply** | 3.3V | 3.3V |
| **Cost** | ~$3 | ~$2 |

#### Clock Fanout

| Parameter | CDCLVD1208 | LMK00101 |
|-----------|------------|----------|
| **Outputs** | 8 LVDS | 1 LVCMOS |
| **Additive jitter** | <15fs | <50fs |
| **Cost** | ~$4 | ~$1 |

### 2.3 Jitter Budget

```
Source                          Jitter Contribution
─────────────────────────────────────────────────────
OCXO (Crystek CVHD-950)         25 fs (RMS)
Clock Mux (SY89545U)            20 fs (RMS)
Fanout Buffer (CDCLVD1208)      15 fs (RMS)
PCB trace (matched length)       5 fs (RMS)
─────────────────────────────────────────────────────
RSS Total                       35 fs (RMS)  ✅ <100fs target
```

---

## 3. Sample Rate to Clock Mapping

### 3.1 Supported Rates

| Sample Rate | Clock Family | MCLK | MCLK/Fs Ratio |
|-------------|--------------|------|---------------|
| 44,100 Hz | 44.1k | 22.5792 MHz | 512x |
| 48,000 Hz | 48k | 24.576 MHz | 512x |
| 88,200 Hz | 44.1k | 22.5792 MHz | 256x |
| 96,000 Hz | 48k | 24.576 MHz | 256x |
| 176,400 Hz | 44.1k | 22.5792 MHz | 128x |
| 192,000 Hz | 48k | 24.576 MHz | 128x |
| 352,800 Hz | 44.1k | 22.5792 MHz | 64x |
| 384,000 Hz | 48k | 24.576 MHz | 64x |
| 705,600 Hz | 44.1k | 22.5792 MHz | 32x |
| 768,000 Hz | 48k | 24.576 MHz | 32x |

### 3.2 DSD Rates

| DSD Rate | Clock Family | MCLK | Notes |
|----------|--------------|------|-------|
| DSD64 (2.8224 MHz) | 44.1k | 22.5792 MHz | MCLK = 8x DSD |
| DSD128 (5.6448 MHz) | 44.1k | 22.5792 MHz | MCLK = 4x DSD |
| DSD256 (11.2896 MHz) | 44.1k | 22.5792 MHz | MCLK = 2x DSD |
| DSD512 (22.5792 MHz) | 44.1k | 22.5792 MHz | MCLK = 1x DSD |

**Note**: All DSD rates are in the 44.1k family. DSD512 requires MCLK = DSD clock.

---

## 4. Clock Switching Procedure

### 4.1 Glitch-Free Switching

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    CLOCK SWITCHING STATE MACHINE                          │
│                                                                           │
│    ┌─────────┐     rate change      ┌─────────┐                          │
│    │ PLAYING │ ──────request──────► │  MUTE   │                          │
│    └─────────┘                       └────┬────┘                          │
│         ▲                                 │                               │
│         │                                 │ mute confirmed                │
│         │                                 ▼                               │
│         │                           ┌─────────┐                          │
│         │                           │  STOP   │                          │
│         │                           │   I2S   │                          │
│         │                           └────┬────┘                          │
│         │                                 │                               │
│         │                                 │ I2S stopped                   │
│         │                                 ▼                               │
│         │                           ┌─────────┐                          │
│         │                           │ SWITCH  │                          │
│         │                           │  CLOCK  │                          │
│         │                           └────┬────┘                          │
│         │                                 │                               │
│         │                                 │ new clock stable (1ms)        │
│         │                                 ▼                               │
│         │                           ┌─────────┐                          │
│         │                           │ CONFIG  │                          │
│         │                           │   DAC   │                          │
│         │                           └────┬────┘                          │
│         │                                 │                               │
│         │                                 │ DAC ready                     │
│         │                                 ▼                               │
│         │                           ┌─────────┐                          │
│         │                           │  START  │                          │
│         │                           │   I2S   │                          │
│         │                           └────┬────┘                          │
│         │                                 │                               │
│         │                                 │ I2S running                   │
│         │                                 ▼                               │
│         │                           ┌─────────┐                          │
│         │                           │ UNMUTE  │                          │
│         │                           └────┬────┘                          │
│         │                                 │                               │
│         └─────────────────────────────────┘                               │
│                                                                           │
│   Total switching time: <10ms (inaudible gap)                            │
└──────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Switching Timeline

| Step | Duration | Action |
|------|----------|--------|
| 1 | 0-1ms | Soft mute (ramp to zero) |
| 2 | 1-2ms | Stop I2S clocks |
| 3 | 2-3ms | Switch clock mux |
| 4 | 3-4ms | Wait for clock stability |
| 5 | 4-6ms | Update DAC registers |
| 6 | 6-7ms | Start I2S clocks |
| 7 | 7-10ms | Soft unmute (ramp from zero) |

**Total**: <10ms - imperceptible during track changes.

---

## 5. Hardware Implementation

### 5.1 Schematic (Simplified)

```
                    VCC_3V3_ANA (filtered)
                         │
                    ┌────┴────┐
                    │  FERRITE │
                    │  BEAD    │
                    └────┬────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
     ┌────┴────┐    ┌────┴────┐    ┌────┴────┐
     │ 10µF    │    │ 100nF   │    │ 100nF   │
     │ X5R     │    │ C0G     │    │ C0G     │
     └────┬────┘    └────┬────┘    └────┬────┘
          │              │              │
          └──────────────┼──────────────┘
                         │
            ┌────────────┴────────────┐
            │                         │
       ┌────┴────┐               ┌────┴────┐
       │         │               │         │
       │  OCXO   │               │  OCXO   │
       │ 22.5792 │               │ 24.576  │
       │  MHz    │               │  MHz    │
       │         │               │         │
       └────┬────┘               └────┬────┘
            │ OUT                     │ OUT
            │                         │
            │    ┌───────────────┐    │
            └───►│ IN0           │◄───┘
                 │               │
                 │   SY89545U    │
                 │    2:1 MUX    │
                 │               │
            ┌───►│ SEL      OUT  ├───┬──────────────────────┐
            │    └───────────────┘   │                      │
            │                        │                      │
       CLK_SEL                       │                      │
       (GPIO)                        │                      │
                                     │                      │
                         ┌───────────┴───────────┐          │
                         │                       │          │
                         │     CDCLVD1208        │          │
                         │    Clock Fanout       │          │
                         │                       │          │
                         │  OUT0: MCLK_I2S      ─┼──► To SoC I2S
                         │  OUT1: MCLK_DAC      ─┼──► To Module Connector
                         │  OUT2: MCLK_SPARE    ─┼──► Test Point
                         │                       │
                         └───────────────────────┘
```

### 5.2 PCB Layout Guidelines

1. **Placement**: OCXOs and clock mux within 10mm of each other
2. **Routing**: 50Ω controlled impedance traces
3. **Length matching**: All MCLK outputs matched to ±0.5mm
4. **Ground plane**: Unbroken beneath clock section
5. **Isolation**: Keep away from SMPS, digital noise sources
6. **Shielding**: Optional EMI shield can over clock section

### 5.3 Power Supply

```
VCC_5V ──►┌────────────┐     ┌────────────┐
          │  TPS7A4700 │────►│  Ferrite   │──► VCC_3V3_CLK
          │  3.3V LDO  │     │  + LC      │    (Clock-only rail)
          │  <5µVrms   │     │  Filter    │
          └────────────┘     └────────────┘

Noise budget:
- LDO output: 5µVrms
- Post-filter: <1µVrms
- PSRR of OCXO: >60dB
- Effective supply noise: <0.001µVrms at oscillator
```

---

## 6. Software Interface

### 6.1 Clock Manager API

```c
/* clock_manager.h */

typedef enum {
    CLOCK_FAMILY_44K,   /* 22.5792 MHz base */
    CLOCK_FAMILY_48K,   /* 24.576 MHz base */
} clock_family_t;

typedef struct {
    clock_family_t current_family;
    uint32_t       current_rate;
    bool           ocxo_44k_enabled;
    bool           ocxo_48k_enabled;
    uint64_t       switch_count;
    uint64_t       last_switch_us;
} clock_state_t;

/* Initialize clock subsystem */
int clock_init(void);

/* Get current clock state */
int clock_get_state(clock_state_t *state);

/* Switch to clock family for given sample rate */
/* Returns 0 on success, -EBUSY if switch in progress */
int clock_set_rate(uint32_t sample_rate);

/* Get clock family for a sample rate */
clock_family_t clock_get_family(uint32_t sample_rate);

/* Power management */
int clock_enter_low_power(void);  /* Disable unused OCXO */
int clock_exit_low_power(void);   /* Enable both OCXOs */
```

### 6.2 Driver Implementation

```c
/* clock_manager.c */

#include "clock_manager.h"
#include <linux/gpio.h>
#include <linux/delay.h>

#define GPIO_CLK_SEL      45    /* Clock mux select */
#define GPIO_OCXO_44K_EN  46    /* 44.1k OCXO enable */
#define GPIO_OCXO_48K_EN  47    /* 48k OCXO enable */

#define CLOCK_SWITCH_DELAY_US  1000  /* 1ms for clock stability */

static clock_state_t g_clock_state = {
    .current_family = CLOCK_FAMILY_48K,
    .current_rate = 48000,
    .ocxo_44k_enabled = true,
    .ocxo_48k_enabled = true,
};

static DEFINE_MUTEX(clock_mutex);

clock_family_t clock_get_family(uint32_t sample_rate)
{
    switch (sample_rate) {
    case 44100:
    case 88200:
    case 176400:
    case 352800:
    case 705600:
    case 2822400:   /* DSD64 */
    case 5644800:   /* DSD128 */
    case 11289600:  /* DSD256 */
    case 22579200:  /* DSD512 */
        return CLOCK_FAMILY_44K;

    case 48000:
    case 96000:
    case 192000:
    case 384000:
    case 768000:
    default:
        return CLOCK_FAMILY_48K;
    }
}

int clock_set_rate(uint32_t sample_rate)
{
    clock_family_t target_family = clock_get_family(sample_rate);
    int ret = 0;

    mutex_lock(&clock_mutex);

    if (target_family == g_clock_state.current_family) {
        /* Same family, just update rate */
        g_clock_state.current_rate = sample_rate;
        goto out;
    }

    /* Switch clock family */
    pr_info("clock: switching from %s to %s for %u Hz\n",
            g_clock_state.current_family == CLOCK_FAMILY_44K ? "44.1k" : "48k",
            target_family == CLOCK_FAMILY_44K ? "44.1k" : "48k",
            sample_rate);

    /* Set mux select GPIO */
    gpio_set_value(GPIO_CLK_SEL,
                   target_family == CLOCK_FAMILY_44K ? 0 : 1);

    /* Wait for clock to stabilize */
    usleep_range(CLOCK_SWITCH_DELAY_US, CLOCK_SWITCH_DELAY_US + 100);

    /* Update state */
    g_clock_state.current_family = target_family;
    g_clock_state.current_rate = sample_rate;
    g_clock_state.switch_count++;
    g_clock_state.last_switch_us = ktime_get_ns() / 1000;

out:
    mutex_unlock(&clock_mutex);
    return ret;
}

int clock_enter_low_power(void)
{
    mutex_lock(&clock_mutex);

    /* Disable the unused OCXO to save ~60mW */
    if (g_clock_state.current_family == CLOCK_FAMILY_44K) {
        gpio_set_value(GPIO_OCXO_48K_EN, 0);
        g_clock_state.ocxo_48k_enabled = false;
    } else {
        gpio_set_value(GPIO_OCXO_44K_EN, 0);
        g_clock_state.ocxo_44k_enabled = false;
    }

    mutex_unlock(&clock_mutex);
    return 0;
}

int clock_exit_low_power(void)
{
    mutex_lock(&clock_mutex);

    /* Re-enable both OCXOs */
    gpio_set_value(GPIO_OCXO_44K_EN, 1);
    gpio_set_value(GPIO_OCXO_48K_EN, 1);
    g_clock_state.ocxo_44k_enabled = true;
    g_clock_state.ocxo_48k_enabled = true;

    /* Wait for OCXO warm-up */
    msleep(50);

    mutex_unlock(&clock_mutex);
    return 0;
}
```

---

## 7. Cost Analysis

### 7.1 Flagship Configuration

| Component | Part Number | Qty | Unit Cost | Total |
|-----------|-------------|-----|-----------|-------|
| OCXO 22.5792 MHz | Crystek CVHD-950 | 1 | $18.00 | $18.00 |
| OCXO 24.576 MHz | Crystek CVHD-950 | 1 | $18.00 | $18.00 |
| Clock Mux | SY89545U | 1 | $3.00 | $3.00 |
| Clock Fanout | CDCLVD1208 | 1 | $4.00 | $4.00 |
| LDO (clock rail) | TPS7A4700 | 1 | $3.50 | $3.50 |
| Passives | Various | - | $2.00 | $2.00 |
| **Total** | | | | **$48.50** |

### 7.2 Cost-Optimized Configuration

| Component | Part Number | Qty | Unit Cost | Total |
|-----------|-------------|-----|-----------|-------|
| TCXO 22.5792 MHz | NDK NZ2520SD | 1 | $10.00 | $10.00 |
| TCXO 24.576 MHz | NDK NZ2520SD | 1 | $10.00 | $10.00 |
| Clock Mux | CDCUN1208 | 1 | $2.00 | $2.00 |
| LDO (clock rail) | TPS7A4700 | 1 | $3.50 | $3.50 |
| Passives | Various | - | $1.50 | $1.50 |
| **Total** | | | | **$27.00** |

**Trade-off**: Cost-optimized achieves ~50fs jitter (vs 35fs flagship) - still excellent.

---

## 8. Validation

### 8.1 Jitter Measurement

**Equipment Required**:
- Audio Precision APx555 with jitter analysis
- Or: Stanford Research SR785 spectrum analyzer

**Test Procedure**:
1. Configure system for 44.1kHz playback
2. Measure J-Test signal through analog output
3. Record jitter sidebands at ±229Hz, ±1kHz
4. Calculate total jitter from sideband levels

**Pass Criteria**:
- Total jitter < 100fs RMS (12kHz - 20MHz integration)
- No spurious sidebands > -120dB relative to carrier

### 8.2 Clock Accuracy

**Test Procedure**:
1. Measure MCLK frequency with frequency counter
2. Record over temperature range (0°C to 50°C)

**Pass Criteria**:
- Frequency accuracy: ±0.5ppm at 25°C
- Stability over temperature: ±2ppm total

---

*Document Version: 1.0.0*
*Status: Revised Architecture*
