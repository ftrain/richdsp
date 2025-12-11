# RichDSP Android Audio HAL Implementation

## 1. Overview

This document specifies the custom Android Audio HAL for the RichDSP platform, enabling bit-perfect audio playback, native DSD support, and seamless integration with the modular DAC system.

---

## 2. Architecture

### 2.1 Audio Path Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ANDROID FRAMEWORK                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │  Third-party    │  │  RichDSP        │  │  System Sounds              │  │
│  │  Music Apps     │  │  Music App      │  │  (notifications, UI)        │  │
│  └────────┬────────┘  └────────┬────────┘  └──────────────┬──────────────┘  │
│           │                    │                          │                  │
│           │ AudioTrack         │ DIRECT flag              │ AudioTrack      │
│           ▼                    ▼                          ▼                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                        AUDIOFLINGER                                      ││
│  │  ┌──────────────────────────────┐  ┌──────────────────────────────────┐ ││
│  │  │      MixerThread             │  │      DirectOutputThread          │ ││
│  │  │  (resamples to 48kHz)        │  │  (bit-perfect passthrough)       │ ││
│  │  └──────────────┬───────────────┘  └───────────────┬──────────────────┘ ││
│  └─────────────────┼──────────────────────────────────┼─────────────────────┘│
└────────────────────┼──────────────────────────────────┼─────────────────────┘
                     │                                  │
                     │ primary_out                      │ direct_out / dsd_out
                     ▼                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         RICHDSP AUDIO HAL                                    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                        audio_hw.c                                        ││
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌───────────┐ ││
│  │  │ Primary       │  │ Direct        │  │ DSD           │  │ Module    │ ││
│  │  │ Output        │  │ Output        │  │ Output        │  │ Manager   │ ││
│  │  │ (mixed)       │  │ (bit-perfect) │  │ (DoP/Native)  │  │           │ ││
│  │  └───────┬───────┘  └───────┬───────┘  └───────┬───────┘  └─────┬─────┘ ││
│  └──────────┼──────────────────┼──────────────────┼────────────────┼────────┘│
│             │                  │                  │                │         │
│  ┌──────────▼──────────────────▼──────────────────▼────────────────┘         │
│  │                     OUTPUT ROUTER                                         │
│  │  • Sample rate switching                                                  │
│  │  • Format conversion (if needed)                                          │
│  │  • Clock source selection                                                 │
│  │  • Volume control (analog preferred)                                      │
│  └──────────────────────────────┬────────────────────────────────────────────│
└─────────────────────────────────┼────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────▼────────────────────────────────────────────┐
│                         KERNEL LAYER                                         │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                    TinyALSA / ALSA Interface                            │ │
│  └─────────────────────────────────┬───────────────────────────────────────┘ │
│  ┌─────────────────────────────────▼───────────────────────────────────────┐ │
│  │                    RichDSP ASoC Codec Driver                            │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │ │
│  │  │  I2S/DSD     │  │  Clock       │  │  DAC I2C     │  │  Module      │ │ │
│  │  │  Controller  │  │  Generator   │  │  Control     │  │  Detection   │ │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Directory Structure

```
hardware/richdsp/audio/
├── Android.bp                    # Build configuration
├── audio_hw.c                    # Main HAL implementation
├── audio_hw.h                    # HAL structures and constants
├── stream_out.c                  # Output stream implementation
├── stream_out.h
├── stream_in.c                   # Input stream (for loopback/ADC)
├── stream_in.h
├── module_manager.c              # DAC module detection/config
├── module_manager.h
├── dac/
│   ├── dac_common.h              # Common DAC interface
│   ├── dac_ak4497.c              # AKM AK4497 driver
│   ├── dac_ak4499.c              # AKM AK4499 driver
│   ├── dac_es9038.c              # ESS ES9038PRO driver
│   ├── dac_pcm1792.c             # TI PCM1792A driver
│   └── dac_ad1955.c              # AD AD1955 driver
├── clock/
│   ├── clock_manager.c           # Clock source management
│   ├── clock_manager.h
│   └── si5351.c                  # Si5351 clock generator driver
├── dsd/
│   ├── dsd_processor.c           # DSD handling (DoP/Native)
│   └── dsd_processor.h
├── volume/
│   ├── volume_control.c          # Volume management
│   └── volume_control.h
└── tests/
    ├── audio_hal_test.cpp        # HAL unit tests
    └── module_test.cpp           # Module detection tests
```

---

## 4. Audio Policy Configuration

### 4.1 audio_policy_configuration.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<audioPolicyConfiguration version="1.0" xmlns:xi="http://www.w3.org/2001/XInclude">
    <globalConfiguration speaker_drc_enabled="false"/>

    <modules>
        <module name="richdsp" halVersion="3.0">
            <attachedDevices>
                <item>Headphones</item>
                <item>Line Out</item>
            </attachedDevices>
            <defaultOutputDevice>Headphones</defaultOutputDevice>

            <mixPorts>
                <!-- Primary output: mixed system audio -->
                <mixPort name="primary_out" role="source"
                         flags="AUDIO_OUTPUT_FLAG_PRIMARY">
                    <profile name="" format="AUDIO_FORMAT_PCM_24_BIT_PACKED"
                             samplingRates="48000"
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
                </mixPort>

                <!-- Direct PCM: bit-perfect, all sample rates -->
                <mixPort name="direct_pcm" role="source"
                         flags="AUDIO_OUTPUT_FLAG_DIRECT">
                    <profile name="" format="AUDIO_FORMAT_PCM_16_BIT"
                             samplingRates="44100,48000,88200,96000,176400,192000"
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
                    <profile name="" format="AUDIO_FORMAT_PCM_24_BIT_PACKED"
                             samplingRates="44100,48000,88200,96000,176400,192000,352800,384000"
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
                    <profile name="" format="AUDIO_FORMAT_PCM_32_BIT"
                             samplingRates="44100,48000,88200,96000,176400,192000,352800,384000,705600,768000"
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
                    <profile name="" format="AUDIO_FORMAT_PCM_FLOAT"
                             samplingRates="44100,48000,88200,96000,176400,192000,352800,384000"
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
                </mixPort>

                <!-- DSD output: DoP and native -->
                <mixPort name="dsd_out" role="source"
                         flags="AUDIO_OUTPUT_FLAG_DIRECT|AUDIO_OUTPUT_FLAG_NON_BLOCKING">
                    <profile name="dsd64" format="AUDIO_FORMAT_DSD"
                             samplingRates="2822400"
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
                    <profile name="dsd128" format="AUDIO_FORMAT_DSD"
                             samplingRates="5644800"
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
                    <profile name="dsd256" format="AUDIO_FORMAT_DSD"
                             samplingRates="11289600"
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
                    <profile name="dsd512" format="AUDIO_FORMAT_DSD"
                             samplingRates="22579200"
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
                </mixPort>

                <!-- Offload for compressed formats -->
                <mixPort name="compressed_offload" role="source"
                         flags="AUDIO_OUTPUT_FLAG_DIRECT|AUDIO_OUTPUT_FLAG_COMPRESS_OFFLOAD|AUDIO_OUTPUT_FLAG_NON_BLOCKING">
                    <profile name="" format="AUDIO_FORMAT_FLAC"
                             samplingRates="44100,48000,88200,96000,176400,192000"
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
                    <profile name="" format="AUDIO_FORMAT_ALAC"
                             samplingRates="44100,48000,88200,96000,176400,192000"
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
                </mixPort>
            </mixPorts>

            <devicePorts>
                <devicePort tagName="Headphones" type="AUDIO_DEVICE_OUT_WIRED_HEADPHONE" role="sink">
                    <profile name="" format="AUDIO_FORMAT_PCM_32_BIT"
                             samplingRates="44100,48000,88200,96000,176400,192000,352800,384000,705600,768000"
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
                </devicePort>
                <devicePort tagName="Line Out" type="AUDIO_DEVICE_OUT_LINE" role="sink">
                    <profile name="" format="AUDIO_FORMAT_PCM_32_BIT"
                             samplingRates="44100,48000,88200,96000,176400,192000,352800,384000,705600,768000"
                             channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>
                </devicePort>
            </devicePorts>

            <routes>
                <route type="mix" sink="Headphones"
                       sources="primary_out,direct_pcm,dsd_out,compressed_offload"/>
                <route type="mix" sink="Line Out"
                       sources="primary_out,direct_pcm,dsd_out,compressed_offload"/>
            </routes>
        </module>
    </modules>
</audioPolicyConfiguration>
```

---

## 5. Core HAL Implementation

### 5.1 Main Header (audio_hw.h)

```c
#ifndef RICHDSP_AUDIO_HW_H
#define RICHDSP_AUDIO_HW_H

#include <hardware/audio.h>
#include <tinyalsa/asoundlib.h>
#include <pthread.h>

/* Output stream types */
typedef enum {
    STREAM_PRIMARY,         /* Mixed system audio (48kHz) */
    STREAM_DIRECT_PCM,      /* Bit-perfect PCM */
    STREAM_DSD_DOP,         /* DSD over PCM */
    STREAM_DSD_NATIVE,      /* Native DSD (if supported) */
} stream_type_t;

/* Volume control modes */
typedef enum {
    VOLUME_DIGITAL,         /* Digital attenuation (in DSP) */
    VOLUME_ANALOG_DAC,      /* DAC internal attenuator */
    VOLUME_ANALOG_PGA,      /* External PGA (best quality) */
    VOLUME_RELAY_LADDER,    /* Relay-switched resistor ladder */
} volume_mode_t;

/* Clock source families */
typedef enum {
    CLOCK_44K_FAMILY,       /* 44.1, 88.2, 176.4, 352.8, 705.6 kHz */
    CLOCK_48K_FAMILY,       /* 48, 96, 192, 384, 768 kHz */
} clock_family_t;

/* Module capabilities (from EEPROM) */
typedef struct {
    uint16_t module_id;
    char     manufacturer[32];
    char     model[32];

    /* Audio capabilities */
    uint32_t max_pcm_rate;
    uint32_t max_dsd_rate;
    uint8_t  max_bit_depth;
    bool     native_dsd;
    bool     dop_supported;

    /* Output specs */
    uint16_t max_voltage_mv;
    uint16_t output_impedance_mohm;

    /* Volume control */
    volume_mode_t volume_mode;
    int8_t   min_volume_db;
    int8_t   max_volume_db;
    float    volume_step_db;

    /* Filter options */
    uint8_t  num_filters;
    const char *filter_names[8];
} module_caps_t;

/* RichDSP device context */
typedef struct {
    struct audio_hw_device device;

    pthread_mutex_t lock;

    /* Module state */
    module_caps_t   module;
    bool            module_present;

    /* Current configuration */
    uint32_t        current_rate;
    audio_format_t  current_format;
    clock_family_t  current_clock;

    /* Output streams */
    struct richdsp_stream_out *primary_out;
    struct richdsp_stream_out *direct_out;

    /* Hardware interfaces */
    int             i2c_fd;          /* DAC control */
    int             clock_fd;        /* Clock generator */

    /* Settings */
    float           master_volume;
    uint8_t         digital_filter;
    bool            phase_invert;
    bool            dsd_native_mode;

} richdsp_audio_device_t;

/* Output stream context */
typedef struct richdsp_stream_out {
    struct audio_stream_out stream;

    richdsp_audio_device_t *dev;
    stream_type_t           type;

    pthread_mutex_t         lock;

    /* ALSA */
    struct pcm             *pcm;
    struct pcm_config       pcm_config;

    /* Stream config */
    audio_format_t          format;
    uint32_t                sample_rate;
    audio_channel_mask_t    channel_mask;
    size_t                  buffer_size;

    /* State */
    bool                    standby;
    uint64_t                frames_written;

    /* DSD state (if applicable) */
    bool                    dsd_mode;
    uint8_t                *dop_buffer;
    size_t                  dop_buffer_size;

} richdsp_stream_out_t;

/* Function prototypes */
int richdsp_open_pcm(richdsp_stream_out_t *out);
void richdsp_close_pcm(richdsp_stream_out_t *out);
int richdsp_set_sample_rate(richdsp_audio_device_t *dev, uint32_t rate);
int richdsp_configure_dac(richdsp_audio_device_t *dev);
int richdsp_set_volume(richdsp_audio_device_t *dev, float volume);
int richdsp_detect_module(richdsp_audio_device_t *dev);

#endif /* RICHDSP_AUDIO_HW_H */
```

### 5.2 Main HAL Implementation (audio_hw.c)

```c
#define LOG_TAG "richdsp_audio_hw"

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/ioctl.h>

#include <log/log.h>
#include <cutils/properties.h>

#include "audio_hw.h"
#include "module_manager.h"
#include "clock/clock_manager.h"
#include "dsd/dsd_processor.h"
#include "volume/volume_control.h"

/* ALSA card/device numbers */
#define CARD_RICHDSP        0
#define DEVICE_PRIMARY      0
#define DEVICE_DIRECT       1
#define DEVICE_DSD          2

/* PCM configuration defaults */
#define DEFAULT_PERIOD_SIZE     1024
#define DEFAULT_PERIOD_COUNT    4
#define DEEP_BUFFER_PERIOD_SIZE 1920
#define DEEP_BUFFER_PERIOD_COUNT 8

/* ========================================================================== */
/*                           DEVICE OPERATIONS                                 */
/* ========================================================================== */

static int adev_init_check(const struct audio_hw_device *dev)
{
    richdsp_audio_device_t *adev = (richdsp_audio_device_t *)dev;
    return adev->module_present ? 0 : -ENODEV;
}

static int adev_set_master_volume(struct audio_hw_device *dev, float volume)
{
    richdsp_audio_device_t *adev = (richdsp_audio_device_t *)dev;

    pthread_mutex_lock(&adev->lock);
    adev->master_volume = volume;

    int ret = richdsp_set_volume(adev, volume);

    pthread_mutex_unlock(&adev->lock);
    return ret;
}

static int adev_get_master_volume(struct audio_hw_device *dev, float *volume)
{
    richdsp_audio_device_t *adev = (richdsp_audio_device_t *)dev;
    *volume = adev->master_volume;
    return 0;
}

static int adev_set_parameters(struct audio_hw_device *dev, const char *kvpairs)
{
    richdsp_audio_device_t *adev = (richdsp_audio_device_t *)dev;
    struct str_parms *parms = str_parms_create_str(kvpairs);
    char value[32];
    int ret = 0;

    pthread_mutex_lock(&adev->lock);

    /* Digital filter selection */
    if (str_parms_get_str(parms, "richdsp_filter", value, sizeof(value)) >= 0) {
        int filter = atoi(value);
        if (filter >= 0 && filter < adev->module.num_filters) {
            adev->digital_filter = filter;
            richdsp_configure_dac(adev);
            ALOGD("Digital filter set to %d (%s)",
                  filter, adev->module.filter_names[filter]);
        }
    }

    /* Phase inversion */
    if (str_parms_get_str(parms, "richdsp_phase_invert", value, sizeof(value)) >= 0) {
        adev->phase_invert = (strcmp(value, "true") == 0);
        richdsp_configure_dac(adev);
    }

    /* DSD mode preference */
    if (str_parms_get_str(parms, "richdsp_dsd_mode", value, sizeof(value)) >= 0) {
        if (strcmp(value, "native") == 0 && adev->module.native_dsd) {
            adev->dsd_native_mode = true;
        } else {
            adev->dsd_native_mode = false; /* Fall back to DoP */
        }
    }

    pthread_mutex_unlock(&adev->lock);
    str_parms_destroy(parms);
    return ret;
}

/* ========================================================================== */
/*                         OUTPUT STREAM OPERATIONS                            */
/* ========================================================================== */

static uint32_t out_get_sample_rate(const struct audio_stream *stream)
{
    richdsp_stream_out_t *out = (richdsp_stream_out_t *)stream;
    return out->sample_rate;
}

static int out_set_sample_rate(struct audio_stream *stream, uint32_t rate)
{
    /* Sample rate is set at stream open, not dynamically */
    return -ENOSYS;
}

static size_t out_get_buffer_size(const struct audio_stream *stream)
{
    richdsp_stream_out_t *out = (richdsp_stream_out_t *)stream;
    return out->buffer_size;
}

static audio_channel_mask_t out_get_channels(const struct audio_stream *stream)
{
    richdsp_stream_out_t *out = (richdsp_stream_out_t *)stream;
    return out->channel_mask;
}

static audio_format_t out_get_format(const struct audio_stream *stream)
{
    richdsp_stream_out_t *out = (richdsp_stream_out_t *)stream;
    return out->format;
}

static int out_standby(struct audio_stream *stream)
{
    richdsp_stream_out_t *out = (richdsp_stream_out_t *)stream;

    pthread_mutex_lock(&out->lock);

    if (!out->standby) {
        richdsp_close_pcm(out);
        out->standby = true;
        ALOGD("Stream entered standby");
    }

    pthread_mutex_unlock(&out->lock);
    return 0;
}

static ssize_t out_write(struct audio_stream_out *stream,
                         const void *buffer, size_t bytes)
{
    richdsp_stream_out_t *out = (richdsp_stream_out_t *)stream;
    richdsp_audio_device_t *adev = out->dev;
    ssize_t ret = 0;

    pthread_mutex_lock(&out->lock);

    /* Exit standby if needed */
    if (out->standby) {
        pthread_mutex_lock(&adev->lock);

        /* Switch sample rate if different from current */
        if (out->sample_rate != adev->current_rate) {
            ret = richdsp_set_sample_rate(adev, out->sample_rate);
            if (ret < 0) {
                ALOGE("Failed to set sample rate to %u", out->sample_rate);
                pthread_mutex_unlock(&adev->lock);
                pthread_mutex_unlock(&out->lock);
                return ret;
            }
        }

        pthread_mutex_unlock(&adev->lock);

        ret = richdsp_open_pcm(out);
        if (ret < 0) {
            pthread_mutex_unlock(&out->lock);
            return ret;
        }
        out->standby = false;
    }

    /* Handle DSD specially */
    if (out->dsd_mode) {
        if (adev->dsd_native_mode && adev->module.native_dsd) {
            /* Native DSD path */
            ret = pcm_write(out->pcm, buffer, bytes);
        } else {
            /* DoP encapsulation */
            size_t dop_bytes = dsd_to_dop(buffer, bytes,
                                          out->dop_buffer, out->dop_buffer_size);
            ret = pcm_write(out->pcm, out->dop_buffer, dop_bytes);
            /* Adjust return value to reflect input bytes consumed */
            if (ret >= 0) ret = bytes;
        }
    } else {
        /* PCM path - bit-perfect */
        ret = pcm_write(out->pcm, buffer, bytes);
    }

    if (ret >= 0) {
        out->frames_written += bytes / audio_stream_out_frame_size(stream);
    } else {
        ALOGE("pcm_write error: %s", pcm_get_error(out->pcm));
    }

    pthread_mutex_unlock(&out->lock);
    return ret;
}

static int out_get_presentation_position(const struct audio_stream_out *stream,
                                         uint64_t *frames,
                                         struct timespec *timestamp)
{
    richdsp_stream_out_t *out = (richdsp_stream_out_t *)stream;
    int ret = -ENODATA;

    pthread_mutex_lock(&((richdsp_stream_out_t *)out)->lock);

    if (out->pcm) {
        unsigned int avail;
        if (pcm_get_htimestamp(out->pcm, &avail, timestamp) == 0) {
            size_t kernel_buffer_size = out->pcm_config.period_size *
                                        out->pcm_config.period_count;
            int64_t signed_frames = out->frames_written - kernel_buffer_size + avail;
            if (signed_frames >= 0) {
                *frames = signed_frames;
                ret = 0;
            }
        }
    }

    pthread_mutex_unlock(&((richdsp_stream_out_t *)out)->lock);
    return ret;
}

/* ========================================================================== */
/*                           OPEN OUTPUT STREAM                                */
/* ========================================================================== */

static int adev_open_output_stream(struct audio_hw_device *dev,
                                   audio_io_handle_t handle,
                                   audio_devices_t devices,
                                   audio_output_flags_t flags,
                                   struct audio_config *config,
                                   struct audio_stream_out **stream_out,
                                   const char *address)
{
    richdsp_audio_device_t *adev = (richdsp_audio_device_t *)dev;
    richdsp_stream_out_t *out;
    int ret;

    ALOGD("open_output_stream: rate=%u, format=%#x, channels=%#x, flags=%#x",
          config->sample_rate, config->format, config->channel_mask, flags);

    out = calloc(1, sizeof(richdsp_stream_out_t));
    if (!out) return -ENOMEM;

    out->dev = adev;
    pthread_mutex_init(&out->lock, NULL);

    /* Determine stream type based on flags */
    if (flags & AUDIO_OUTPUT_FLAG_DIRECT) {
        if (config->format == AUDIO_FORMAT_DSD) {
            out->type = adev->dsd_native_mode ? STREAM_DSD_NATIVE : STREAM_DSD_DOP;
            out->dsd_mode = true;

            /* Allocate DoP buffer if needed */
            if (!adev->dsd_native_mode) {
                out->dop_buffer_size = DEFAULT_PERIOD_SIZE * DEFAULT_PERIOD_COUNT * 4;
                out->dop_buffer = malloc(out->dop_buffer_size);
                if (!out->dop_buffer) {
                    free(out);
                    return -ENOMEM;
                }
            }

            ALOGD("Opening DSD stream (%s mode)",
                  out->type == STREAM_DSD_NATIVE ? "native" : "DoP");
        } else {
            out->type = STREAM_DIRECT_PCM;
            out->dsd_mode = false;
            ALOGD("Opening direct PCM stream (bit-perfect)");
        }
    } else {
        out->type = STREAM_PRIMARY;
        out->dsd_mode = false;
        /* Primary output always 48kHz for mixing compatibility */
        config->sample_rate = 48000;
        config->format = AUDIO_FORMAT_PCM_24_BIT_PACKED;
        ALOGD("Opening primary (mixed) stream");
    }

    /* Validate and set configuration */
    out->sample_rate = config->sample_rate;
    out->format = config->format;
    out->channel_mask = config->channel_mask;

    /* Check against module capabilities */
    if (out->sample_rate > adev->module.max_pcm_rate && !out->dsd_mode) {
        ALOGE("Requested rate %u exceeds module max %u",
              out->sample_rate, adev->module.max_pcm_rate);
        free(out->dop_buffer);
        free(out);
        return -EINVAL;
    }

    /* Set up PCM config */
    out->pcm_config.channels = audio_channel_count_from_out_mask(out->channel_mask);
    out->pcm_config.rate = out->sample_rate;
    out->pcm_config.period_size = (out->type == STREAM_PRIMARY) ?
                                   DEEP_BUFFER_PERIOD_SIZE : DEFAULT_PERIOD_SIZE;
    out->pcm_config.period_count = (out->type == STREAM_PRIMARY) ?
                                    DEEP_BUFFER_PERIOD_COUNT : DEFAULT_PERIOD_COUNT;
    out->pcm_config.format = pcm_format_from_audio_format(out->format);

    /* Calculate buffer size */
    out->buffer_size = out->pcm_config.period_size *
                       out->pcm_config.period_count *
                       out->pcm_config.channels *
                       audio_bytes_per_sample(out->format);

    /* Set up stream ops */
    out->stream.common.get_sample_rate = out_get_sample_rate;
    out->stream.common.set_sample_rate = out_set_sample_rate;
    out->stream.common.get_buffer_size = out_get_buffer_size;
    out->stream.common.get_channels = out_get_channels;
    out->stream.common.get_format = out_get_format;
    out->stream.common.standby = out_standby;
    out->stream.common.set_parameters = out_set_parameters_stream;
    out->stream.common.get_parameters = out_get_parameters_stream;
    out->stream.write = out_write;
    out->stream.get_latency = out_get_latency;
    out->stream.get_presentation_position = out_get_presentation_position;
    /* ... additional ops ... */

    out->standby = true;

    *stream_out = &out->stream;
    return 0;
}

/* ========================================================================== */
/*                             MODULE OPEN/CLOSE                               */
/* ========================================================================== */

static int adev_close(hw_device_t *device)
{
    richdsp_audio_device_t *adev = (richdsp_audio_device_t *)device;

    if (adev->i2c_fd >= 0) close(adev->i2c_fd);
    if (adev->clock_fd >= 0) close(adev->clock_fd);

    pthread_mutex_destroy(&adev->lock);
    free(adev);

    return 0;
}

static int adev_open(const hw_module_t *module, const char *name,
                     hw_device_t **device)
{
    richdsp_audio_device_t *adev;

    if (strcmp(name, AUDIO_HARDWARE_INTERFACE) != 0)
        return -EINVAL;

    adev = calloc(1, sizeof(richdsp_audio_device_t));
    if (!adev) return -ENOMEM;

    pthread_mutex_init(&adev->lock, NULL);

    /* Initialize hardware interfaces */
    adev->i2c_fd = open("/dev/i2c-1", O_RDWR);
    if (adev->i2c_fd < 0) {
        ALOGE("Failed to open I2C bus: %s", strerror(errno));
    }

    /* Detect and initialize module */
    if (richdsp_detect_module(adev) == 0) {
        adev->module_present = true;
        ALOGI("Module detected: %s %s",
              adev->module.manufacturer, adev->module.model);

        /* Initial DAC configuration */
        richdsp_configure_dac(adev);
    } else {
        adev->module_present = false;
        ALOGW("No audio module detected!");
    }

    /* Initialize clock generator */
    clock_manager_init(adev);

    /* Set up device ops */
    adev->device.common.tag = HARDWARE_DEVICE_TAG;
    adev->device.common.version = AUDIO_DEVICE_API_VERSION_3_0;
    adev->device.common.module = (hw_module_t *)module;
    adev->device.common.close = adev_close;

    adev->device.init_check = adev_init_check;
    adev->device.set_master_volume = adev_set_master_volume;
    adev->device.get_master_volume = adev_get_master_volume;
    adev->device.set_parameters = adev_set_parameters;
    adev->device.get_parameters = adev_get_parameters;
    adev->device.open_output_stream = adev_open_output_stream;
    adev->device.close_output_stream = adev_close_output_stream;
    /* ... additional ops ... */

    /* Defaults */
    adev->master_volume = 1.0f;
    adev->digital_filter = 0;
    adev->phase_invert = false;
    adev->dsd_native_mode = false;
    adev->current_rate = 48000;

    *device = &adev->device.common;
    return 0;
}

static struct hw_module_methods_t hal_module_methods = {
    .open = adev_open,
};

struct audio_module HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = AUDIO_MODULE_API_VERSION_0_1,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = AUDIO_HARDWARE_MODULE_ID,
        .name = "RichDSP Audio HAL",
        .author = "RichDSP Team",
        .methods = &hal_module_methods,
    },
};
```

---

## 6. Sample Rate Switching

### 6.1 Clock Manager (clock_manager.c)

```c
#include "clock_manager.h"
#include "si5351.h"

/* Master clock frequencies for each family */
#define MCLK_44K_FAMILY     22579200    /* 22.5792 MHz (512 * 44100) */
#define MCLK_48K_FAMILY     24576000    /* 24.576 MHz (512 * 48000) */

/* Rate-to-divisor mapping */
static const struct {
    uint32_t rate;
    clock_family_t family;
    uint8_t mclk_divisor;   /* MCLK = base_freq / divisor */
} rate_config[] = {
    { 44100,   CLOCK_44K_FAMILY, 1 },
    { 48000,   CLOCK_48K_FAMILY, 1 },
    { 88200,   CLOCK_44K_FAMILY, 1 },
    { 96000,   CLOCK_48K_FAMILY, 1 },
    { 176400,  CLOCK_44K_FAMILY, 1 },
    { 192000,  CLOCK_48K_FAMILY, 1 },
    { 352800,  CLOCK_44K_FAMILY, 1 },
    { 384000,  CLOCK_48K_FAMILY, 1 },
    { 705600,  CLOCK_44K_FAMILY, 1 },
    { 768000,  CLOCK_48K_FAMILY, 1 },
    /* DSD rates */
    { 2822400,  CLOCK_44K_FAMILY, 1 },  /* DSD64 */
    { 5644800,  CLOCK_44K_FAMILY, 1 },  /* DSD128 */
    { 11289600, CLOCK_44K_FAMILY, 1 },  /* DSD256 */
    { 22579200, CLOCK_44K_FAMILY, 1 },  /* DSD512 */
};

int richdsp_set_sample_rate(richdsp_audio_device_t *dev, uint32_t rate)
{
    clock_family_t target_family = CLOCK_48K_FAMILY;
    int ret;

    /* Find matching rate config */
    for (int i = 0; i < ARRAY_SIZE(rate_config); i++) {
        if (rate_config[i].rate == rate) {
            target_family = rate_config[i].family;
            break;
        }
    }

    /* Only switch clock if family changed */
    if (target_family != dev->current_clock) {
        ALOGD("Switching clock family from %s to %s",
              dev->current_clock == CLOCK_44K_FAMILY ? "44.1k" : "48k",
              target_family == CLOCK_44K_FAMILY ? "44.1k" : "48k");

        uint32_t mclk = (target_family == CLOCK_44K_FAMILY) ?
                         MCLK_44K_FAMILY : MCLK_48K_FAMILY;

        /* Mute during clock switch to avoid glitches */
        dac_mute(dev, true);

        /* Switch clock source */
        ret = si5351_set_frequency(dev->clock_fd, SI5351_CLK0, mclk);
        if (ret < 0) {
            ALOGE("Failed to set clock frequency");
            return ret;
        }

        /* Allow clock to stabilize */
        usleep(10000);  /* 10ms */

        /* Update DAC for new sample rate */
        ret = dac_set_sample_rate(dev, rate);
        if (ret < 0) {
            ALOGE("Failed to configure DAC for rate %u", rate);
            return ret;
        }

        dev->current_clock = target_family;

        /* Unmute */
        dac_mute(dev, false);
    }

    dev->current_rate = rate;
    ALOGD("Sample rate set to %u Hz", rate);
    return 0;
}
```

---

## 7. Module Manager

### 7.1 Module Detection and Configuration (module_manager.c)

```c
#include "module_manager.h"
#include "dac/dac_common.h"

/* EEPROM address on module */
#define MODULE_EEPROM_ADDR      0x50
#define MODULE_EEPROM_MAGIC     0x52444350  /* "RDCP" */

/* Supported DAC drivers */
static const dac_driver_t *dac_drivers[] = {
    &dac_ak4497_driver,
    &dac_ak4499_driver,
    &dac_es9038_driver,
    &dac_pcm1792_driver,
    &dac_ad1955_driver,
    NULL
};

int richdsp_detect_module(richdsp_audio_device_t *dev)
{
    ModuleDescriptor desc;
    int ret;

    /* Read EEPROM header */
    ret = i2c_read(dev->i2c_fd, MODULE_EEPROM_ADDR, 0, &desc, sizeof(desc));
    if (ret < 0) {
        ALOGW("Failed to read module EEPROM: %s", strerror(errno));
        return -ENODEV;
    }

    /* Validate magic number */
    if (desc.magic != MODULE_EEPROM_MAGIC) {
        ALOGW("Invalid module magic: 0x%08x (expected 0x%08x)",
              desc.magic, MODULE_EEPROM_MAGIC);
        return -EINVAL;
    }

    /* Verify CRC */
    uint32_t calc_crc = crc32(&desc, offsetof(ModuleDescriptor, crc32));
    if (calc_crc != desc.crc32) {
        ALOGE("Module EEPROM CRC mismatch");
        return -EILSEQ;
    }

    /* Populate module caps */
    dev->module.module_id = desc.module_id;
    strncpy(dev->module.manufacturer, desc.manufacturer, 31);
    strncpy(dev->module.model, desc.model_name, 31);

    dev->module.max_pcm_rate = desc.max_pcm_rate;
    dev->module.max_dsd_rate = desc.max_dsd_rate;
    dev->module.max_bit_depth = desc.bit_depth;
    dev->module.max_voltage_mv = desc.output_voltage_mv;
    dev->module.output_impedance_mohm = desc.output_impedance;

    /* Find matching DAC driver */
    for (int i = 0; dac_drivers[i] != NULL; i++) {
        if (dac_drivers[i]->dac_type == desc.dac_type &&
            dac_drivers[i]->dac_model == desc.dac_model) {
            dev->dac_driver = dac_drivers[i];
            ALOGI("Using DAC driver: %s", dac_drivers[i]->name);
            break;
        }
    }

    if (!dev->dac_driver) {
        ALOGW("No specific driver for DAC type %d model %d, using generic",
              desc.dac_type, desc.dac_model);
        dev->dac_driver = &dac_generic_driver;
    }

    /* Load DAC-specific capabilities */
    dev->module.native_dsd = dev->dac_driver->supports_native_dsd;
    dev->module.dop_supported = dev->dac_driver->supports_dop;
    dev->module.num_filters = dev->dac_driver->num_filters;
    for (int i = 0; i < dev->module.num_filters; i++) {
        dev->module.filter_names[i] = dev->dac_driver->filter_names[i];
    }

    return 0;
}

int richdsp_configure_dac(richdsp_audio_device_t *dev)
{
    if (!dev->dac_driver) return -ENODEV;

    dac_config_t config = {
        .sample_rate = dev->current_rate,
        .bit_depth = 32,
        .filter = dev->digital_filter,
        .phase_invert = dev->phase_invert,
        .dsd_mode = false,
    };

    return dev->dac_driver->configure(dev->i2c_fd, &config);
}
```

---

## 8. Build Configuration

### 8.1 Android.bp

```
cc_library_shared {
    name: "audio.primary.richdsp",
    relative_install_path: "hw",
    vendor: true,

    srcs: [
        "audio_hw.c",
        "stream_out.c",
        "stream_in.c",
        "module_manager.c",
        "dac/dac_ak4497.c",
        "dac/dac_ak4499.c",
        "dac/dac_es9038.c",
        "dac/dac_pcm1792.c",
        "dac/dac_ad1955.c",
        "clock/clock_manager.c",
        "clock/si5351.c",
        "dsd/dsd_processor.c",
        "volume/volume_control.c",
    ],

    include_dirs: [
        "external/tinyalsa/include",
    ],

    shared_libs: [
        "liblog",
        "libcutils",
        "libtinyalsa",
        "libhardware",
    ],

    cflags: [
        "-Wall",
        "-Werror",
        "-Wno-unused-parameter",
    ],
}
```

---

## 9. SELinux Policy

### 9.1 file_contexts

```
/dev/richdsp_audio      u:object_r:audio_device:s0
/dev/i2c-[0-9]+         u:object_r:i2c_device:s0
/sys/devices/platform/richdsp-clock(/.*)?   u:object_r:sysfs_audio:s0
```

### 9.2 richdsp_audio.te

```
# Audio HAL domain
type richdsp_audio, domain;
type richdsp_audio_exec, exec_type, vendor_file_type, file_type;

# Allow HAL to access audio devices
allow richdsp_audio audio_device:chr_file rw_file_perms;

# Allow I2C access for DAC control
allow richdsp_audio i2c_device:chr_file rw_file_perms;

# Allow sysfs access for clock control
allow richdsp_audio sysfs_audio:file rw_file_perms;

# Allow binder communication with audioserver
binder_use(richdsp_audio)
binder_call(richdsp_audio, audioserver)
```

---

## 10. Testing

### 10.1 HAL Test Suite

```cpp
// audio_hal_test.cpp
#include <gtest/gtest.h>
#include <hardware/audio.h>

class AudioHalTest : public ::testing::Test {
protected:
    audio_hw_device_t *device = nullptr;

    void SetUp() override {
        const hw_module_t *module;
        int ret = hw_get_module(AUDIO_HARDWARE_MODULE_ID, &module);
        ASSERT_EQ(0, ret);

        ret = audio_hw_device_open(module, &device);
        ASSERT_EQ(0, ret);
    }

    void TearDown() override {
        if (device) {
            audio_hw_device_close(device);
        }
    }
};

TEST_F(AudioHalTest, InitCheck) {
    EXPECT_EQ(0, device->init_check(device));
}

TEST_F(AudioHalTest, OpenDirectStream_44100) {
    audio_stream_out *stream;
    audio_config config = {
        .sample_rate = 44100,
        .format = AUDIO_FORMAT_PCM_24_BIT_PACKED,
        .channel_mask = AUDIO_CHANNEL_OUT_STEREO,
    };

    int ret = device->open_output_stream(device, 0, AUDIO_DEVICE_OUT_WIRED_HEADPHONE,
                                         AUDIO_OUTPUT_FLAG_DIRECT, &config,
                                         &stream, nullptr);
    EXPECT_EQ(0, ret);
    EXPECT_EQ(44100u, stream->common.get_sample_rate(&stream->common));

    device->close_output_stream(device, stream);
}

TEST_F(AudioHalTest, OpenDirectStream_384000) {
    audio_stream_out *stream;
    audio_config config = {
        .sample_rate = 384000,
        .format = AUDIO_FORMAT_PCM_32_BIT,
        .channel_mask = AUDIO_CHANNEL_OUT_STEREO,
    };

    int ret = device->open_output_stream(device, 0, AUDIO_DEVICE_OUT_WIRED_HEADPHONE,
                                         AUDIO_OUTPUT_FLAG_DIRECT, &config,
                                         &stream, nullptr);
    EXPECT_EQ(0, ret);
    EXPECT_EQ(384000u, stream->common.get_sample_rate(&stream->common));

    device->close_output_stream(device, stream);
}

TEST_F(AudioHalTest, OpenDsdStream) {
    audio_stream_out *stream;
    audio_config config = {
        .sample_rate = 2822400,  // DSD64
        .format = AUDIO_FORMAT_DSD,
        .channel_mask = AUDIO_CHANNEL_OUT_STEREO,
    };

    int ret = device->open_output_stream(device, 0, AUDIO_DEVICE_OUT_WIRED_HEADPHONE,
                                         AUDIO_OUTPUT_FLAG_DIRECT, &config,
                                         &stream, nullptr);
    EXPECT_EQ(0, ret);

    device->close_output_stream(device, stream);
}

TEST_F(AudioHalTest, VolumeControl) {
    EXPECT_EQ(0, device->set_master_volume(device, 0.5f));

    float volume;
    EXPECT_EQ(0, device->get_master_volume(device, &volume));
    EXPECT_FLOAT_EQ(0.5f, volume);
}
```

---

*Document Version: 0.1.0-draft*
*Last Updated: 2024*
*Status: Implementation Specification*
