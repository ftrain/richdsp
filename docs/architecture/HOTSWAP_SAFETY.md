# RichDSP Hot-Swap Safety Design

## 1. Overview

This document specifies the hot-swap safety mechanisms for the modular DAC system, addressing the critical safety gaps identified in the architecture review. Improper hot-swap handling can damage hardware and create safety hazards.

---

## 2. Hot-Swap Hazards

### 2.1 Failure Modes

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    HOT-SWAP FAILURE MODES                                    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │ ELECTRICAL HAZARDS                                                      ││
│  │                                                                         ││
│  │ 1. INRUSH CURRENT                                                       ││
│  │    - Module capacitors charge instantly when power applied              ││
│  │    - Can draw >10A peak, damaging connector pins                        ││
│  │    - Causes voltage sag on system rails                                 ││
│  │                                                                         ││
│  │ 2. CONTACT BOUNCE                                                       ││
│  │    - Connector pins make/break rapidly during insertion                 ││
│  │    - Can cause arcing at pin contacts                                   ││
│  │    - Creates noise spikes on power and signal rails                     ││
│  │                                                                         ││
│  │ 3. POWER SEQUENCING VIOLATION                                           ││
│  │    - Digital supply before analog can latch-up DAC                      ││
│  │    - Analog negative before positive can damage op-amps                 ││
│  │    - I/O before core can damage SoC                                     ││
│  │                                                                         ││
│  │ 4. SIGNAL INTEGRITY                                                     ││
│  │    - Hot connecting I2S to running system causes clicks/pops            ││
│  │    - Incomplete insertion = intermittent connection                     ││
│  │    - ESD discharge through signal pins                                  ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │ AUDIO HAZARDS                                                           ││
│  │                                                                         ││
│  │ 1. LOUD POPS                                                            ││
│  │    - DC offset during insertion can create dangerous SPL                ││
│  │    - Can damage headphones and hearing                                  ││
│  │                                                                         ││
│  │ 2. SUSTAINED NOISE                                                      ││
│  │    - Unmuted output during configuration = full-scale noise             ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Connector Design for Hot-Swap

### 3.1 Staggered Pin Lengths

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    STAGGERED PIN CONNECTOR DESIGN                            │
│                                                                              │
│  Module insertion direction ──────────────────────────────────────────►     │
│                                                                              │
│  PIN CONTACT SEQUENCE (longer pins contact first):                          │
│                                                                              │
│  Contact │                                                                  │
│  Order   │  Pin Type          Length    Purpose                             │
│  ────────┼─────────────────────────────────────────────────────────────     │
│    1st   │  GROUND            +1.5mm    Establish ground reference first    │
│    2nd   │  POWER_POS (+15V)  +1.0mm    Positive rail second                │
│    3rd   │  POWER_NEG (-15V)  +0.5mm    Negative rail third                 │
│    4th   │  DIGITAL_3V3       +0.25mm   Digital power fourth                │
│    5th   │  ALL SIGNALS       0mm       Signals connect last                │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════   │
│                                                                              │
│  PHYSICAL LAYOUT:                                                           │
│                                                                              │
│              MAIN UNIT SIDE                    MODULE SIDE                   │
│                                                                              │
│       ┌─────────────────────┐          ┌─────────────────────┐              │
│       │  GND ════════════▓▓▓│  ◄────►  │▓▓▓════════════ GND  │              │
│       │  +15V ═══════════▓▓ │  ◄────►  │ ▓▓═══════════ +15V  │              │
│       │  -15V ══════════▓▓  │  ◄────►  │  ▓▓══════════ -15V  │              │
│       │  3V3 ═════════▓▓    │  ◄────►  │    ▓▓═════════ 3V3  │              │
│       │  SIG ════════▓▓     │  ◄────►  │     ▓▓════════ SIG  │              │
│       └─────────────────────┘          └─────────────────────┘              │
│                                                                              │
│  Pin length difference ensures correct sequence during insertion            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Module Detection Pin

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MODULE DETECTION CIRCUIT                                  │
│                                                                              │
│  The MODULE_DETECT pin is the SHORTEST pin in the connector.                │
│  It only makes contact when module is FULLY INSERTED.                       │
│                                                                              │
│  MAIN UNIT:                                                                 │
│                                                                              │
│       VCC_3V3 ────┬────────────────────────────────────────► MODULE_DETECT  │
│                   │                                          (to module)    │
│               ┌───┴───┐                                                     │
│               │ 10kΩ  │  Pull-up resistor                                   │
│               └───┬───┘                                                     │
│                   │                                                         │
│                   ├─────────────────────────────────────────► GPIO_DETECT   │
│                   │                                          (to MCU)       │
│               ┌───┴───┐                                                     │
│               │ 100nF │  Debounce capacitor                                 │
│               └───┬───┘                                                     │
│                   │                                                         │
│                  GND                                                        │
│                                                                              │
│  MODULE:                                                                    │
│                                                                              │
│       MODULE_DETECT ─────────────────────────────────────────► GND          │
│       (from main)        (connected to ground on module)                    │
│                                                                              │
│  LOGIC:                                                                     │
│  • No module: GPIO_DETECT = HIGH (pulled up)                                │
│  • Module inserted: GPIO_DETECT = LOW (grounded through module)             │
│  • RC time constant provides hardware debouncing (~1ms)                     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Hot-Swap State Machine

### 4.1 State Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    HOT-SWAP STATE MACHINE                                    │
│                                                                              │
│                         ┌──────────────────┐                                │
│                         │                  │                                │
│                    ┌────│    NO_MODULE     │◄────────────────────┐          │
│                    │    │                  │                     │          │
│                    │    └────────┬─────────┘                     │          │
│                    │             │                               │          │
│   Module removed   │             │ DETECT pin goes LOW           │          │
│   (DETECT HIGH)    │             │ (module inserted)             │          │
│                    │             ▼                               │          │
│                    │    ┌──────────────────┐                     │          │
│                    │    │                  │                     │          │
│                    │    │    DEBOUNCING    │  Wait 50ms          │          │
│                    │    │                  │  for stable contact │          │
│                    │    └────────┬─────────┘                     │          │
│                    │             │                               │          │
│                    │             │ Debounce complete,            │          │
│                    │             │ DETECT still LOW              │          │
│                    │             ▼                               │          │
│                    │    ┌──────────────────┐                     │          │
│                    │    │                  │                     │          │
│                    │    │  POWER_SEQUENCE  │  Enable rails       │          │
│                    │    │                  │  in correct order   │          │
│                    │    └────────┬─────────┘                     │          │
│                    │             │                               │          │
│                    │             │ All rails stable              │          │
│                    │             │ (power good signals)          │          │
│                    │             ▼                               │          │
│                    │    ┌──────────────────┐                     │          │
│                    │    │                  │                     │          │
│                    │    │   IDENTIFYING    │  Read EEPROM        │          │
│                    │    │                  │  Authenticate       │          │
│                    │    └────────┬─────────┘                     │          │
│                    │             │                               │          │
│                    │             │ Module identified             │          │
│                    │             │                               │          │
│                    │             ▼                               │          │
│                    │    ┌──────────────────┐                     │          │
│                    │    │                  │                     │          │
│                    │    │  CONFIGURING     │  Initialize DAC     │          │
│                    │    │                  │  registers          │          │
│                    │    └────────┬─────────┘                     │          │
│                    │             │                               │          │
│                    │             │ DAC ready                     │          │
│                    │             ▼                               │          │
│                    │    ┌──────────────────┐                     │          │
│                    │    │                  │                     │          │
│                    │    │     UNMUTING     │  Gradual unmute     │          │
│                    │    │                  │  (ramp up)          │          │
│                    │    └────────┬─────────┘                     │          │
│                    │             │                               │          │
│                    │             │ Unmute complete               │          │
│                    │             ▼                               │          │
│                    │    ┌──────────────────┐                     │          │
│                    │    │                  │◄──────────┐         │          │
│                    │    │      READY       │           │         │          │
│                    └───►│                  │───────────┘         │          │
│                         └────────┬─────────┘   DETECT            │          │
│                                  │             glitch            │          │
│                                  │             (< 10ms)          │          │
│                                  │                               │          │
│                                  │ DETECT HIGH                   │          │
│                                  │ (sustained > 10ms)            │          │
│                                  ▼                               │          │
│                         ┌──────────────────┐                     │          │
│                         │                  │                     │          │
│                         │     MUTING       │  Immediate mute     │          │
│                         │                  │  (hard mute)        │          │
│                         └────────┬─────────┘                     │          │
│                                  │                               │          │
│                                  │ Mute confirmed                │          │
│                                  ▼                               │          │
│                         ┌──────────────────┐                     │          │
│                         │                  │                     │          │
│                         │  POWER_DOWN      │  Disable rails      │          │
│                         │                  │  in reverse order   │          │
│                         └────────┬─────────┘                     │          │
│                                  │                               │          │
│                                  │ All rails disabled            │          │
│                                  └───────────────────────────────┘          │
│                                                                              │
│  ERROR PATHS (not shown):                                                   │
│  • EEPROM read fail → ERROR state → retry or warn user                      │
│  • Auth fail → LIMITED_FUNCTION state → warn user                           │
│  • DAC init fail → ERROR state → power down, warn user                      │
│  • Power fail → EMERGENCY_SHUTDOWN → immediate power down                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 State Timing Requirements

| State | Max Duration | Action on Timeout |
|-------|--------------|-------------------|
| DEBOUNCING | 100ms | Return to NO_MODULE |
| POWER_SEQUENCE | 500ms | Power down, ERROR |
| IDENTIFYING | 1000ms | Use generic config |
| CONFIGURING | 500ms | Power down, ERROR |
| UNMUTING | 200ms | Force unmute |
| MUTING | 50ms | Force power down |
| POWER_DOWN | 500ms | Force disable |

---

## 5. Power Sequencing

### 5.1 Power-On Sequence

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    POWER-ON SEQUENCE                                         │
│                                                                              │
│  Time ──────────────────────────────────────────────────────────────────►   │
│                                                                              │
│  t=0ms     t=10ms    t=20ms    t=50ms    t=100ms   t=150ms   t=200ms       │
│    │         │         │         │         │         │         │            │
│    ▼         ▼         ▼         ▼         ▼         ▼         ▼            │
│                                                                              │
│  GND     ═══════════════════════════════════════════════════════════════   │
│  (already connected via long pins)                                          │
│                                                                              │
│  +15V         ┌────────────────────────────────────────────────────────    │
│               │ (soft-start via inrush limiter)                             │
│  ─────────────┘                                                             │
│                                                                              │
│  -15V              ┌───────────────────────────────────────────────────    │
│                    │ (enabled after +15V stable)                            │
│  ──────────────────┘                                                        │
│                                                                              │
│  +3.3V                  ┌──────────────────────────────────────────────    │
│                         │ (enabled after both analog rails stable)          │
│  ───────────────────────┘                                                   │
│                                                                              │
│  I2S_MCLK                         ┌────────────────────────────────────    │
│                                   │ (enabled after digital power stable)    │
│  ─────────────────────────────────┘                                         │
│                                                                              │
│  MUTE                             ┌────────────────────────────────────    │
│  (active low)                     │ (keep muted until DAC configured)       │
│  ═════════════════════════════════┘                                         │
│                                                                              │
│  DAC_OUT                                              ┌────────────────    │
│  (audio)                                              │ (unmute ramp)       │
│  ═════════════════════════════════════════════════════┘                     │
│                                                                              │
│  KEY REQUIREMENTS:                                                          │
│  • +15V must be stable before -15V enabled (prevents op-amp latchup)        │
│  • Analog rails must be stable before digital (DAC requirement)             │
│  • MCLK must be running before DAC initialization                           │
│  • Output remains muted until DAC fully configured                          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Power-Off Sequence

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    POWER-OFF SEQUENCE                                        │
│                                                                              │
│  Time ──────────────────────────────────────────────────────────────────►   │
│                                                                              │
│  t=0ms     t=5ms     t=20ms    t=30ms    t=50ms    t=100ms                  │
│    │         │         │         │         │         │                      │
│    ▼         ▼         ▼         ▼         ▼         ▼                      │
│                                                                              │
│  MUTE     ═══════════════════════════════════════════════════════════      │
│  (active) │ IMMEDIATE MUTE on removal detection                             │
│  ─────────┘                                                                 │
│                                                                              │
│  I2S_MCLK ────────────┐                                                     │
│                       │ (stop clocks after mute)                            │
│                       └═══════════════════════════════════════════════      │
│                                                                              │
│  +3.3V    ────────────────────┐                                             │
│                               │ (disable digital first)                     │
│                               └═════════════════════════════════════        │
│                                                                              │
│  -15V     ────────────────────────────┐                                     │
│                                       │ (negative before positive)          │
│                                       └═════════════════════════════        │
│                                                                              │
│  +15V     ────────────────────────────────────┐                             │
│                                               │ (positive last)             │
│                                               └═════════════════════        │
│                                                                              │
│  GND      ═══════════════════════════════════════════════════════════      │
│  (remains connected until physical removal)                                 │
│                                                                              │
│  KEY REQUIREMENTS:                                                          │
│  • IMMEDIATE mute on removal detect (< 1ms)                                 │
│  • Reverse order of power-on                                                │
│  • Wait for rail discharge before re-insertion allowed                      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Inrush Current Limiting

### 6.1 Inrush Limiter Circuit

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    INRUSH CURRENT LIMITER                                    │
│                                                                              │
│  Without limiting, inrush current = V / ESR of capacitors                   │
│  Example: 15V / 0.1Ω = 150A peak! (will damage connector)                   │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════   │
│                                                                              │
│  DESIGN: Active inrush limiter with soft-start                              │
│                                                                              │
│                          VIN (+18V from SMPS)                               │
│                               │                                              │
│                               │                                              │
│                           ┌───┴───┐                                         │
│                           │       │                                         │
│                           │   Q1  │  P-channel MOSFET (Si7461DP)            │
│                           │       │  Rds(on) = 0.02Ω, Id = 8A               │
│                           └───┬───┘                                         │
│                               │                                              │
│                    ┌──────────┤                                              │
│                    │          │                                              │
│               ┌────┴────┐     │                                              │
│               │ 10kΩ    │     │                                              │
│               └────┬────┘     │                                              │
│                    │          │                                              │
│       ENABLE ──────┼──────────┼─────────────────────────► VOUT (+15V)       │
│       (GPIO)       │          │                          (to module)        │
│                    │          │                                              │
│               ┌────┴────┐ ┌───┴───┐                                         │
│               │ 100nF   │ │ Rsoft │  Soft-start resistor                    │
│               │         │ │ 10Ω   │  (limits di/dt during turn-on)          │
│               └────┬────┘ └───┬───┘                                         │
│                    │          │                                              │
│                   GND        GND                                            │
│                                                                              │
│  OPERATION:                                                                 │
│  1. ENABLE LOW: Q1 off, no power to module                                  │
│  2. ENABLE HIGH: Gate charges through RC (100nF × 10kΩ = 1ms)               │
│  3. Q1 turns on slowly, limiting inrush current                             │
│  4. Peak inrush ≈ 15V / 10Ω = 1.5A (safe for connector)                     │
│                                                                              │
│  CURRENT PROFILE:                                                           │
│                                                                              │
│  I (A)                                                                      │
│    │                                                                        │
│  2 ┤      ╭──╮                                                              │
│    │     ╱    ╲                                                             │
│  1 ┤    ╱      ╲____________________________________                        │
│    │   ╱                                                                    │
│  0 ┤──╱                                                                     │
│    └────────────────────────────────────────────────► t (ms)                │
│       0    1    2    3    4    5                                            │
│                                                                              │
│  Peak current limited to ~1.5A for ~1ms (vs 150A instantaneous)             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 6.2 Power Good Detection

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    POWER GOOD DETECTION                                      │
│                                                                              │
│  Each power rail has a supervisor that signals when stable:                 │
│                                                                              │
│           VIN ────────────────────────────────────────────────► VOUT        │
│                    │                                                        │
│                    │                                                        │
│               ┌────┴────┐                                                   │
│               │         │                                                   │
│               │ TPS3839 │  Voltage supervisor                               │
│               │ (or eq) │  Threshold: 95% of nominal                        │
│               │         │                                                   │
│               └────┬────┘                                                   │
│                    │                                                        │
│                    │                                                        │
│                   PGOOD ────────────────────────────────────► MCU GPIO      │
│                   (open drain, active high with pull-up)                    │
│                                                                              │
│  POWER GOOD LOGIC:                                                          │
│                                                                              │
│  ALL_POWER_GOOD = PGOOD_15V_POS && PGOOD_15V_NEG && PGOOD_3V3              │
│                                                                              │
│  State machine waits for ALL_POWER_GOOD before proceeding to IDENTIFYING    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. ESD Protection

### 7.1 ESD Protection Strategy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ESD PROTECTION                                            │
│                                                                              │
│  Module connectors are exposed to user contact → ESD risk                   │
│                                                                              │
│  PROTECTION LEVEL REQUIRED:                                                 │
│  • IEC 61000-4-2 Level 4: ±15kV air discharge, ±8kV contact                 │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════   │
│                                                                              │
│  PROTECTION COMPONENTS:                                                     │
│                                                                              │
│  1. TVS DIODES ON POWER RAILS                                               │
│                                                                              │
│       VIN ─────────┬─────────────────────────────────────► VOUT             │
│                    │                                                        │
│               ┌────┴────┐                                                   │
│               │  SMBJ   │  TVS diode                                        │
│               │  18A    │  Clamping voltage: 29V                            │
│               │         │  Peak current: 43A                                │
│               └────┬────┘                                                   │
│                    │                                                        │
│                   GND                                                       │
│                                                                              │
│  2. TVS ARRAYS ON SIGNAL LINES                                              │
│                                                                              │
│       I2C_SDA ─────┬─────────────────────────────────────► SDA              │
│       I2C_SCL ─────┼──┬──────────────────────────────────► SCL              │
│                    │  │                                                     │
│               ┌────┴──┴────┐                                                │
│               │  TPD2E009  │  Dual TVS array                                │
│               │            │  <1pF capacitance                              │
│               │            │  ±15kV ESD                                     │
│               └─────┬──────┘                                                │
│                     │                                                       │
│                    GND                                                      │
│                                                                              │
│  3. SERIES RESISTORS ON HIGH-SPEED SIGNALS                                  │
│                                                                              │
│       I2S_MCLK ────/\/\/────────────────────────────────► MCLK              │
│                    33Ω                                                      │
│                    (limits current, provides ESD impedance)                 │
│                                                                              │
│  PLACEMENT:                                                                 │
│  • TVS devices immediately at connector                                     │
│  • <5mm trace length to connector pins                                      │
│  • Wide ground pour around ESD components                                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Mute Control

### 8.1 Multi-Level Mute Strategy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MUTE CONTROL HIERARCHY                                    │
│                                                                              │
│  Level 1: DAC SOFTWARE MUTE                                                 │
│  ─────────────────────────────                                              │
│  • Fastest response (<100µs)                                                │
│  • Implemented via DAC register write                                       │
│  • Ramps output to zero digitally                                           │
│  • Used for: track changes, sample rate switches                            │
│                                                                              │
│  Level 2: ANALOG MUTE (RELAY OR MOSFET)                                     │
│  ───────────────────────────────────────                                    │
│  • Medium response (~1ms)                                                   │
│  • Shorts output to ground or opens signal path                             │
│  • Used for: power on/off sequences, module swap                            │
│                                                                              │
│           Signal ────┬────────○ ○────────────────────► Output               │
│                      │      RELAY                                           │
│                      │       (NC)                                           │
│                  ┌───┴───┐                                                  │
│                  │ 100Ω  │  Bleed resistor                                  │
│                  └───┬───┘  (prevents pop when relay opens)                 │
│                      │                                                      │
│                     GND                                                     │
│                                                                              │
│  Level 3: POWER DISABLE (EMERGENCY)                                         │
│  ──────────────────────────────────                                         │
│  • Last resort (~10ms)                                                      │
│  • Cuts power to entire module                                              │
│  • Used for: hot removal, fault condition                                   │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════   │
│                                                                              │
│  MUTE SEQUENCE ON MODULE REMOVAL:                                           │
│                                                                              │
│  DETECT goes HIGH                                                           │
│        │                                                                    │
│        ├───► LEVEL 1: DAC soft mute (via cached last command)               │
│        │     (may fail if module already disconnected)                      │
│        │                                                                    │
│        ├───► LEVEL 2: Analog mute relay activated                           │
│        │     (guaranteed to work, on main board)                            │
│        │                                                                    │
│        └───► LEVEL 3: Power rails disabled                                  │
│              (ensures no current flows)                                     │
│                                                                              │
│  All three levels activate simultaneously for safety                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 8.2 Pop/Click Prevention

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    POP/CLICK PREVENTION                                      │
│                                                                              │
│  Pops occur when:                                                           │
│  1. DC offset changes rapidly                                               │
│  2. Signal path impedance changes rapidly                                   │
│  3. Power supply voltage changes rapidly                                    │
│                                                                              │
│  MITIGATION STRATEGIES:                                                     │
│                                                                              │
│  1. DC SERVO (removes DC offset)                                            │
│                                                                              │
│       Signal ───────┬───────────────────────────────────► Output            │
│                     │                                                       │
│                     │     ┌─────────┐                                       │
│                     └────►│-        │                                       │
│                           │ Integr  │                                       │
│                     ┌────►│+   OUT  ├───┐                                   │
│                     │     └─────────┘   │                                   │
│                     │                   │                                   │
│                     └───────────────────┘                                   │
│                                                                              │
│       Integrator forces DC offset to zero over ~100ms                       │
│                                                                              │
│  2. SOFT-START RAMP                                                         │
│                                                                              │
│       Volume                                                                │
│       (dB)                                                                  │
│         │                                                                   │
│       0 ┤                    ╭───────────────                               │
│         │                   ╱                                               │
│     -20 ┤                  ╱                                                │
│         │                 ╱                                                 │
│     -40 ┤                ╱                                                  │
│         │               ╱                                                   │
│    -inf ┤──────────────╯                                                    │
│         └────────────────────────────────────────────► t (ms)               │
│              0       50      100     150     200                            │
│                                                                              │
│       Ramp from -inf to 0dB over 200ms                                      │
│                                                                              │
│  3. OUTPUT COUPLING CAPACITOR (optional, degrades bass)                     │
│                                                                              │
│       Signal ───────┤├────────────────────────────────► Output              │
│                    100µF                                                    │
│                    (film)                                                   │
│                                                                              │
│       Blocks DC, but fc = 1/(2π×Zload×C) = 0.5Hz for 32Ω                    │
│       Trade-off: Adds phase shift in bass, large capacitor needed           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 9. Software Implementation

### 9.1 State Machine Code

```c
/* hotswap_manager.c */

#include "hotswap_manager.h"
#include "power_control.h"
#include "mute_control.h"
#include "module_manager.h"

typedef enum {
    STATE_NO_MODULE,
    STATE_DEBOUNCING,
    STATE_POWER_SEQUENCE,
    STATE_IDENTIFYING,
    STATE_CONFIGURING,
    STATE_UNMUTING,
    STATE_READY,
    STATE_MUTING,
    STATE_POWER_DOWN,
    STATE_ERROR,
} hotswap_state_t;

typedef struct {
    hotswap_state_t state;
    uint64_t        state_enter_time;
    uint32_t        debounce_count;
    bool            detect_pin_state;
    module_info_t   module_info;
} hotswap_context_t;

static hotswap_context_t ctx;

/* State timeouts in milliseconds */
static const uint32_t state_timeouts[] = {
    [STATE_NO_MODULE]      = 0,         /* No timeout */
    [STATE_DEBOUNCING]     = 100,
    [STATE_POWER_SEQUENCE] = 500,
    [STATE_IDENTIFYING]    = 1000,
    [STATE_CONFIGURING]    = 500,
    [STATE_UNMUTING]       = 200,
    [STATE_READY]          = 0,         /* No timeout */
    [STATE_MUTING]         = 50,
    [STATE_POWER_DOWN]     = 500,
    [STATE_ERROR]          = 0,         /* No timeout */
};

/* Called from GPIO interrupt */
void hotswap_detect_isr(void)
{
    bool detect = gpio_read(GPIO_MODULE_DETECT);

    /* Module removal takes priority - immediate mute */
    if (detect == HIGH && ctx.state == STATE_READY) {
        /* CRITICAL: Mute immediately */
        mute_control_set(MUTE_ALL, true);
        ctx.state = STATE_MUTING;
        ctx.state_enter_time = get_time_ms();
    }

    ctx.detect_pin_state = detect;
}

/* Called from main loop at 1kHz */
void hotswap_tick(void)
{
    uint64_t now = get_time_ms();
    uint64_t elapsed = now - ctx.state_enter_time;
    bool detect = ctx.detect_pin_state;

    /* Check for timeout */
    if (state_timeouts[ctx.state] > 0 &&
        elapsed > state_timeouts[ctx.state]) {
        handle_timeout();
        return;
    }

    switch (ctx.state) {
    case STATE_NO_MODULE:
        if (detect == LOW) {
            /* Module possibly inserted */
            ctx.state = STATE_DEBOUNCING;
            ctx.state_enter_time = now;
            ctx.debounce_count = 0;
        }
        break;

    case STATE_DEBOUNCING:
        if (detect == LOW) {
            ctx.debounce_count++;
            if (ctx.debounce_count >= 50) {  /* 50ms stable */
                ctx.state = STATE_POWER_SEQUENCE;
                ctx.state_enter_time = now;
                power_sequence_start();
            }
        } else {
            /* Bounced, go back */
            ctx.state = STATE_NO_MODULE;
        }
        break;

    case STATE_POWER_SEQUENCE:
        if (power_sequence_complete()) {
            ctx.state = STATE_IDENTIFYING;
            ctx.state_enter_time = now;
            module_identify_start();
        }
        break;

    case STATE_IDENTIFYING:
        if (module_identify_complete(&ctx.module_info)) {
            ctx.state = STATE_CONFIGURING;
            ctx.state_enter_time = now;
            dac_configure_start(&ctx.module_info);
        }
        break;

    case STATE_CONFIGURING:
        if (dac_configure_complete()) {
            ctx.state = STATE_UNMUTING;
            ctx.state_enter_time = now;
            mute_control_ramp(MUTE_ALL, false, 200);  /* 200ms ramp */
        }
        break;

    case STATE_UNMUTING:
        if (mute_control_ramp_complete()) {
            ctx.state = STATE_READY;
            ctx.state_enter_time = now;
            notify_module_ready(&ctx.module_info);
        }
        break;

    case STATE_READY:
        /* Normal operation */
        if (detect == HIGH) {
            /* Module removed, but ISR should have caught this */
            mute_control_set(MUTE_ALL, true);
            ctx.state = STATE_MUTING;
            ctx.state_enter_time = now;
        }
        break;

    case STATE_MUTING:
        /* Mute already activated in ISR */
        ctx.state = STATE_POWER_DOWN;
        ctx.state_enter_time = now;
        power_sequence_stop();
        break;

    case STATE_POWER_DOWN:
        if (power_sequence_stopped()) {
            ctx.state = STATE_NO_MODULE;
            ctx.state_enter_time = now;
            notify_module_removed();
        }
        break;

    case STATE_ERROR:
        /* Wait for user intervention or module removal */
        if (detect == HIGH) {
            power_sequence_emergency_stop();
            ctx.state = STATE_NO_MODULE;
        }
        break;
    }
}

static void handle_timeout(void)
{
    switch (ctx.state) {
    case STATE_DEBOUNCING:
        ctx.state = STATE_NO_MODULE;
        break;

    case STATE_POWER_SEQUENCE:
    case STATE_CONFIGURING:
        power_sequence_emergency_stop();
        ctx.state = STATE_ERROR;
        notify_error(ERROR_POWER_TIMEOUT);
        break;

    case STATE_IDENTIFYING:
        /* Use generic configuration */
        ctx.module_info.type = MODULE_GENERIC;
        ctx.state = STATE_CONFIGURING;
        dac_configure_start(&ctx.module_info);
        break;

    case STATE_UNMUTING:
        mute_control_set(MUTE_ALL, false);  /* Force unmute */
        ctx.state = STATE_READY;
        break;

    case STATE_MUTING:
    case STATE_POWER_DOWN:
        power_sequence_emergency_stop();
        ctx.state = STATE_NO_MODULE;
        break;

    default:
        break;
    }
}
```

---

## 10. Testing Requirements

### 10.1 Hot-Swap Test Procedures

| Test | Procedure | Pass Criteria |
|------|-----------|---------------|
| **Insertion detection** | Insert module slowly | Detected within 100ms |
| **Removal detection** | Remove module | Muted within 1ms |
| **Inrush current** | Monitor current during insert | <2A peak |
| **Pop test** | Monitor output during insert/remove | <10mV spike |
| **Power sequencing** | Monitor rails with scope | Correct order, <500ms |
| **ESD immunity** | IEC 61000-4-2 discharge to connector | No damage, no reset |
| **Rapid cycling** | Insert/remove 100x | No failures |
| **Partial insertion** | Insert halfway, hold | No damage, error state |
| **Power loss during insert** | Kill power mid-sequence | Safe state on reboot |

### 10.2 Durability Requirements

| Parameter | Requirement |
|-----------|-------------|
| **Insertion cycles** | >500 (product lifetime) |
| **Contact resistance** | <50mΩ after 500 cycles |
| **Mechanical alignment** | ±0.1mm tolerance |
| **Retention force** | 10-20N (secure but removable) |

---

*Document Version: 1.0.0*
*Status: Revised Architecture*
