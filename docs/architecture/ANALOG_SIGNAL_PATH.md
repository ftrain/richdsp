# RichDSP Analog Signal Path Design

## 1. Overview

This document specifies the complete analog signal path for each supported DAC type, addressing the critical gap identified in the architecture review. The analog section is where audio quality is won or lost.

---

## 2. Signal Path Architecture

### 2.1 Generic Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ANALOG SIGNAL PATH (per channel)                          │
│                                                                              │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐   │
│  │   DAC   │───►│   I/V   │───►│   LPF   │───►│ VOLUME  │───►│ OUTPUT  │   │
│  │  OUTPUT │    │  STAGE  │    │         │    │ CONTROL │    │  STAGE  │   │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘   │
│       │              │              │              │              │         │
│       │              │              │              │              │         │
│   Current or     Convert to    Remove HF      Attenuate      Buffer for   │
│   Voltage out    Voltage       aliasing       signal         headphone/   │
│                                                               line out     │
│                                                                             │
│  CRITICAL DESIGN POINTS:                                                    │
│  • I/V stage dominates THD for current-output DACs                         │
│  • LPF must not add phase distortion in audio band                         │
│  • Volume control: analog preferred for bit-perfect path                   │
│  • Output stage: high current, low impedance, low distortion               │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 DAC Output Types

| DAC | Output Type | I/V Stage Required |
|-----|-------------|-------------------|
| AK4497 | Current | Yes (±3.5mA full scale) |
| AK4499 | Current | Yes (±3.9mA full scale) |
| ES9038PRO | Current | Yes (±4.9mA full scale) |
| PCM1792A | Voltage | No (7.8Vpp differential) |
| AD1955 | Current | Yes (±4.7mA full scale) |
| R2R Discrete | Voltage | No (varies) |

---

## 3. Per-DAC Signal Path Designs

### 3.1 AKM AK4497 / AK4499 Module

#### Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    AK4497/AK4499 ANALOG PATH                                 │
│                                                                              │
│                         V+ (+5V or +15V)                                    │
│                              │                                               │
│  ┌─────────┐           ┌────┴────┐           ┌─────────┐                   │
│  │ AK4497  │  IOUT+    │         │           │         │                   │
│  │         ├──────────►│   I/V   │──────────►│  Post   │──► To Volume      │
│  │         │           │  Stage  │           │  Filter │                   │
│  │         │  IOUT-    │  (OPA)  │           │  (LPF)  │                   │
│  │         ├──────────►│         │           │         │                   │
│  └─────────┘           └────┬────┘           └─────────┘                   │
│                              │                                               │
│                         V- (-5V or -15V)                                    │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════   │
│                                                                              │
│  I/V STAGE DETAIL (Discrete + Op-amp hybrid):                               │
│                                                                              │
│                    V+ ────┬──────────────────────┬───── V+                  │
│                           │                      │                          │
│                       ┌───┴───┐              ┌───┴───┐                      │
│                       │  Rf   │              │  Rf   │                      │
│                       │ 470Ω  │              │ 470Ω  │                      │
│                       │±0.01% │              │±0.01% │                      │
│                       └───┬───┘              └───┬───┘                      │
│                           │                      │                          │
│       IOUT+ ──────────────┼──────────────────────┼───────── VOUT+          │
│                           │     ┌─────────┐      │                          │
│                           └────►│-        │◄─────┘                          │
│                                 │ OPA1612 │                                 │
│                           ┌────►│+        │◄─────┐                          │
│                           │     └─────────┘      │                          │
│       IOUT- ──────────────┼──────────────────────┼───────── VOUT-          │
│                           │                      │                          │
│                       ┌───┴───┐              ┌───┴───┐                      │
│                       │  Rf   │              │  Rf   │                      │
│                       │ 470Ω  │              │ 470Ω  │                      │
│                       │±0.01% │              │±0.01% │                      │
│                       └───┬───┘              └───┴───┘                      │
│                           │                      │                          │
│                    V- ────┴──────────────────────┴───── V-                  │
│                                                                              │
│  OUTPUT: VOUT = IOUT × Rf = ±3.5mA × 470Ω = ±1.645V                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Component Selection

| Component | Value | Part Number | Notes |
|-----------|-------|-------------|-------|
| **Rf (I/V resistor)** | 470Ω ±0.01% | Vishay Z-foil VPR221Z | Ultra-low TC (0.2ppm/°C) |
| **I/V Op-amp** | - | TI OPA1612 | 1.1nV/√Hz, 0.00001% THD |
| **Alternative** | - | AD797 | Lower noise, higher power |
| **Bypass caps** | 100nF C0G + 10µF X7R | Various | Close to op-amp pins |
| **Power resistors** | 10Ω | Vishay MMA | Power supply decoupling |

#### Performance Targets (AK4497)

| Parameter | Target | Notes |
|-----------|--------|-------|
| THD+N | <0.0004% | At 1kHz, 0dBFS |
| SNR | >123dB | A-weighted |
| Output voltage | 2.0Vrms | Single-ended |
| Output impedance | <1Ω | Before output buffer |

### 3.2 ESS ES9038PRO Module

#### Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ES9038PRO ANALOG PATH                                     │
│                                                                              │
│  ES9038PRO has 8 DAC channels that can be configured as:                    │
│  • 8-channel mode (8 SE outputs)                                            │
│  • 4-channel mode (4 balanced pairs)                                        │
│  • 2-channel mode (2 balanced, 4 paralleled per channel) ◄── RECOMMENDED   │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════   │
│                                                                              │
│  2-CHANNEL CONFIGURATION (8 outputs paralleled to 2):                       │
│                                                                              │
│            ┌───────────────────────────────────────────────────────────┐    │
│            │                    ES9038PRO                              │    │
│            │                                                           │    │
│            │  OUT1+ ─┬─► ┌─────┐                                       │    │
│            │  OUT2+ ─┼──►│     │                                       │    │
│            │  OUT3+ ─┼──►│ SUM │──► I/V Stage ──► LPF ──► L+          │    │
│            │  OUT4+ ─┴──►│     │                                       │    │
│            │             └─────┘                                       │    │
│            │                                                           │    │
│            │  OUT1- ─┬─► ┌─────┐                                       │    │
│            │  OUT2- ─┼──►│     │                                       │    │
│            │  OUT3- ─┼──►│ SUM │──► I/V Stage ──► LPF ──► L-          │    │
│            │  OUT4- ─┴──►│     │                                       │    │
│            │             └─────┘                                       │    │
│            │                                                           │    │
│            │  (Similar for R+/R- using OUT5-8)                         │    │
│            │                                                           │    │
│            └───────────────────────────────────────────────────────────┘    │
│                                                                              │
│  BENEFITS OF PARALLELING:                                                   │
│  • 6dB improvement in SNR (√4 = 2x voltage, noise uncorrelated)            │
│  • Lower output impedance                                                   │
│  • Higher output current capability                                         │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════   │
│                                                                              │
│  I/V STAGE (for ES9038PRO):                                                 │
│                                                                              │
│           V+ ────────────────┬──────────────────────────────── V+           │
│                              │                                               │
│                          ┌───┴───┐                                          │
│                          │  Rf   │                                          │
│                          │ 590Ω  │  (optimized for ES9038 output)           │
│                          └───┬───┘                                          │
│                              │                                               │
│      IOUT (summed) ──────────┼─────────────────────────────── VOUT          │
│                              │     ┌─────────┐                              │
│                              └────►│-   OUT  │──────┐                       │
│                                    │ OPA1656 │      │                       │
│                              ┌────►│+        │      │                       │
│                              │     └─────────┘      │                       │
│                              │                      │                       │
│                          ┌───┴───┐              ┌───┴───┐                   │
│                          │ 100Ω  │              │ 100Ω  │                   │
│                          └───┬───┘              └───┬───┘                   │
│                              │                      │                       │
│           V- ────────────────┴──────────────────────┴──────── V-            │
│                                                                              │
│  NOTE: ES9038PRO benefits from lower noise op-amp due to very high SNR     │
│  OPA1656: 2.2nV/√Hz, THD: 0.000035%                                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Component Selection (ES9038PRO)

| Component | Value | Part Number | Notes |
|-----------|-------|-------------|-------|
| **Rf (I/V resistor)** | 590Ω ±0.1% | Vishay TNPW | Precision thin film |
| **I/V Op-amp** | - | TI OPA1656 | Ultra-low distortion |
| **Alternative** | - | OPA1612 | Lower noise |
| **Summing resistors** | 10Ω ±1% | Various | For paralleled outputs |

#### Performance Targets (ES9038PRO)

| Parameter | Target | Notes |
|-----------|--------|-------|
| THD+N | <0.00015% | At 1kHz, 0dBFS |
| SNR | >130dB | A-weighted, 8ch paralleled |
| Dynamic range | >134dB | |
| Output voltage | 4.0Vrms | Balanced |

### 3.3 TI PCM1792A Module

#### Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PCM1792A ANALOG PATH                                      │
│                                                                              │
│  PCM1792A has VOLTAGE OUTPUT - no I/V stage required!                       │
│                                                                              │
│  OUTPUT: 7.8Vpp differential (2.76Vrms) at 0dBFS                            │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════   │
│                                                                              │
│           ┌─────────────────────────────────────────────────────────┐       │
│           │                    PCM1792A                             │       │
│           │                                                         │       │
│           │  VOUTL+ ───────►┌─────────┐                             │       │
│           │                 │  Diff   │                             │       │
│           │  VOUTL- ───────►│  to SE  │──► LPF ──► Volume ──► OUT  │       │
│           │                 │  (opt)  │                             │       │
│           │                 └─────────┘                             │       │
│           │                                                         │       │
│           │  (Similar for Right channel)                            │       │
│           │                                                         │       │
│           └─────────────────────────────────────────────────────────┘       │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════   │
│                                                                              │
│  SIMPLIFIED PATH (voltage output DAC):                                      │
│                                                                              │
│   PCM1792A     Low-pass      Optional        Output                         │
│   VOUT+ ──────►Filter ──────►Diff Amp ──────►Buffer ──────► OUT+            │
│                                                                              │
│                                                                              │
│  POST-DAC LOW-PASS FILTER (required for all DACs):                          │
│                                                                              │
│                    ┌─────────────────────────────────────────────────┐      │
│                    │        2nd Order Sallen-Key LPF                 │      │
│                    │        fc = 100kHz, Q = 0.707                   │      │
│                    │                                                 │      │
│                    │          R1        R2                           │      │
│                    │    IN ──/\/\/──┬──/\/\/──┬──────► OUT           │      │
│                    │                │         │    │                 │      │
│                    │                │         │  ──┴──               │      │
│                    │              ──┴──     ──┴──  │ │               │      │
│                    │              ──┬──     ──┬──  │ │ C2            │      │
│                    │       C1       │         │  ──┬──               │      │
│                    │                │   Op    │    │                 │      │
│                    │                │   amp   │    │                 │      │
│                    │                │─────────┼────┘                 │      │
│                    │                                                 │      │
│                    │  R1=R2=1.6kΩ, C1=1nF, C2=470pF                  │      │
│                    │  Op-amp: OPA1612 or equivalent                  │      │
│                    │                                                 │      │
│                    └─────────────────────────────────────────────────┘      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Performance Targets (PCM1792A)

| Parameter | Target | Notes |
|-----------|--------|-------|
| THD+N | <0.0004% | At 1kHz, 0dBFS |
| SNR | >123dB | A-weighted |
| Dynamic range | >127dB | |
| Output voltage | 2.76Vrms | Differential |

---

## 4. Volume Control

### 4.1 Volume Control Comparison

| Method | Pros | Cons | Use Case |
|--------|------|------|----------|
| **Digital (DSP)** | Zero cost, infinite resolution | Loses bits at low volume | Mobile, cost-sensitive |
| **DAC Internal** | Good linearity, no added components | Limited range, steps audible | Mid-range |
| **Analog PGA** | No bit loss, good range | Adds noise/distortion | High-end |
| **Relay Ladder** | Best quality, no active components | Expensive, large, clicks | Ultra high-end |

### 4.2 Recommended: Analog PGA (MUSES72323)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MUSES72323 VOLUME CONTROL                                 │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                         MUSES72323                                    │  │
│  │                    (JRC Electronic Volume)                            │  │
│  │                                                                       │  │
│  │  Features:                                                            │  │
│  │  • -111.5dB to 0dB range                                              │  │
│  │  • 0.5dB steps                                                        │  │
│  │  • THD: 0.00016%                                                      │  │
│  │  • SNR: 115dB                                                         │  │
│  │  • Stereo (L/R in one package)                                        │  │
│  │  • SPI control interface                                              │  │
│  │                                                                       │  │
│  │               ┌───────────────┐                                       │  │
│  │   VIN L+ ────►│               │────► VOUT L+                          │  │
│  │   VIN L- ────►│   MUSES72323  │────► VOUT L-                          │  │
│  │   VIN R+ ────►│               │────► VOUT R+                          │  │
│  │   VIN R- ────►│               │────► VOUT R-                          │  │
│  │               │               │                                       │  │
│  │      SPI ────►│ CLK DI CS    │                                       │  │
│  │               └───────────────┘                                       │  │
│  │                                                                       │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  COST: ~$10-15                                                              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.3 Alternative: Relay Ladder (Ultra High-End)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    RELAY LADDER VOLUME CONTROL                               │
│                                                                              │
│  Uses binary-weighted precision resistors switched by relays                │
│  No active components in signal path!                                       │
│                                                                              │
│                    R/16    R/8     R/4     R/2      R                       │
│                   ─────   ─────   ─────   ─────   ─────                     │
│       VIN ──────┬──┤├──┬──┤├──┬──┤├──┬──┤├──┬──┤├──┬────────► VOUT         │
│                 │       │       │       │       │       │                   │
│                ═╪═     ═╪═     ═╪═     ═╪═     ═╪═     │                   │
│                 │       │       │       │       │       │                   │
│                REL1    REL2    REL3    REL4    REL5    GND                  │
│                (0.5dB) (1dB)   (2dB)   (4dB)   (8dB)                        │
│                                                                              │
│  5 relays = 32 steps (15.5dB range per bank)                                │
│  Multiple banks for full range                                              │
│                                                                              │
│  ADVANTAGES:                                                                 │
│  • Zero active component distortion in signal path                          │
│  • Resistor thermal noise only                                              │
│  • Excellent channel matching with 0.01% resistors                          │
│                                                                              │
│  DISADVANTAGES:                                                              │
│  • Expensive (~$50-100 for full implementation)                             │
│  • Large PCB area                                                           │
│  • Relay clicks during adjustment (use mute or soft-switch)                 │
│                                                                              │
│  COMPONENTS:                                                                 │
│  • Relays: Omron G6K-2F-Y (signal relay, low capacitance)                   │
│  • Resistors: Vishay Z-foil (0.01%, 0.2ppm/°C)                              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Output Stage

### 5.1 Headphone Output

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    HEADPHONE OUTPUT STAGE                                    │
│                                                                              │
│  Requirements:                                                               │
│  • Output impedance: <1Ω (damping factor >32 for 32Ω headphones)            │
│  • Max output: ±6.4V (for high-impedance headphones)                        │
│  • Current: >100mA continuous                                               │
│  • THD: <0.001% at full output                                              │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════   │
│                                                                              │
│  DESIGN 1: Discrete Class-A Buffer (Best Quality)                           │
│                                                                              │
│                          V+ (+15V)                                          │
│                              │                                               │
│                          ┌───┴───┐                                          │
│                          │  Ibias │  Constant current source                │
│                          │  50mA  │  (LM334 or discrete)                    │
│                          └───┬───┘                                          │
│                              │                                               │
│                       ┌──────┴──────┐                                       │
│                       │             │                                       │
│                      ███           ███                                      │
│                      █C█           █C█  Matched output transistors          │
│                      ███           ███  (2SC5171 / 2SA1930)                 │
│                       │             │                                       │
│       VIN+ ─────────►│B           B│◄───────── VIN-                        │
│                       │             │                                       │
│                       └──────┬──────┘                                       │
│                              │                                               │
│                              ├─────────────────────────────► VOUT            │
│                              │                                               │
│                          ┌───┴───┐                                          │
│                          │   Re  │  Emitter degeneration (10Ω)              │
│                          └───┬───┘                                          │
│                              │                                               │
│                          V- (-15V)                                          │
│                                                                              │
│  Zout ≈ Re / (1 + β×gm×Re) ≈ 0.1Ω                                          │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════   │
│                                                                              │
│  DESIGN 2: IC-Based (Good Quality, Lower Cost)                              │
│                                                                              │
│           ┌─────────────────────────────────────────────────────────┐       │
│           │                    TPA6120A2                            │       │
│           │              (TI Headphone Amplifier)                   │       │
│           │                                                         │       │
│           │  • Output impedance: 0.1Ω                               │       │
│           │  • THD: 0.000035%                                       │       │
│           │  • SNR: 120dB                                           │       │
│           │  • Output current: 200mA                                │       │
│           │  • Slew rate: 1300V/µs                                  │       │
│           │  • Cost: ~$6                                            │       │
│           │                                                         │       │
│           │       VIN+ ───►┌─────────┐───► VOUT+                    │       │
│           │                │TPA6120A2│                              │       │
│           │       VIN- ───►└─────────┘───► VOUT-                    │       │
│           │                                                         │       │
│           └─────────────────────────────────────────────────────────┘       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Line Output

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    LINE OUTPUT STAGE                                         │
│                                                                              │
│  Line output requirements are simpler:                                      │
│  • 2Vrms nominal                                                            │
│  • 10kΩ minimum load                                                        │
│  • Output impedance: <100Ω (typically much lower)                           │
│                                                                              │
│  Simple buffer using OPA1612:                                               │
│                                                                              │
│                 V+ (+15V)                                                    │
│                    │                                                         │
│                ┌───┴───┐                                                    │
│                │ 100nF │  Bypass cap                                        │
│                └───┬───┘                                                    │
│                    │                                                         │
│       VIN+ ───────►│+      ┌──────────────────────────────► VOUT+          │
│                    │ OUT───┤                                                │
│       VIN- ───────►│-      │                                                │
│                    │       │       ┌─────┐                                  │
│               OPA1612      └───────┤ 47Ω ├──┐                               │
│                    │               └─────┘  │                               │
│                ┌───┴───┐                    ├──► RCA Jack                   │
│                │ 100nF │               ┌────┴────┐                          │
│                └───┬───┘               │  100µF  │  DC blocking             │
│                    │                   │  (film) │  (if needed)             │
│                 V- (-15V)              └─────────┘                          │
│                                                                              │
│  47Ω output resistor:                                                       │
│  • Provides short-circuit protection                                        │
│  • Isolates capacitive cable loads                                          │
│  • Maintains stability                                                      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Power Supply for Analog

### 6.1 Analog Supply Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ANALOG POWER SUPPLY                                       │
│                                                                              │
│  VBAT ──► SMPS ──► Pre-Reg ──► LDO ──► LC Filter ──► Analog Rail           │
│  (3.7V)   (±18V)   (±16V)     (±15V)   (Ultra-clean)                        │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════   │
│                                                                              │
│  DETAILED POWER PATH:                                                       │
│                                                                              │
│             ┌─────────────────────────────────────────────────────────────┐ │
│             │                     SMPS STAGE                              │ │
│             │                   (LT8331/LT8330)                           │ │
│             │                                                             │ │
│             │   VBAT ───► Buck-Boost ───► +18V                            │ │
│             │   (3.7V)                                                    │ │
│             │                            ───► -18V                        │ │
│             │                                                             │ │
│             │   Switching frequency: 2MHz (keep away from audio band)     │ │
│             │   EMI: Spread-spectrum modulation enabled                   │ │
│             │                                                             │ │
│             └─────────────────────────────────────────────────────────────┘ │
│                          │                    │                             │
│                          ▼                    ▼                             │
│             ┌─────────────────────────────────────────────────────────────┐ │
│             │                   PRE-REGULATOR                             │ │
│             │               (Optional, improves PSRR)                     │ │
│             │                                                             │ │
│             │   +18V ───► LM317 ───► +16V                                 │ │
│             │   -18V ───► LM337 ───► -16V                                 │ │
│             │                                                             │ │
│             │   Purpose: Provide clean input to ultra-low-noise LDO       │ │
│             │                                                             │ │
│             └─────────────────────────────────────────────────────────────┘ │
│                          │                    │                             │
│                          ▼                    ▼                             │
│             ┌─────────────────────────────────────────────────────────────┐ │
│             │               ULTRA-LOW-NOISE LDO                           │ │
│             │                                                             │ │
│             │   +16V ───► TPS7A4700 ───► +15V   (4µVrms noise)            │ │
│             │   -16V ───► TPS7A3301 ───► -15V   (4µVrms noise)            │ │
│             │                                                             │ │
│             │   Alternative: LT3093/LT3042 (0.8µVrms noise)               │ │
│             │                                                             │ │
│             └─────────────────────────────────────────────────────────────┘ │
│                          │                    │                             │
│                          ▼                    ▼                             │
│             ┌─────────────────────────────────────────────────────────────┐ │
│             │                  LC POST-FILTER                             │ │
│             │                                                             │ │
│             │   +15V ───┬─── L (10µH) ─── C (100µF) ───┬───► VDD_ANA+     │ │
│             │           │                             │                   │ │
│             │           └─── Ferrite ─────────────────┘                   │ │
│             │                                                             │ │
│             │   -15V ───┬─── L (10µH) ─── C (100µF) ───┬───► VDD_ANA-     │ │
│             │           │                             │                   │ │
│             │           └─── Ferrite ─────────────────┘                   │ │
│             │                                                             │ │
│             │   Capacitors: Nichicon MUSE KZ or Panasonic FR (audio)      │ │
│             │                                                             │ │
│             └─────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  NOISE BUDGET:                                                              │
│  • SMPS output: 10mVpp ripple                                               │
│  • Pre-reg output: 1mVpp ripple                                             │
│  • LDO output: 4µVrms (10Hz-100kHz)                                         │
│  • Post-filter output: <1µVrms                                              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 6.2 Component Recommendations

| Stage | Component | Part Number | Key Spec |
|-------|-----------|-------------|----------|
| **SMPS** | Buck-boost | LT8331 | 2MHz, low EMI |
| **Pre-reg +** | Adjustable LDO | LM317HV | 1.5A, SOT-223 |
| **Pre-reg -** | Adjustable LDO | LM337HV | 1.5A, SOT-223 |
| **LDO +** | Ultra-low noise | TPS7A4700 | 4µVrms, 1A |
| **LDO -** | Ultra-low noise | TPS7A3301 | 4µVrms, 1A |
| **Filter L** | Inductor | Murata LQH | 10µH, low DCR |
| **Filter C** | Audio capacitor | Nichicon KZ | 100µF, low ESR |

---

## 7. PCB Layout Guidelines

### 7.1 Critical Layout Rules

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PCB LAYOUT GUIDELINES                                     │
│                                                                              │
│  1. STACKUP (6-layer recommended):                                          │
│     Layer 1: Signal (analog)                                                │
│     Layer 2: Ground (unbroken beneath analog)                               │
│     Layer 3: Signal (digital)                                               │
│     Layer 4: Power planes                                                   │
│     Layer 5: Ground                                                         │
│     Layer 6: Signal (mixed)                                                 │
│                                                                              │
│  2. GROUND TOPOLOGY:                                                        │
│                                                                              │
│          ┌───────────────────────────────────────────────────────────┐      │
│          │                    GROUND PLANE                           │      │
│          │                                                           │      │
│          │   ┌─────────────┐                   ┌─────────────┐       │      │
│          │   │  ANALOG     │                   │  DIGITAL    │       │      │
│          │   │  GROUND     │                   │  GROUND     │       │      │
│          │   │  ISLAND     │───┐           ┌───│  ISLAND     │       │      │
│          │   │             │   │           │   │             │       │      │
│          │   └─────────────┘   │           │   └─────────────┘       │      │
│          │                     │           │                         │      │
│          │                     └─────┬─────┘                         │      │
│          │                           │                               │      │
│          │                      STAR POINT                           │      │
│          │                    (single connection)                    │      │
│          │                                                           │      │
│          └───────────────────────────────────────────────────────────┘      │
│                                                                              │
│  3. ANALOG ROUTING:                                                         │
│     • Keep analog traces short and direct                                   │
│     • Use ground-signal-ground for sensitive traces                         │
│     • 50Ω controlled impedance for clock signals                            │
│     • No digital traces crossing under analog section                       │
│     • Guard rings around sensitive nodes (I/V summing node)                 │
│                                                                              │
│  4. COMPONENT PLACEMENT:                                                    │
│     • I/V op-amps close to DAC outputs (<5mm)                               │
│     • Bypass caps immediately adjacent to IC pins (<2mm)                    │
│     • Power supply section separated from signal path                       │
│     • SMPS inductor shielded and away from analog                           │
│                                                                              │
│  5. THERMAL:                                                                │
│     • Output stage may dissipate 1-2W in Class-A                            │
│     • Provide thermal vias to internal ground plane                         │
│     • Heat spreader or connection to chassis                                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Test Points and Measurements

### 8.1 Required Test Points

| Test Point | Location | Purpose |
|------------|----------|---------|
| TP1 | DAC analog output | Verify DAC output level |
| TP2 | I/V stage output | Verify I/V conversion |
| TP3 | LPF output | Check for oscillation |
| TP4 | Volume control output | Verify attenuation |
| TP5 | Final output | System-level measurements |
| TP6 | +15V rail | Power supply verification |
| TP7 | -15V rail | Power supply verification |
| TP8 | AGND | Ground reference |

### 8.2 Production Test Specification

| Test | Equipment | Limit | Notes |
|------|-----------|-------|-------|
| THD+N | Audio Precision | <0.001% | 1kHz, 0dBFS |
| SNR | Audio Precision | >120dB | A-weighted |
| Crosstalk | Audio Precision | <-110dB | 1kHz |
| Output level | Multimeter | 2V ±5% | 0dBFS |
| DC offset | Multimeter | <5mV | No signal |
| Output impedance | Impedance analyzer | <1Ω | HP out |

---

*Document Version: 1.0.0*
*Status: Revised Architecture*
