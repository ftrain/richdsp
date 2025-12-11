# RichDSP Bill of Materials & Cost Analysis

## 1. Overview

This document provides detailed BOM cost analysis for the RichDSP platform with three configuration tiers: Flagship, Standard, and Cost-Optimized. Each tier makes specific trade-offs between performance and cost.

---

## 2. Configuration Tiers

| Tier | Target Price | Target Specs | Market Position |
|------|--------------|--------------|-----------------|
| **Flagship** | $4,000-5,000 | THD < 0.0003%, SNR > 128dB | Audiophile reference |
| **Standard** | $2,000-2,500 | THD < 0.001%, SNR > 123dB | Enthusiast |
| **Cost-Optimized** | $800-1,200 | THD < 0.003%, SNR > 118dB | Entry hi-fi |

---

## 3. Main Board BOM

### 3.1 SoC / Processing

| Component | Flagship | Standard | Cost-Opt | Notes |
|-----------|----------|----------|----------|-------|
| **Application Processor** | | | | |
| NXP i.MX 8M Plus | $45 | - | - | Quad A53, NPU, best BSP |
| NXP i.MX 8M Mini | - | $28 | - | Quad A53, proven audio |
| Allwinner H6 | - | - | $8 | Quad A53, good value |
| **Memory** | | | | |
| LPDDR4 4GB | $18 | $18 | - | Samsung/Micron |
| LPDDR4 2GB | - | - | $10 | |
| **Storage** | | | | |
| eMMC 64GB | $12 | $12 | $8 | Samsung/Kingston |
| **DSP (optional)** | | | | |
| SHARC ADSP-21569 | $35 | - | - | Dedicated audio DSP |
| None (use NEON) | - | $0 | $0 | ARM SIMD sufficient |

**Subtotal Processing:**
- Flagship: $110
- Standard: $58
- Cost-Opt: $26

### 3.2 Clock System

| Component | Flagship | Standard | Cost-Opt | Notes |
|-----------|----------|----------|----------|-------|
| **Oscillators** | | | | |
| Crystek CVHD-950 22.5792MHz | $18 | - | - | VCXO, <25fs |
| Crystek CVHD-950 24.576MHz | $18 | - | - | VCXO, <25fs |
| NDK NZ2520SD 22.5792MHz | - | $10 | - | TCXO, <50fs |
| NDK NZ2520SD 24.576MHz | - | $10 | - | TCXO, <50fs |
| Standard XO 22.5792MHz | - | - | $2 | Crystal osc, ~1ps |
| Standard XO 24.576MHz | - | - | $2 | Crystal osc, ~1ps |
| **Clock Distribution** | | | | |
| SY89545U (mux) | $3 | $3 | - | Ultra-low jitter |
| CDCLVD1208 (fanout) | $4 | - | - | LVDS fanout |
| 74LVC1G157 (mux) | - | - | $0.30 | Basic CMOS mux |
| **LDO for clocks** | | | | |
| TPS7A4700 | $3.50 | $3.50 | - | Ultra-low noise |
| Standard LDO | - | - | $0.50 | |

**Subtotal Clock:**
- Flagship: $46.50
- Standard: $26.50
- Cost-Opt: $4.80

### 3.3 Power System

| Component | Flagship | Standard | Cost-Opt | Notes |
|-----------|----------|----------|----------|-------|
| **Battery** | | | | |
| Li-Po 4700mAh | $15 | $15 | $12 | Quality cells |
| **Charging IC** | | | | |
| BQ25895 (USB-C PD) | $4 | $4 | $3 | TI charger |
| **SMPS** | | | | |
| LT8331 (±18V) | $8 | $6 | - | Low EMI boost |
| MT3608 (generic) | - | - | $0.50 | Basic boost |
| **Analog LDOs** | | | | |
| TPS7A4700 (+15V) | $3.50 | $3.50 | - | 4µVrms |
| TPS7A3301 (-15V) | $3.50 | $3.50 | - | 4µVrms |
| LM317/337 | - | - | $1 | Standard regulators |
| **Digital LDOs** | | | | |
| Various 3.3V/1.8V | $3 | $3 | $2 | |
| **Protection** | | | | |
| Fuse, TVS, etc. | $2 | $2 | $1 | |

**Subtotal Power:**
- Flagship: $39
- Standard: $37
- Cost-Opt: $19.50

### 3.4 Display & UI

| Component | Flagship | Standard | Cost-Opt | Notes |
|-----------|----------|----------|----------|-------|
| **Display** | | | | |
| 5" IPS 1080x1920 | $35 | $35 | - | High-res MIPI |
| 4.3" IPS 800x480 | - | - | $18 | Lower res |
| **Touch Controller** | | | | |
| GT911 or equiv | $2 | $2 | $1.50 | Capacitive touch |
| **Buttons/Encoder** | | | | |
| Alps encoder + buttons | $5 | $5 | $3 | Quality tactile |

**Subtotal Display/UI:**
- Flagship: $42
- Standard: $42
- Cost-Opt: $22.50

### 3.5 Connectivity

| Component | Flagship | Standard | Cost-Opt | Notes |
|-----------|----------|----------|----------|-------|
| **WiFi/BT Module** | | | | |
| Murata Type 1MW | $12 | - | - | Premium, certified |
| ESP32-C3 | - | $4 | $4 | Good value |
| **USB-C Controller** | | | | |
| TUSB320 + MUX | $5 | $5 | $3 | USB-C with PD |
| **SD Card Slot** | | | | |
| Micro SD connector | $1 | $1 | $1 | Standard |

**Subtotal Connectivity:**
- Flagship: $18
- Standard: $10
- Cost-Opt: $8

### 3.6 Module Interface

| Component | Flagship | Standard | Cost-Opt | Notes |
|-----------|----------|----------|----------|-------|
| **Connector** | | | | |
| Hirose FX23-80P | $8 | $8 | - | 80-pin, hot-swap rated |
| Generic 60-pin | - | - | $3 | Reduced pin count |
| **Hot-swap Control** | | | | |
| Load switches, TVS | $4 | $4 | $2 | Protection circuits |
| **I2C Isolator** | | | | |
| ISO1540 | $2 | $2 | - | Galvanic isolation |

**Subtotal Module Interface:**
- Flagship: $14
- Standard: $14
- Cost-Opt: $5

### 3.7 Audio Output (Main Board)

| Component | Flagship | Standard | Cost-Opt | Notes |
|-----------|----------|----------|----------|-------|
| **Mute Relay** | | | | |
| Omron G6K-2F-Y | $3 | $3 | - | Signal relay |
| Analog switch IC | - | - | $1 | CMOS switch |
| **Output Jacks** | | | | |
| Neutrik 4.4mm TRRRS | $8 | $8 | - | Balanced |
| Neutrik 3.5mm TRS | $4 | $4 | $3 | SE |
| 6.35mm jack | $3 | - | - | Full-size SE |

**Subtotal Audio Output:**
- Flagship: $18
- Standard: $15
- Cost-Opt: $4

### 3.8 Mechanical

| Component | Flagship | Standard | Cost-Opt | Notes |
|-----------|----------|----------|----------|-------|
| **Enclosure** | | | | |
| CNC aluminum unibody | $65 | - | - | Premium finish |
| Extruded aluminum | - | $35 | - | Good quality |
| Injection molded | - | - | $8 | Plastic |
| **Module latch** | | | | |
| CNC mechanism | $12 | $8 | - | Tool-free |
| Basic latch | - | - | $2 | Simple |
| **Hardware** | | | | |
| Screws, gaskets, etc. | $5 | $4 | $2 | |

**Subtotal Mechanical:**
- Flagship: $82
- Standard: $47
- Cost-Opt: $12

---

## 4. DAC Module BOM (AK4497 Example)

### 4.1 Flagship AK4497 Module

| Component | Qty | Unit Cost | Total | Notes |
|-----------|-----|-----------|-------|-------|
| **DAC** | | | | |
| AKM AK4497EQ | 2 | $35 | $70 | Dual mono |
| **I/V Stage** | | | | |
| OPA1612 | 4 | $4.50 | $18 | I/V conversion |
| Vishay Z-foil 470Ω | 8 | $8 | $64 | 0.01%, 0.2ppm/°C |
| **Low-pass Filter** | | | | |
| OPA1612 | 2 | $4.50 | $9 | Sallen-Key |
| C0G capacitors | 8 | $0.50 | $4 | |
| **Volume Control** | | | | |
| MUSES72323 | 1 | $12 | $12 | Electronic volume |
| **Output Stage** | | | | |
| TPA6120A2 | 1 | $6 | $6 | Headphone amp |
| OPA1612 | 2 | $4.50 | $9 | Line buffer |
| **Power** | | | | |
| TPS7A4700 (+) | 2 | $3.50 | $7 | Per-channel LDO |
| TPS7A3301 (-) | 2 | $3.50 | $7 | Per-channel LDO |
| Passives | - | - | $8 | Caps, resistors |
| **Security** | | | | |
| ATECC608B | 1 | $0.60 | $0.60 | Module auth |
| EEPROM 4KB | 1 | $0.30 | $0.30 | Config storage |
| **PCB** | | | | |
| 6-layer, gold | 1 | $15 | $15 | High quality |
| **Connector** | | | | |
| Hirose FX23-80P | 1 | $8 | $8 | Module side |

**Flagship AK4497 Module Total: $237.90**

### 4.2 Standard AK4497 Module

| Component | Qty | Unit Cost | Total | Notes |
|-----------|-----|-----------|-------|-------|
| AKM AK4497EQ | 1 | $35 | $35 | Single |
| OPA1612 | 2 | $4.50 | $9 | I/V |
| Precision resistors (0.1%) | 4 | $1 | $4 | |
| OPA1612 | 1 | $4.50 | $4.50 | LPF |
| MUSES72320 | 1 | $8 | $8 | Volume |
| TPA6120A2 | 1 | $6 | $6 | HP amp |
| LDOs (standard) | 2 | $1 | $2 | |
| Passives | - | - | $5 | |
| ATECC608B | 1 | $0.60 | $0.60 | |
| PCB 4-layer | 1 | $8 | $8 | |
| Connector | 1 | $8 | $8 | |

**Standard AK4497 Module Total: $90.10**

### 4.3 Cost-Optimized Module (ES9018K2M)

| Component | Qty | Unit Cost | Total | Notes |
|-----------|-----|-----------|-------|-------|
| ESS ES9018K2M | 1 | $8 | $8 | Mobile DAC |
| NE5532 | 2 | $0.50 | $1 | I/V + LPF |
| Resistors (1%) | 8 | $0.02 | $0.16 | |
| Digital pot | 1 | $2 | $2 | Volume |
| TPA6132A2 | 1 | $2 | $2 | HP amp |
| LDOs | 2 | $0.50 | $1 | |
| Passives | - | - | $2 | |
| PCB 2-layer | 1 | $3 | $3 | |
| Connector | 1 | $3 | $3 | |

**Cost-Optimized Module Total: $22.16**

---

## 5. Complete System Cost Summary

### 5.1 Main Board Cost

| Subsystem | Flagship | Standard | Cost-Opt |
|-----------|----------|----------|----------|
| Processing | $110 | $58 | $26 |
| Clock | $46.50 | $26.50 | $4.80 |
| Power | $39 | $37 | $19.50 |
| Display/UI | $42 | $42 | $22.50 |
| Connectivity | $18 | $10 | $8 |
| Module Interface | $14 | $14 | $5 |
| Audio Output | $18 | $15 | $4 |
| Mechanical | $82 | $47 | $12 |
| PCB (main) | $25 | $18 | $8 |
| Assembly | $40 | $30 | $20 |
| **Main Board Total** | **$434.50** | **$297.50** | **$129.80** |

### 5.2 Total System Cost (with one module)

| Configuration | Main Board | Module | Total BOM | Target Retail | Margin |
|---------------|------------|--------|-----------|---------------|--------|
| Flagship + AK4497 | $434.50 | $237.90 | $672.40 | $4,000 | 83% |
| Flagship + ES9038PRO | $434.50 | $295.00 | $729.50 | $4,500 | 84% |
| Standard + AK4497 | $297.50 | $90.10 | $387.60 | $2,000 | 81% |
| Standard + ES9038PRO | $297.50 | $145.00 | $442.50 | $2,500 | 82% |
| Cost-Opt + ES9018K2M | $129.80 | $22.16 | $151.96 | $800 | 81% |

**Note**: Retail margin must cover R&D amortization, warranty, support, distribution, and profit.

---

## 6. Cost Optimization Opportunities

### 6.1 Quick Wins (Minimal Performance Impact)

| Change | Savings | Impact |
|--------|---------|--------|
| NDK TCXO instead of Crystek OCXO | $16 | Jitter 50fs vs 25fs (inaudible) |
| Standard resistors (0.1%) vs Z-foil | $60 | Slightly higher TC |
| Extruded vs CNC enclosure | $30 | Aesthetic only |
| Drop 6.35mm jack | $3 | Adapter required |
| Remove dedicated DSP | $35 | ARM NEON sufficient |
| **Total Quick Wins** | **$144** | Minimal |

### 6.2 Moderate Trade-offs

| Change | Savings | Impact |
|--------|---------|--------|
| Single DAC vs dual mono | $35 | ~3dB lower SNR |
| 4-layer vs 6-layer PCB | $7 | Requires careful layout |
| Smaller display (4.3") | $17 | Less premium feel |
| ESP32 vs premium WiFi | $8 | Similar function |
| **Total Moderate** | **$67** | Noticeable but acceptable |

### 6.3 Not Recommended

| Change | Savings | Impact |
|--------|---------|--------|
| Remove ATECC608B | $0.60 | Loses module authentication |
| Cheap op-amps (4558) | $15 | THD increases 10-100x |
| Skip hot-swap protection | $4 | Safety hazard |
| Use switching for analog | $10 | Noise floor rises dramatically |

---

## 7. Volume Pricing

### 7.1 Component Price Breaks

| Component | 1-99 | 100-499 | 500-999 | 1000+ |
|-----------|------|---------|---------|-------|
| AK4497EQ | $35 | $32 | $29 | $26 |
| ES9038PRO | $45 | $41 | $38 | $35 |
| OPA1612 | $4.50 | $4.00 | $3.60 | $3.20 |
| TPS7A4700 | $3.50 | $3.20 | $2.90 | $2.60 |
| ATECC608B | $0.60 | $0.55 | $0.50 | $0.45 |
| PCB (6-layer) | $15 | $10 | $7 | $5 |

### 7.2 Assembly Cost Scaling

| Volume | Main Board | Module | Notes |
|--------|------------|--------|-------|
| 1-99 | $40 | $15 | Hand assembly |
| 100-499 | $25 | $10 | Small batch SMT |
| 500-999 | $18 | $7 | Production SMT |
| 1000+ | $12 | $5 | Full automation |

### 7.3 Total Cost at Volume

| Configuration | 100 units | 500 units | 1000 units |
|---------------|-----------|-----------|------------|
| Flagship + AK4497 | $585 | $520 | $465 |
| Standard + AK4497 | $340 | $295 | $260 |
| Cost-Opt + ES9018K2M | $135 | $115 | $100 |

---

## 8. Supply Chain Considerations

### 8.1 Critical Components

| Component | Lead Time | Risk | Mitigation |
|-----------|-----------|------|------------|
| **AKM DACs** | 26-52 weeks | HIGH | Second source ESS |
| **ESS DACs** | 12-20 weeks | MEDIUM | Stock buffer |
| **NXP i.MX** | 16-24 weeks | MEDIUM | Design for multiple SoCs |
| **LPDDR4** | 8-12 weeks | LOW | Multiple sources |
| **Premium resistors** | 12-16 weeks | LOW | Multiple sources |

### 8.2 Recommended Stock Levels

| Component | Months of Stock | Rationale |
|-----------|-----------------|-----------|
| DAC ICs | 6-12 months | Critical, long lead |
| SoC | 3-6 months | Long lead |
| Passives | 1-3 months | Easy to source |
| Connectors | 3-6 months | Custom, moderate lead |

---

## 9. Cost Reduction Roadmap

### Phase 1 (Launch)
- Flagship and Standard tiers only
- Focus on quality, build brand

### Phase 2 (6 months)
- Introduce Cost-Optimized tier
- Volume pricing kicks in

### Phase 3 (12 months)
- Design refresh for DFM improvements
- Target 15% cost reduction across all tiers

### Phase 4 (18 months)
- Next-gen SoC integration
- Potential single-board design for Cost-Opt tier

---

## 10. Appendix: Full BOM Templates

### 10.1 Flagship Main Board BOM

```
Part Number          Description              Qty  Unit     Extended
─────────────────────────────────────────────────────────────────────
MIMX8ML8CVNKZAB     i.MX 8M Plus             1    $45.00   $45.00
MT53E512M32D2DS     LPDDR4 4GB               2    $9.00    $18.00
KLMBG4GEND-B041     eMMC 64GB                1    $12.00   $12.00
ADSP-21569KBCZ      SHARC DSP                1    $35.00   $35.00
CVHD-950-22.5792    VCXO 22.5792MHz          1    $18.00   $18.00
CVHD-950-24.576     VCXO 24.576MHz           1    $18.00   $18.00
SY89545UMG          Clock Mux                1    $3.00    $3.00
CDCLVD1208RGZT      Clock Fanout             1    $4.00    $4.00
TPS7A4700RGWR       LDO 3.3V (clock)         1    $3.50    $3.50
... (continued)
─────────────────────────────────────────────────────────────────────
                                          TOTAL:          $434.50
```

*(Full BOM available in separate spreadsheet)*

---

*Document Version: 1.0.0*
*Status: Cost Analysis*
