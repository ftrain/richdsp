# RichDSP: Flexible DAC/Amp Platform Architecture

## 1. Executive Summary

RichDSP is a modular, high-performance digital audio player platform designed for maximum flexibility in DAC selection, signal processing, and amplification. The architecture supports hot-swappable analog modules, real-time DSP, and an extensible software stack.

---

## 2. System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER INTERFACE                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  5" Touch   │  │  Physical   │  │  Rotary     │  │  Status LEDs /      │ │
│  │  Display    │  │  Buttons    │  │  Encoder    │  │  Indicators         │ │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘ │
└─────────┼────────────────┼────────────────┼────────────────────┼────────────┘
          │                │                │                    │
┌─────────▼────────────────▼────────────────▼────────────────────▼────────────┐
│                           MAIN PROCESSING UNIT                               │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                      APPLICATION PROCESSOR                              │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │ │
│  │  │   LP OS      │  │   Audio      │  │   File       │  │  Network    │ │ │
│  │  │   Kernel     │  │   Engine     │  │   System     │  │  Stack      │ │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └─────────────┘ │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                         DSP SUBSYSTEM                                   │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │ │
│  │  │  Parametric  │  │  Crossfeed   │  │  Room        │  │  Custom     │ │ │
│  │  │  EQ (10-band)│  │  / Spatial   │  │  Correction  │  │  FIR/IIR    │ │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └─────────────┘ │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │  Clock Gen      │  │  Module         │  │  Power Management           │  │
│  │  (Ultra-low PN) │  │  Detection      │  │  Controller                 │  │
│  └────────┬────────┘  └────────┬────────┘  └─────────────────────────────┘  │
└───────────┼────────────────────┼────────────────────────────────────────────┘
            │                    │
┌───────────▼────────────────────▼────────────────────────────────────────────┐
│                        DIGITAL AUDIO INTERFACE                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │   I2S        │  │   DSD/DoP    │  │   SPDIF      │  │   USB Audio     │  │
│  │   Master     │  │   Native     │  │   In/Out     │  │   (UAC 2.0)     │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └────────┬────────┘  │
└─────────┼─────────────────┼─────────────────┼───────────────────┼───────────┘
          │                 │                 │                   │
          └─────────────────┴─────────────────┴───────────────────┘
                                      │
                            ┌─────────▼─────────┐
                            │  MODULE CONNECTOR │
                            │  (High-density)   │
                            └─────────┬─────────┘
                                      │
┌─────────────────────────────────────▼───────────────────────────────────────┐
│                      SWAPPABLE DAC/AMP MODULE                                │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                         DAC SECTION                                     │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │ │
│  │  │  Supported DAC ICs:                                             │   │ │
│  │  │  • AKM: AK4497, AK4499, AK4493                                  │   │ │
│  │  │  • ESS: ES9038PRO, ES9039MPRO                                   │   │ │
│  │  │  • TI/BB: PCM1792A, PCM1794A                                    │   │ │
│  │  │  • AD: AD1955, AD1862 (R2R)                                     │   │ │
│  │  │  • Discrete R2R ladder networks                                 │   │ │
│  │  └─────────────────────────────────────────────────────────────────┘   │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                      ANALOG SECTION                                     │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │ │
│  │  │  I/V Stage   │  │  Low-pass    │  │  Volume      │  │  Output     │ │ │
│  │  │  (discrete/  │  │  Filter      │  │  Control     │  │  Buffer/    │ │ │
│  │  │   op-amp)    │  │              │  │  (relay/PGA) │  │  Amp        │ │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └─────────────┘ │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                      OUTPUT STAGE                                       │ │
│  │  ┌────────────────────┐  ┌────────────────────┐  ┌──────────────────┐  │ │
│  │  │  Single-Ended      │  │  Balanced          │  │  Line Out        │  │ │
│  │  │  3.5mm / 6.35mm    │  │  4.4mm / XLR       │  │  RCA / XLR       │  │ │
│  │  └────────────────────┘  └────────────────────┘  └──────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                                 │
│  │  Module EEPROM   │  │  Local LDO       │                                 │
│  │  (ID + Config)   │  │  Regulators      │                                 │
│  └──────────────────┘  └──────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           POWER SYSTEM                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │  Li-Po       │  │  Charging    │  │  Multi-rail  │  │  Isolated       │  │
│  │  4700mAh     │  │  (USB-C PD)  │  │  SMPS        │  │  Analog Supply  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Hardware Architecture

### 3.1 Main Board Components

| Subsystem | Component | Purpose |
|-----------|-----------|---------|
| **Application Processor** | ARM Cortex-A53/A72 or RISC-V | Main OS, UI, file handling |
| **DSP** | Dedicated DSP core (SHARC/C6000) or FPGA | Real-time audio processing |
| **Audio MCU** | ARM Cortex-M4/M7 | Low-latency audio path control |
| **Clock Generator** | Si5351 + TCXO or dedicated audio clock | Ultra-low jitter clocking |
| **FPGA (optional)** | Lattice/Xilinx small FPGA | I2S routing, format conversion |
| **Storage** | eMMC + SD card slot | OS + music storage |
| **Display** | 5" IPS 1080x1920 MIPI DSI | Touch UI |
| **Connectivity** | WiFi/BT module, USB-C | Streaming, file transfer |

### 3.2 Module Interface Specification

```
MODULE CONNECTOR PINOUT (80-pin high-density)
═══════════════════════════════════════════════════════════════
DIGITAL AUDIO (Active Low):
  Pin 1-4:    I2S_MCLK (differential pair + ground)
  Pin 5-8:    I2S_BCLK (differential pair + ground)
  Pin 9-12:   I2S_LRCK (differential pair + ground)
  Pin 13-16:  I2S_DATA (differential pair + ground)
  Pin 17-20:  DSD_CLK (differential pair + ground)
  Pin 21-24:  DSD_L (differential pair + ground)
  Pin 25-28:  DSD_R (differential pair + ground)

CONTROL:
  Pin 30-31:  I2C_SDA, I2C_SCL (module config)
  Pin 32-33:  SPI_MOSI, SPI_MISO (high-speed config)
  Pin 34-35:  SPI_CLK, SPI_CS
  Pin 36:     MODULE_DETECT (active low)
  Pin 37:     MODULE_RESET
  Pin 38-40:  GPIO (3x general purpose)

POWER:
  Pin 50-55:  VDD_DIGITAL (3.3V, 6 pins for current)
  Pin 56-61:  VDD_ANALOG_P (+15V or +5V, 6 pins)
  Pin 62-67:  VDD_ANALOG_N (-15V or -5V, 6 pins)
  Pin 68-75:  GND (8 pins, star ground topology)

RESERVED:
  Pin 76-80:  Future expansion
═══════════════════════════════════════════════════════════════
```

### 3.3 Module EEPROM Data Structure

```c
typedef struct {
    uint32_t magic;              // 0x52444350 "RDCP"
    uint16_t version;            // Module spec version
    uint16_t module_id;          // Unique module identifier

    // DAC Configuration
    uint8_t  dac_type;           // Enum: AKM, ESS, TI, AD, R2R, etc.
    uint8_t  dac_model;          // Specific chip model
    uint8_t  dac_count;          // Number of DAC chips
    uint8_t  dac_interface;      // I2S, DSD, both

    // Capabilities
    uint32_t max_pcm_rate;       // Max PCM sample rate (Hz)
    uint32_t max_dsd_rate;       // Max DSD rate (DSD64=2822400)
    uint8_t  bit_depth;          // Max bit depth
    uint8_t  channels;           // Channel count

    // Analog specs
    uint16_t output_voltage_mv;  // Max output (mV RMS)
    uint16_t output_impedance;   // Output impedance (mΩ)
    uint8_t  thd_class;          // THD+N class rating
    uint8_t  snr_class;          // SNR class rating

    // Power requirements
    uint16_t current_3v3_ma;     // Digital current draw
    uint16_t current_pos_ma;     // Positive analog current
    uint16_t current_neg_ma;     // Negative analog current

    // Register maps
    uint16_t reg_map_offset;     // Offset to register init table
    uint16_t reg_map_size;       // Size of register table

    // String descriptors
    char     manufacturer[32];
    char     model_name[32];
    char     serial[16];

    uint32_t crc32;              // Data integrity check
} ModuleDescriptor;
```

---

## 4. Software Architecture

### 4.1 System Stack

```
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION LAYER                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  UI Shell   │  │  Music      │  │  Settings /         │  │
│  │  (Qt/LVGL)  │  │  Library    │  │  Configuration      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    AUDIO FRAMEWORK                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Decoder    │  │  DSP        │  │  Output             │  │
│  │  Pipeline   │  │  Chain      │  │  Manager            │  │
│  │  (ffmpeg)   │  │             │  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    HAL (Hardware Abstraction)                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Module     │  │  Clock      │  │  Audio              │  │
│  │  Manager    │  │  Manager    │  │  Router             │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    KERNEL / RTOS                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Linux      │  │  I2S/DMA    │  │  Power              │  │
│  │  (RT patch) │  │  Drivers    │  │  Management         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    BOOTLOADER                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  U-Boot / Custom bootloader                         │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Audio Pipeline

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Source  │──▶│  Decode  │──▶│   DSP    │──▶│  Resample│──▶│  Output  │
│  (file/  │   │  (codec) │   │  Chain   │   │  (SRC)   │   │  (I2S/   │
│  stream) │   │          │   │          │   │          │   │  DSD)    │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
              ┌──────────┐  ┌──────────┐  ┌──────────┐
              │  EQ      │  │  Volume  │  │  Effects │
              │  (10-band│  │  (64-bit │  │  (xfeed, │
              │  PEQ)    │  │  float)  │  │  reverb) │
              └──────────┘  └──────────┘  └──────────┘
```

### 4.3 Module Manager State Machine

```
                    ┌─────────────────┐
                    │   UNPLUGGED     │
                    └────────┬────────┘
                             │ (detect pin low)
                             ▼
                    ┌─────────────────┐
                    │   DETECTED      │
                    └────────┬────────┘
                             │ (read EEPROM)
                             ▼
                    ┌─────────────────┐
              ┌─────│   IDENTIFYING   │─────┐
              │     └────────┬────────┘     │
              │ (unknown)    │ (known)      │ (corrupt)
              ▼              ▼              ▼
     ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
     │  FALLBACK   │  │   CONFIG    │  │   ERROR     │
     │  (generic)  │  │   LOADING   │  │             │
     └──────┬──────┘  └──────┬──────┘  └─────────────┘
            │                │
            └───────┬────────┘
                    ▼
           ┌─────────────────┐
           │  INITIALIZING   │
           └────────┬────────┘
                    │ (DAC registers written)
                    ▼
           ┌─────────────────┐
           │     READY       │
           └────────┬────────┘
                    │ (playback starts)
                    ▼
           ┌─────────────────┐
           │     ACTIVE      │◀──────┐
           └────────┬────────┘       │
                    │ (idle timeout) │ (playback resumes)
                    ▼                │
           ┌─────────────────┐       │
           │   LOW_POWER     │───────┘
           └─────────────────┘
```

---

## 5. DSP Capabilities

### 5.1 Processing Blocks

| Block | Function | Implementation |
|-------|----------|----------------|
| **Parametric EQ** | 10-band fully parametric | Biquad IIR filters |
| **Graphic EQ** | 31-band graphic | FIR or IIR bank |
| **Crossfeed** | Headphone spatial | Bauer stereophonic |
| **Room Correction** | Convolution | FIR up to 65536 taps |
| **Dynamic Range** | Compression/limiting | Look-ahead limiter |
| **Upsampling** | PCM rate conversion | Sinc interpolation |
| **DSD Conversion** | PCM↔DSD | Sigma-delta modulator |
| **Channel Mixing** | Matrix mixer | Gain matrix |
| **Phase Correction** | Time alignment | Delay lines |
| **Harmonic Enhancement** | Tube/tape simulation | Waveshaping |

### 5.2 Supported Formats

```
PCM:
  Sample rates: 44.1, 48, 88.2, 96, 176.4, 192, 352.8, 384, 705.6, 768 kHz
  Bit depths:   16, 24, 32 (integer), 32/64 (float)

DSD:
  DSD64  (2.8224 MHz)
  DSD128 (5.6448 MHz)
  DSD256 (11.2896 MHz)
  DSD512 (22.5792 MHz)

Container formats:
  FLAC, ALAC, WAV, AIFF, DFF, DSF, APE, WavPack, MP3, AAC, OGG, OPUS
```

---

## 6. Electrical Specifications

### 6.1 Power Rails

| Rail | Voltage | Max Current | Purpose |
|------|---------|-------------|---------|
| VDD_CORE | 1.0V | 2A | SoC core |
| VDD_IO | 1.8V / 3.3V | 500mA | I/O, SD card |
| VDD_MODULE | 3.3V | 1A | Module digital |
| VDD_ANALOG+ | +5V to +15V | 500mA | Module positive analog |
| VDD_ANALOG- | -5V to -15V | 500mA | Module negative analog |
| VDD_USB | 5V | 500mA | USB host power |

### 6.2 Audio Performance Targets

| Parameter | Target | Notes |
|-----------|--------|-------|
| THD+N | < 0.0005% | At 1kHz, 1Vrms |
| SNR | > 125dB | A-weighted |
| Dynamic Range | > 130dB | |
| Channel Separation | > 120dB | At 1kHz |
| Output Impedance | < 1Ω | Headphone out |
| Max Output | 6.4Vrms | Balanced |
| Jitter | < 100fs | At clock output |

---

## 7. Mechanical Design

### 7.1 Enclosure

- **Material**: CNC aluminum unibody
- **Dimensions**: 75 × 140 × 22mm
- **Weight**: < 350g
- **Finish**: Anodized, multiple color options
- **Thermal**: Passive cooling via chassis

### 7.2 Module Bay

- **Access**: Tool-free slide-out mechanism
- **Hot-swap**: Supported (with mute during transition)
- **Alignment**: Keyed connector, ESD protection

---

## 8. Development Roadmap

### Phase 1: Platform Foundation
- [ ] Finalize SoC selection and evaluation boards
- [ ] Design main board schematic
- [ ] Develop bootloader and base Linux BSP
- [ ] Create module interface specification v1.0
- [ ] Prototype reference DAC module (AK4497)

### Phase 2: Core Functionality
- [ ] Audio driver development (I2S, DMA)
- [ ] Module detection and initialization
- [ ] Basic playback pipeline
- [ ] DSP framework implementation
- [ ] UI framework selection and prototype

### Phase 3: Feature Complete
- [ ] Full DSP processing chain
- [ ] Multiple module support (hot-swap)
- [ ] Complete UI implementation
- [ ] USB Audio Class 2.0 device mode
- [ ] Streaming protocols (DLNA, Roon)

### Phase 4: Production
- [ ] Hardware design for manufacture (DFM)
- [ ] EMC testing and certification
- [ ] Production tooling
- [ ] Factory test procedures
- [ ] Documentation and user guides

---

## 9. Open Questions

1. **SoC Selection**: ARM vs RISC-V? Integrated DSP or separate?
2. **FPGA Necessity**: Required for I2S routing flexibility?
3. **Module Voltage**: Fixed ±15V or configurable?
4. **DSD Native Path**: Separate data lines or DoP only?
5. **OS Choice**: Custom Linux vs Android for app ecosystem?
6. **Licensing**: Open source firmware or proprietary?

---

## 10. References

- AKM AK4497 Datasheet
- ESS ES9038PRO Datasheet
- USB Audio Class 2.0 Specification
- I2S Bus Specification (Philips)
- DSD-Wide Interface Specification

---

*Document Version: 0.1.0-draft*
*Last Updated: 2024*
*Status: Initial Architecture Proposal*
