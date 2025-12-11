# RichDSP Security Architecture

## 1. Overview

This document defines the security architecture for the RichDSP platform, addressing the critical gaps identified in the architecture review. Security must be designed in from the start - it cannot be bolted on later.

### 1.1 Threat Model

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           THREAT LANDSCAPE                                   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │ PHYSICAL THREATS                                                        ││
│  │ • Malicious DAC modules (counterfeit, tampered)                         ││
│  │ • Debug port access (UART, JTAG)                                        ││
│  │ • Storage extraction (eMMC dump)                                        ││
│  │ • Side-channel attacks (power analysis)                                 ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │ SOFTWARE THREATS                                                        ││
│  │ • Malicious firmware updates                                            ││
│  │ • Compromised app store apps                                            ││
│  │ • Network attacks (if WiFi enabled)                                     ││
│  │ • USB attacks (malicious host)                                          ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │ SUPPLY CHAIN THREATS                                                    ││
│  │ • Counterfeit components                                                ││
│  │ • Factory backdoors                                                     ││
│  │ • Compromised development tools                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Security Objectives

| Objective | Description | Priority |
|-----------|-------------|----------|
| **Authenticity** | Only genuine firmware and modules operate | Critical |
| **Integrity** | Detect tampering with firmware/data | Critical |
| **Confidentiality** | Protect user data and credentials | High |
| **Availability** | Resist bricking, ensure recovery | High |
| **Privacy** | Minimize data collection, user control | Medium |

---

## 2. Secure Boot Chain

### 2.1 Boot Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SECURE BOOT CHAIN                                     │
│                                                                              │
│   ┌──────────────┐                                                          │
│   │   ROM        │  Immutable bootloader in SoC                             │
│   │   Bootloader │  Verifies BL2 signature                                  │
│   │   (BL1)      │  Root of trust                                           │
│   └──────┬───────┘                                                          │
│          │ RSA-2048 signature verification                                  │
│          ▼                                                                  │
│   ┌──────────────┐                                                          │
│   │   Trusted    │  ARM Trusted Firmware (ATF)                              │
│   │   Firmware   │  Initializes secure world                                │
│   │   (BL2)      │  Verifies BL31 + BL33                                    │
│   └──────┬───────┘                                                          │
│          │ RSA-2048 signature verification                                  │
│          ▼                                                                  │
│   ┌──────────────┐                                                          │
│   │   Secure     │  OP-TEE or other TEE                                     │
│   │   Monitor    │  Provides secure services                                │
│   │   (BL31)     │  Key storage, crypto                                     │
│   └──────┬───────┘                                                          │
│          │ RSA-2048 signature verification                                  │
│          ▼                                                                  │
│   ┌──────────────┐                                                          │
│   │   U-Boot     │  Normal world bootloader                                 │
│   │   (BL33)     │  Verifies kernel + DTB                                   │
│   └──────┬───────┘                                                          │
│          │ RSA-2048 / SHA-256 verification                                  │
│          ▼                                                                  │
│   ┌──────────────┐                                                          │
│   │   Linux      │  dm-verity for system partition                          │
│   │   Kernel     │  IMA for runtime integrity                               │
│   └──────┬───────┘                                                          │
│          │ dm-verity hash tree verification                                 │
│          ▼                                                                  │
│   ┌──────────────┐                                                          │
│   │   Android    │  Verified Boot (AVB 2.0)                                 │
│   │   System     │  APK signature verification                              │
│   └──────────────┘                                                          │
│                                                                              │
│   SECURITY PROPERTIES:                                                       │
│   ✓ Unbroken chain from ROM to userspace                                    │
│   ✓ Any tampering detected and halts boot                                   │
│   ✓ Rollback protection via anti-rollback counters                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Key Hierarchy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           KEY HIERARCHY                                      │
│                                                                              │
│                    ┌─────────────────────┐                                  │
│                    │   OEM Root Key      │  Burned into SoC eFuses          │
│                    │   (RSA-4096)        │  NEVER leaves factory            │
│                    └──────────┬──────────┘                                  │
│                               │                                              │
│           ┌───────────────────┼───────────────────┐                         │
│           │                   │                   │                         │
│           ▼                   ▼                   ▼                         │
│   ┌───────────────┐   ┌───────────────┐   ┌───────────────┐                │
│   │ Firmware      │   │ Module        │   │ OTA Update    │                │
│   │ Signing Key   │   │ Signing Key   │   │ Signing Key   │                │
│   │ (RSA-2048)    │   │ (ECDSA-P256)  │   │ (RSA-2048)    │                │
│   └───────────────┘   └───────────────┘   └───────────────┘                │
│                                                                              │
│   Storage:                                                                   │
│   • OEM Root Key: SoC eFuses (one-time programmable)                        │
│   • Signing Keys: HSM in secure facility                                    │
│   • Public Keys: Embedded in bootloader/firmware                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.3 Anti-Rollback Protection

```c
/* Anti-rollback counter structure */
typedef struct {
    uint32_t bootloader_version;    /* BL2/BL33 minimum version */
    uint32_t kernel_version;        /* Kernel minimum version */
    uint32_t system_version;        /* Android/rootfs minimum version */
    uint32_t module_fw_version;     /* DAC module firmware minimum */
} rollback_counters_t;

/* Stored in SoC eFuses or RPMB partition */
/* Can only be incremented, never decremented */
```

---

## 3. Module Authentication

### 3.1 Authentication Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MODULE AUTHENTICATION FLOW                                │
│                                                                              │
│   MAIN UNIT                              DAC MODULE                          │
│   ─────────                              ──────────                          │
│                                                                              │
│   ┌─────────────┐                        ┌─────────────┐                    │
│   │  Module     │   1. Read Module ID    │   EEPROM    │                    │
│   │  Manager    │ ─────────────────────► │   (Basic)   │                    │
│   └──────┬──────┘                        └─────────────┘                    │
│          │                                                                   │
│          │ 2. Generate challenge (32-byte random)                           │
│          │                                                                   │
│          ▼                                                                   │
│   ┌─────────────┐                        ┌─────────────┐                    │
│   │  Crypto     │   3. Challenge         │   Secure    │                    │
│   │  Engine     │ ─────────────────────► │   Element   │                    │
│   │  (TEE)      │                        │  (ATECC608) │                    │
│   └──────┬──────┘                        └──────┬──────┘                    │
│          │                                      │                           │
│          │                               4. Sign with module private key    │
│          │                                      │                           │
│          │         5. Signature                 │                           │
│          │ ◄────────────────────────────────────┘                           │
│          │                                                                   │
│          ▼                                                                   │
│   ┌─────────────┐                                                           │
│   │  Verify     │  6. Verify signature with RichDSP Module CA cert         │
│   │  Signature  │                                                           │
│   └──────┬──────┘                                                           │
│          │                                                                   │
│          ├──► PASS: Enable full functionality                               │
│          │                                                                   │
│          └──► FAIL: Warn user, limited functionality (or reject)            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Module Certificate Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MODULE CERTIFICATE CHAIN                                  │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ RichDSP Root CA                                                     │   │
│   │ ─────────────────                                                   │   │
│   │ Subject: CN=RichDSP Root CA, O=RichDSP                              │   │
│   │ Validity: 20 years                                                  │   │
│   │ Key: ECDSA P-384                                                    │   │
│   │ Storage: Offline HSM (air-gapped)                                   │   │
│   └──────────────────────────────┬──────────────────────────────────────┘   │
│                                  │ Signs                                    │
│                                  ▼                                          │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ RichDSP Module CA                                                   │   │
│   │ ───────────────────                                                 │   │
│   │ Subject: CN=RichDSP Module CA, O=RichDSP                            │   │
│   │ Validity: 10 years                                                  │   │
│   │ Key: ECDSA P-256                                                    │   │
│   │ Storage: Online HSM (factory provisioning)                          │   │
│   └──────────────────────────────┬──────────────────────────────────────┘   │
│                                  │ Signs                                    │
│                                  ▼                                          │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ Module Device Certificate (per module)                              │   │
│   │ ───────────────────────────────────────                             │   │
│   │ Subject: CN=<module_serial>, O=RichDSP                              │   │
│   │ Serial: Unique per module                                           │   │
│   │ Validity: Lifetime of module                                        │   │
│   │ Key: ECDSA P-256 (generated in ATECC608, never exported)            │   │
│   │ Extensions:                                                         │   │
│   │   - moduleType: AK4497 | ES9038PRO | etc.                           │   │
│   │   - moduleSerial: <unique identifier>                               │   │
│   │   - manufacturingDate: <date>                                       │   │
│   │   - firmwareVersion: <version>                                      │   │
│   │ Storage: Module EEPROM + Secure Element                             │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.3 Secure Element on Module

Each DAC module includes an **ATECC608B** secure element:

| Feature | Specification |
|---------|---------------|
| **Crypto** | ECDSA P-256, SHA-256, AES-128 |
| **Key Storage** | 16 key slots, hardware protected |
| **Random** | FIPS-compliant TRNG |
| **Tamper** | Active tamper detection |
| **Interface** | I2C (shared with EEPROM) |
| **Cost** | ~$0.60 |

```c
/* Module authentication implementation */

#include <atecc608.h>

#define MODULE_I2C_ADDR_EEPROM  0x50
#define MODULE_I2C_ADDR_ATECC   0x60

typedef struct {
    uint8_t challenge[32];
    uint8_t signature[64];  /* ECDSA P-256 signature */
    uint8_t certificate[512];
} module_auth_data_t;

int module_authenticate(int i2c_fd, module_auth_data_t *auth)
{
    int ret;

    /* Generate random challenge */
    ret = tee_generate_random(auth->challenge, 32);
    if (ret < 0) return ret;

    /* Send challenge to module's secure element */
    ret = atecc_nonce(i2c_fd, MODULE_I2C_ADDR_ATECC, auth->challenge);
    if (ret < 0) return ret;

    /* Request signature */
    ret = atecc_sign(i2c_fd, MODULE_I2C_ADDR_ATECC,
                     ATECC_KEY_SLOT_DEVICE, auth->signature);
    if (ret < 0) return ret;

    /* Read certificate from EEPROM */
    ret = eeprom_read(i2c_fd, MODULE_I2C_ADDR_EEPROM,
                      CERT_OFFSET, auth->certificate, 512);
    if (ret < 0) return ret;

    /* Verify certificate chain (in TEE) */
    ret = tee_verify_module_cert(auth->certificate, 512);
    if (ret < 0) return ret;

    /* Verify signature matches challenge */
    ret = tee_verify_signature(auth->certificate,
                               auth->challenge, 32,
                               auth->signature, 64);
    if (ret < 0) return ret;

    return 0;  /* Authentication successful */
}
```

### 3.4 Unauthenticated Module Policy

| Scenario | Action |
|----------|--------|
| **Valid signature** | Full functionality enabled |
| **Invalid signature** | Warning displayed, basic playback only, no DSP |
| **No secure element** | Warning, treated as "generic" module |
| **Revoked certificate** | Rejected (module on blocklist) |

User can override warnings for DIY/third-party modules, but this is logged.

---

## 4. OTA Update Security

### 4.1 A/B Partition Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        eMMC PARTITION LAYOUT                                 │
│                                                                              │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┬─────────────────┐ │
│  │ boot_a   │ boot_b   │ system_a │ system_b │ userdata │ misc            │ │
│  │ (64MB)   │ (64MB)   │ (2GB)    │ (2GB)    │ (var)    │ (16MB)          │ │
│  └──────────┴──────────┴──────────┴──────────┴──────────┴─────────────────┘ │
│                                                                              │
│  boot_x:    Kernel + DTB + ramdisk (signed)                                 │
│  system_x:  Android/Linux rootfs (dm-verity protected)                      │
│  userdata:  User data (encrypted with FBE)                                  │
│  misc:      Boot control, OTA status                                        │
│                                                                              │
│  BENEFITS:                                                                   │
│  ✓ Seamless updates (update inactive slot while running)                    │
│  ✓ Automatic rollback on boot failure                                       │
│  ✓ No downtime during update                                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Update Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        OTA UPDATE FLOW                                       │
│                                                                              │
│   ┌──────────┐       ┌──────────┐       ┌──────────┐       ┌──────────┐    │
│   │  Check   │──────►│ Download │──────►│  Verify  │──────►│  Apply   │    │
│   │  Server  │       │  Package │       │ Signature│       │  Update  │    │
│   └──────────┘       └──────────┘       └──────────┘       └──────────┘    │
│        │                  │                  │                  │           │
│        ▼                  ▼                  ▼                  ▼           │
│   • TLS 1.3          • Resume support   • RSA-2048 sig     • Write to      │
│   • Certificate      • Hash chunks      • Version check      inactive slot │
│     pinning          • Progress UI      • Rollback index   • Mark pending  │
│   • Version check                                          • Reboot        │
│                                                                              │
│   ┌──────────┐       ┌──────────┐       ┌──────────┐                       │
│   │  Reboot  │──────►│  Verify  │──────►│  Commit  │                       │
│   │          │       │   Boot   │       │   Slot   │                       │
│   └──────────┘       └──────────┘       └──────────┘                       │
│        │                  │                  │                              │
│        ▼                  ▼                  ▼                              │
│   • Boot from        • Secure boot      • If successful:                   │
│     new slot           verifies           mark slot good                   │
│   • If fail:         • dm-verity        • Increment rollback               │
│     auto-rollback      checks             counter                          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.3 Update Package Format

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     OTA PACKAGE FORMAT                                       │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ Header (4KB)                                                        │    │
│  │ ───────────────────────────────────────────────────────────────────│    │
│  │ magic:          "RDSP"                                              │    │
│  │ version:        Package format version                              │    │
│  │ device:         "richdsp-e7"                                        │    │
│  │ from_version:   Minimum current version (or 0 for full)             │    │
│  │ to_version:     Target version                                      │    │
│  │ rollback_index: Anti-rollback counter requirement                   │    │
│  │ payload_size:   Size of compressed payload                          │    │
│  │ payload_hash:   SHA-256 of payload                                  │    │
│  │ signature:      RSA-2048 signature of header                        │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ Payload (variable)                                                  │    │
│  │ ───────────────────────────────────────────────────────────────────│    │
│  │ • boot.img (kernel + ramdisk)                                       │    │
│  │ • system.img (or delta)                                             │    │
│  │ • Compressed with brotli                                            │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Data Protection

### 5.1 File-Based Encryption (FBE)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FILE-BASED ENCRYPTION                                     │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ Device Encryption Key (DEK)                                         │   │
│   │ ───────────────────────────                                         │   │
│   │ • Generated at first boot                                           │   │
│   │ • Stored in hardware keystore (TEE)                                 │   │
│   │ • Wrapped with Key Encryption Key (KEK)                             │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│   Encryption Classes:                                                        │
│   ┌─────────────────┬─────────────────────────────────────────────────────┐ │
│   │ Class           │ When Accessible                                     │ │
│   ├─────────────────┼─────────────────────────────────────────────────────┤ │
│   │ Device (DE)     │ Always (after boot)                                 │ │
│   │ Credential (CE) │ After user unlock (if PIN/password set)             │ │
│   └─────────────────┴─────────────────────────────────────────────────────┘ │
│                                                                              │
│   Protected Data:                                                            │
│   • Music library database (DE - available for background scan)             │
│   • User preferences (DE)                                                   │
│   • Streaming service credentials (CE - requires unlock)                    │
│   • WiFi passwords (CE)                                                     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Credential Storage

```c
/* Secure credential storage via Android Keystore / OP-TEE */

typedef enum {
    CRED_TYPE_WIFI_PSK,
    CRED_TYPE_STREAMING_TOKEN,
    CRED_TYPE_ROON_CERT,
} credential_type_t;

/* Store credential in TEE-backed keystore */
int secure_store_credential(credential_type_t type,
                            const char *identifier,
                            const uint8_t *data,
                            size_t data_len);

/* Retrieve credential (requires device unlock for CE class) */
int secure_get_credential(credential_type_t type,
                          const char *identifier,
                          uint8_t *data,
                          size_t *data_len);

/* Delete credential */
int secure_delete_credential(credential_type_t type,
                             const char *identifier);
```

---

## 6. Network Security

### 6.1 TLS Configuration

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    TLS CONFIGURATION                                         │
│                                                                              │
│   Minimum Version: TLS 1.2 (TLS 1.3 preferred)                              │
│                                                                              │
│   Cipher Suites (in order of preference):                                   │
│   1. TLS_AES_256_GCM_SHA384                    (TLS 1.3)                    │
│   2. TLS_CHACHA20_POLY1305_SHA256              (TLS 1.3)                    │
│   3. TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384   (TLS 1.2)                    │
│   4. TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384     (TLS 1.2)                    │
│                                                                              │
│   Certificate Validation:                                                    │
│   • System CA store + user-installed CAs                                    │
│   • Certificate pinning for RichDSP services                                │
│   • OCSP stapling required                                                  │
│                                                                              │
│   Disabled:                                                                  │
│   • SSL 3.0, TLS 1.0, TLS 1.1                                               │
│   • RC4, DES, 3DES, MD5, SHA-1 for signatures                               │
│   • Export cipher suites                                                    │
│   • Compression (CRIME attack)                                              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 6.2 Network Services

| Service | Port | Security |
|---------|------|----------|
| **OTA Server** | 443 | TLS 1.3 + certificate pinning |
| **DLNA/UPnP** | 1900/UDP | Local network only, no auth |
| **Roon** | 9100-9200 | TLS + Roon certificate |
| **AirPlay** | 7000 | Apple fairplay |
| **SSH (debug)** | 22 | Disabled in production builds |

---

## 7. Debug Security

### 7.1 Debug Port Protection

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    DEBUG PORT SECURITY                                       │
│                                                                              │
│   UART Console:                                                             │
│   ├─ Development builds: Enabled, full shell access                         │
│   ├─ Production builds: Disabled by default                                 │
│   └─ Service mode: Enabled with signed unlock token                         │
│                                                                              │
│   JTAG/SWD:                                                                 │
│   ├─ Development: Enabled                                                   │
│   ├─ Production: Permanently disabled via eFuse                             │
│   └─ Cannot be re-enabled after eFuse blown                                 │
│                                                                              │
│   ADB (Android Debug Bridge):                                               │
│   ├─ Development: Enabled                                                   │
│   ├─ Production: Disabled by default                                        │
│   ├─ User-enabled: Requires Settings toggle + RSA key authorization         │
│   └─ Limited to: app debugging, file transfer (no root shell)              │
│                                                                              │
│   USB Boot Mode:                                                            │
│   ├─ Production: Disabled via eFuse                                         │
│   └─ Prevents loading unsigned firmware via USB                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Service Mode

For warranty repairs and factory service:

```c
/* Service mode unlock requires signed token from RichDSP */
typedef struct {
    uint8_t  device_serial[16];    /* Specific to this device */
    uint32_t unlock_type;          /* UART, ADB root, etc. */
    uint32_t expiry_time;          /* Unix timestamp */
    uint8_t  signature[256];       /* RSA-2048 signature */
} service_unlock_token_t;

/* Token must be signed by RichDSP service key */
/* Token expires after specified time */
/* Token is single-use (nonce stored in RPMB) */
```

---

## 8. Implementation Checklist

### 8.1 Hardware Requirements

| Component | Purpose | Status |
|-----------|---------|--------|
| SoC with TrustZone | Secure boot, TEE | Required |
| eFuses | Key storage, debug disable | Required |
| RPMB partition | Secure storage | Required |
| ATECC608B (per module) | Module authentication | Required |
| Hardware RNG | Entropy source | Required |

### 8.2 Software Components

| Component | Description | Priority |
|-----------|-------------|----------|
| ARM Trusted Firmware | BL2/BL31 | Critical |
| OP-TEE | Trusted Execution Environment | Critical |
| U-Boot with verified boot | BL33 | Critical |
| dm-verity | System partition integrity | Critical |
| Android Verified Boot | Full chain verification | Critical |
| Module auth daemon | Module certificate verification | High |
| OTA client | Secure update handling | High |
| Keystore HAL | Hardware-backed key storage | High |

### 8.3 Manufacturing Requirements

| Step | Description |
|------|-------------|
| **Key ceremony** | Generate and secure root keys in HSM |
| **eFuse programming** | Burn OEM public key hash into SoC |
| **Module provisioning** | Generate and install per-module certificates |
| **Security audit** | Third-party penetration testing before release |

---

## 9. Cost Impact

| Component | Cost Adder |
|-----------|------------|
| ATECC608B per module | +$0.60 |
| HSM for factory provisioning | $5,000-20,000 (one-time) |
| Security audit | $20,000-50,000 (one-time) |
| Certificate infrastructure | $5,000/year |
| **Per-unit impact** | **~$0.70** |

Security adds minimal per-unit cost but requires upfront investment in infrastructure.

---

*Document Version: 1.0.0*
*Status: New Architecture Component*
