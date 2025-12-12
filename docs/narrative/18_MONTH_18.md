# Month 18: Launch

*"Shipping is a feature."*
*— Joel Spolsky*

---

## Launch Day

December 12th. 9:00 AM Pacific Time.

Victoria Sterling stood in the warehouse, surrounded by pallets of boxed RichDSP players. Eighteen months of work, stacked in neat rows, ready to go to customers around the world.

She pressed send on the launch email:

*Dear RichDSP Community,*

*Today, we ship.*

*Eighteen months ago, we set out to build the finest portable audio player ever made. Today, the first units are on their way to you.*

*Inside each box, you'll find not just a product, but a promise: the promise that your music deserves better. Better clocks, better analog design, better modularity. The promise that you can upgrade without replacing.*

*Thank you for believing in us before you could hold the product in your hands. That trust carried us through technical challenges, budget crises, and more than a few sleepless nights.*

*Now it's your turn. Listen. Discover details in your favorite recordings you never knew existed. And tell us what you think—your feedback shapes our roadmap.*

*The adventure begins.*

*Victoria Sterling*
*CEO, RichDSP*

---

## The First Hours

Within an hour of launch, the website crashed.

Traffic exceeded projections by 400%. The Shopify infrastructure held, but the custom pages displaying product information buckled under the load.

"CDN," Aisha diagnosed. "The images aren't cached. Every visitor is hitting the origin server."

Tom had it fixed in twenty minutes—emergency cache configuration push. The site stabilized.

By noon Pacific:
- 487 new orders (beyond pre-orders)
- $723,000 in new revenue
- 12,000 unique website visitors
- #3 trending on Twitter (tech category)

The Head-Fi thread had grown to 47 pages of discussion. Most reactions were positive:

*"Mine just shipped! Tracking says Friday!"*

*"The measurements in the reviews are insane. Can't wait to hear this thing."*

*"$1,500 is a lot, but for that SNR and the module system? I'm in."*

Some skepticism remained:

*"Let's see how many survive the first week. Startups promising the moon usually disappoint."*

*"Why would I buy this when my Sony sounds great?"*

*"The UI looks terrible in the screenshots. Android really?"*

Victoria read every comment. The critics weren't wrong about the UI—it was functional, not beautiful. But that was fixable. What mattered today was that the hardware worked.

---

## The First Shipments

Wave 1 began shipping at 2 PM.

The Collector tier customers—248 units—went out first. FedEx overnight for US customers, DHL Express for international.

Each shipment triggered:
- Tracking email to customer
- Internal database update
- Social media notification (for opted-in customers)

By 5 PM, all 248 Collector units were on trucks.

Wave 2 started the next morning—400 units to With Module tier customers. Then the remaining pre-orders throughout the week.

James Morrison watched the shipping dashboard like a hawk:

```
SHIPMENT STATUS - LAUNCH WEEK

Day 1: 248 shipped (Collector tier)
Day 2: 400 shipped (Module tier, part 1)
Day 3: 287 shipped (Module tier, part 2)
Day 4: 312 shipped (Player tier)
Day 5: Buffer day (stragglers, verification)

Total pre-orders shipped: 1,247
Average time to ship: 2.8 days
Fastest ship: 4 hours (local customer, walked in to pick up)
```

---

## The First Support Tickets

Day 2. The support tickets started arriving.

**Ticket #001**: "My unit won't power on."

Engineering grabbed the unit's serial number, pulled the test logs. The unit had passed all tests in production. Remote diagnostics showed... nothing. Unit was genuinely dead.

DOA. Dead on arrival. It happened.

Victoria personally called the customer, apologized, and arranged overnight replacement. The customer was understanding—things happen. A replacement shipped that afternoon.

**Ticket #002**: "Audio crackles during DSD playback."

The HAL team investigated. The customer was using an obscure music app that didn't properly handle DSD buffer sizes. The crackle occurred when the buffer underran.

Workaround: Use a different app, or adjust buffer size in settings. Fix planned for firmware 1.0.2.

**Ticket #003**: "The module won't stay locked. It pops out when I walk."

Mechanical issue. The ejector spring was too weak on this unit—manufacturing tolerance at the edge of spec.

The customer received a replacement module housing with properly-tensioned spring. The defective unit was returned for analysis.

**Ticket #004-#007**: Various questions about firmware update, WiFi setup, app compatibility. All resolved with FAQ links.

**Ticket #008**: "This is amazing. Just wanted to say thank you."

Marcus printed that one and taped it to the whiteboard.

---

## Hardware Team Report

### Director of Hardware Engineering: Marcus Chen

**Status**: Launch complete. Monitoring production quality.

**Launch Week Metrics**

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Units shipped | 1,487 | 1,247 | EXCEEDED |
| DOA reports | 4 | <6 (0.5%) | ON TARGET |
| Support tickets | 23 | <50 | ON TARGET |
| Social media sentiment | 87% positive | >80% | ON TARGET |

**DOA Analysis**

Four DOA reports in 1,487 shipments = 0.27% DOA rate. Below our 0.5% target.

Root causes:
- 1 unit: Dead display (damaged in shipping)
- 1 unit: Won't power on (unknown; unit in transit for analysis)
- 1 unit: Module connector damaged (bent pins)
- 1 unit: Intermittent power button (mechanical defect)

All customers received replacements within 48 hours.

**Production Continuation**

Assembly continues to build retail inventory:
- Current inventory: 2,181 players, 752 modules
- Daily production: ~80 players, ~50 modules
- Target retail inventory: 1,000 players, 500 modules by Month 19

---

### Lead Analog Audio Engineer: Dr. Sarah Okonkwo

**Status**: Performance validation on shipped units

I requested return shipping for three randomly selected customer units (with customer permission and loaner units provided). Testing validated production consistency:

| Unit | THD+N | SNR | Crosstalk |
|------|-------|-----|-----------|
| SN 00123 | 0.000028% | 131.4 dB | 125 dB |
| SN 00456 | 0.000026% | 132.1 dB | 127 dB |
| SN 00891 | 0.000029% | 131.0 dB | 124 dB |
| **Spec** | **<0.00003%** | **>130 dB** | **>120 dB** |

All units exceed specification. Production is under control.

**Interesting Note**: Unit SN 00456 measured better than our golden reference. Some production variation lands on the good side.

---

## Software Team Report

### Lead Software Architect: Aisha Rahman

**Status**: Firmware 1.0.1 successfully deployed. 1.0.2 in development.

**OTA Update Statistics**

| Metric | Value |
|--------|-------|
| Units eligible for update | 1,487 |
| Updates downloaded | 1,412 (95%) |
| Updates installed | 1,389 (93%) |
| Update failures | 8 (<1%) |
| Average download time | 4.2 minutes |
| Average install time | 5.1 minutes |

The 8 update failures were all recoverable—users retried and succeeded. No bricked devices.

**Firmware 1.0.2 Changes (In Development)**

1. Fix DSD buffer underrun with certain apps
2. Improve WiFi reconnection after sleep
3. Add Bluetooth battery level reporting
4. Reduce boot time by 3 seconds

Target release: Month 19, Week 2.

---

### Senior HAL Engineer: Priya Nair

**Status**: Module ecosystem planning

With launch complete, we're planning the module roadmap:

**Confirmed Modules**

| Module | DAC | Target Price | ETA |
|--------|-----|--------------|-----|
| Precision (ES9038PRO) | ESS | $349 | Month 21 |
| Classic (PCM1792) | TI | $249 | Month 20 |

**Potential Modules (Market Research)**

| Module | DAC/Type | Interest Level | Feasibility |
|--------|----------|----------------|-------------|
| Tube Output | Hybrid tube stage | High | Medium (thermal challenges) |
| R2R Discrete | Custom ladder | Very High | High (was cut from launch) |
| Balanced Pro | Dual ES9038 | Medium | High |
| Mobile (lower power) | AK4493 | Medium | High |

The R2R module is the most requested feature in customer surveys. We're evaluating whether to resurrect the design.

---

## The Reviews Roll In

Day 5. The professional reviews published.

**Stereophile** (4.5/5 stars):
*"RichDSP has delivered on its promises. The measured performance is among the best we've seen from any portable source, and the modular system works flawlessly. The only demerits are the pedestrian UI and premium price. For serious listeners, this is the new reference."*

**What Hi-Fi** (5/5 stars):
*"Exceptional audio quality. The blackest background we've heard from a portable. The module system is genius—we can't wait to see what other options emerge. If you can afford it, buy it."*

**The Verge** (8/10):
*"A niche product done excellently. The RichDSP won't replace your phone for casual listening, but for audiophiles who care about every last decibel, it's a revelation. The modular approach is unique and well-executed."*

**Head-Fi Community Review** (Top 10%):
*"I've owned Chord Hugo, Sony WM1Z, and Astell&Kern SP2000. This beats them all on measured performance and matches them on subjective quality. The module system is the future."*

The Head-Fi review thread had grown to 200 pages. User impressions were overwhelmingly positive. The forum's "most anticipated" poll showed RichDSP at #1.

---

## The Unexpected Problem

Day 7. A Head-Fi user posted:

*"Anyone else getting a faint buzz when using balanced output with IEMs?"*

Within hours, six other users reported the same issue. A faint 60 Hz buzz audible with sensitive in-ear monitors (<20Ω impedance, >110 dB sensitivity).

The engineering team scrambled.

"I can reproduce it," Sarah reported. "It's not present on the single-ended output. Only balanced. And only with very sensitive IEMs—over-ear headphones don't show it."

She connected the output to the Audio Precision analyzer. A small spike at 60 Hz—power line frequency. -120 dB below full scale. Inaudible with normal headphones, but with hyper-sensitive IEMs...

"The balanced output stage has a ground loop," she diagnosed. "The negative rails have slightly different potentials. Normally that's fine, but with IEMs, any ground differential becomes audible."

"Can we fix it?"

"In hardware? We'd need to redesign the output stage. In firmware? No."

"What about a software warning?"

"We can detect low-impedance loads and warn users. That's a mitigation, not a fix."

Victoria made the call. "We disclose. Post an acknowledgment, explain the technical cause, and offer single-ended adapters to affected customers."

The forum post went up that evening:

*"We've identified a ground-referenced noise issue affecting balanced output with very low impedance, high-sensitivity IEMs. The root cause is a potential difference in the balanced ground path. We're evaluating hardware solutions for future production runs. In the meantime, affected customers can contact support for a complimentary single-ended adapter cable."*

The response was mixed:

*"Appreciate the transparency. Most products would just deny it."*

*"This is why I wait for v2."*

*"Used my IEMs all week, never noticed it. Guess it depends on your ears."*

One user ran extensive measurements and posted his findings:

*"I measured -118 dB at 60 Hz. For reference, the background noise in my quiet room is around -85 dB. You literally cannot hear this unless you're in an anechoic chamber with the most sensitive IEMs on the market."*

The controversy faded. For most users, it wasn't an issue. For the few affected, adapters solved it. The lesson was learned: test with every possible load type before launch.

---

## Technical Deep Dive: Ground Loops and Audio

*The invisible enemy of clean audio*

### What Is a Ground Loop?

A ground loop occurs when two points that should be at the same potential have a small voltage difference. Current flows through this difference, creating noise.

In audio equipment, ground loops manifest as hum—typically 50 Hz (Europe) or 60 Hz (North America), matching the power line frequency.

### The Balanced Output Problem

Our balanced output has four conductors:
- LEFT+ (positive signal)
- LEFT- (negative signal, inverted)
- RIGHT+ (positive signal)
- RIGHT- (negative signal, inverted)

In theory, LEFT+ and LEFT- are symmetric around ground. The differential receiver rejects any noise common to both conductors.

In practice, our output stage has slightly different ground references:

```
         +15V
          │
    ┌─────┴─────┐
    │  Output   │
    │  Stage L+ │
    └─────┬─────┘
          │ LEFT+
          │
     ─────┼───── Ground A (DAC reference)
          │
    ┌─────┴─────┐
    │  Output   │
    │  Stage L- │
    └─────┬─────┘
          │ LEFT-
          │
         -15V

The negative rail has slightly different filtering than
the positive rail. This creates a small AC voltage between
Ground A and the actual circuit ground—perhaps 10µV at 60Hz.
```

With a 32Ω headphone, 10µV creates 0.3µA of current flow—inaudible.

With a 16Ω IEM, the same 10µV creates 0.6µA—still inaudible.

But with a 10Ω IEM that has 118 dB sensitivity:
```
SPL = Sensitivity + 20×log10(V/√R)
    = 118 + 20×log10(10µV/√10)
    = 118 + 20×log10(3.16µV)
    = 118 + (-110)
    = 8 dB SPL
```

8 dB SPL is near the threshold of hearing in a quiet room. Technically audible. Practically marginal.

### The Fix (For Rev D)

The solution is a properly designed balanced ground:

```
         +15V
          │
    ┌─────┴─────┐
    │  Output   │
    │  Stage L+ │──────┐
    └───────────┘      │
                       │
    ┌───────────┐      │
    │  Output   │      ├───── LEFT (differential)
    │  Stage L- │──────┘
    └─────┬─────┘
          │
    ┌─────┴─────┐
    │  Ground   │
    │  Buffer   │───── GROUND (actively driven to 0V)
    └─────┬─────┘
          │
         -15V

The ground buffer actively drives the ground pin to exactly
the midpoint between the output signals. Any noise on the
rails appears equally on both outputs and cancels.
```

This requires an additional op-amp in the output path—added to the Rev D BOM.

### Why It Wasn't Caught

Our test procedures measured with 32Ω and 300Ω loads—typical headphone impedances. We didn't test with ultra-sensitive IEMs because:

1. IEMs weren't the primary use case
2. The noise was below measurement floor at higher impedances
3. Time pressure pushed exhaustive testing to "later"

"Later" became "after launch." Lesson learned.

---

## End of Month Status

**Budget**: $3.98M of $4.0M spent (99.5%)
**Schedule**: LAUNCH COMPLETE
**Team**: 21 engineers + 3 support staff
**Morale**: Exhausted but triumphant

**Launch Metrics**:
- Pre-orders shipped: 1,247 (100%)
- New orders (launch week): 487
- Total revenue (launch week): $2.5M
- DOA rate: 0.27%
- Customer satisfaction: 87% positive

**Known Issues Post-Launch**:
- Balanced output ground noise with sensitive IEMs (disclosed, mitigated)
- DSD buffer underrun with some apps (firmware fix planned)
- UI aesthetics (refresh planned for 1.1)

---

**END OF PHASE 3: THE LAUNCH**

*Against the odds, they shipped. The product worked. Customers were happy. But launching is just the beginning—the real test is sustaining success.*

---

**[Next: Month 19 - Aftershocks](./19_MONTH_19.md)**
