# SWOOP

A native Swift iOS + watchOS app that reads Apple Watch health data via HealthKit and displays your daily **Readiness Score**, **Sleep**, **Load**, and **HRV Trends** — all computed on-device with no backend.

---

## Screenshots

_Add screenshots here after first run_

---

## Features

- **Readiness Ring** — animated circular score (0–100) driven by HRV, sleep quality, and resting heart rate
- **Sleep Detail** — sleep score, hours slept vs. need, sleep debt, 14-day bar chart
- **Load Detail** — daily training load via TRIMP (Training Impulse) with HR zone reference
- **HRV Trends** — 30-day line chart with 7-day rolling baseline band
- **Readiness Breakdown** — shows HRV component, sleep component, and RHR component scores
- **History** — scrollable list of past days with sparklines
- **Settings** — birth year (for max HR estimation), sleep need, data reset
- **watchOS Glance** — readiness ring + sleep/load/HRV stats synced via WatchConnectivity
- **Background Refresh** — daily score update at ~6am via BGTaskScheduler

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9+ |
| UI | SwiftUI (iOS 18+, watchOS 11+) |
| Data | SwiftData |
| Health data | HealthKit |
| Background | BGTaskScheduler |
| Watch sync | WatchConnectivity |
| Charts | Swift Charts |
| Tests | XCTest |

---

## Requirements

- Xcode 16+ (project created with Xcode 26)
- iOS 18+ deployment target
- watchOS 11+ deployment target
- Apple Developer account (required for HealthKit entitlement)
- Physical iPhone + Apple Watch (HealthKit does not run in Simulator)

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/videetm/swoop.git
cd swoop
open Swoop.xcodeproj
```

### 2. Set your Team

In Xcode, select the **Swoop** target → **Signing & Capabilities** → set your **Team** to your Apple Developer account. Repeat for **SwoopWatch Watch App**.

### 3. Update Bundle Identifiers (if needed)

The default bundle IDs are `com.swoop.app.Swoop` and `com.swoop.app.Swoop.watchkitapp`. Change them if they conflict with an existing app on your account.

### 4. Add Capabilities (already configured — verify these exist)

| Target | Capability |
|---|---|
| Swoop | HealthKit |
| Swoop | Background Modes → Background fetch + Background processing |
| SwoopWatch Watch App | HealthKit |

These should already be present in the entitlements files. If Xcode shows signing errors, re-add them via **+ Capability**.

### 5. Build & Run

Select your **iPhone** as the destination and run the **Swoop** scheme. On first launch:

1. Onboarding screen appears
2. Tap **Connect Health Data** → grant all requested permissions
3. App loads the Today tab and fetches your scores

To also run the Watch app, pair your Apple Watch and run the **SwoopWatch Watch App** scheme, or let Xcode install it automatically when running the iOS scheme.

---

## Project Structure

```
Swoop.xcodeproj/         Xcode project
Swoop/                   iOS app source
├── SwoopApp.swift        App entry — SwiftData container, BG task registration
├── DesignSystem.swift    Color tokens, gradients, GlassCard modifier
├── Models/
│   ├── DailySnapshot.swift   SwiftData model (one row per day)
│   └── UserSettings.swift    UserDefaults-backed settings singleton
├── Services/
│   ├── ScoreEngine.swift             Pure score computation (no I/O)
│   ├── HealthKitService.swift        HealthKit queries
│   ├── BackgroundRefreshService.swift BGTaskScheduler orchestration
│   └── WatchSyncService.swift        WatchConnectivity send/receive
└── Features/
    ├── ContentView.swift         Tab container + onboarding gate
    ├── Onboarding/               HealthKit permission screen
    ├── Home/                     Readiness ring + metric chips
    ├── Sleep/                    Sleep score + 14-day chart
    ├── Load/                     TRIMP score + HR zone key
    ├── HRV/                      30-day HRV chart + baseline band
    ├── Readiness/                Score breakdown + 7-day history
    ├── History/                  Daily list with sparklines
    └── Settings/                 Birth year, sleep need, data reset
SwoopTests/              Unit tests (ScoreEngine + DailySnapshot)
SwoopWatch Watch App/    watchOS app
├── SwoopWatchApp.swift
├── ReadinessGlanceView.swift
├── WatchSessionManager.swift
└── ComplicationProvider.swift
```

---

## Score Algorithms

All computation lives in `ScoreEngine.swift` and is fully unit-tested.

### Sleep Score (0–100)
```
sleep_score = (efficiency × 0.6 + duration_ratio × 0.4) × 100
efficiency  = hours_asleep / hours_in_bed
duration    = min(hours_asleep / 8.0, 1.0)
```

### Load Score (0–100) via TRIMP
```
trimp       = Σ (duration_min × zone_multiplier)
zone_multipliers: Z1=1.0  Z2=2.0  Z3=3.0  Z4=4.5  Z5=6.0
load_score  = min(trimp / 300 × 100, 100)
```

### Readiness Score (0–100)
```
hrv_component   = min((today_hrv / 7day_baseline) × 50, 50)
sleep_component = sleep_score × 0.30
rhr_component   = min(max((1 − (today_rhr − baseline_rhr) / baseline_rhr) × 20, 0), 20)
readiness       = hrv_component + sleep_component + rhr_component
```

### Sleep Debt
```
debt = mean(max(8.0 − night_hours, 0) for each of last 7 nights)
```

---

## Running Tests

```bash
xcodebuild test \
  -project Swoop.xcodeproj \
  -scheme Swoop \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  | grep -E "(Test Suite|passed|failed)"
```

All `ScoreEngineTests` and `DailySnapshotTests` run without a device (no HealthKit dependency).

---

## Background Refresh

The app schedules a `BGAppRefreshTask` (identifier `com.swoop.refresh`) to run at approximately 6am daily. To manually trigger it during development:

In Xcode with the app paused at a breakpoint, run:
```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.swoop.refresh"]
```

---

## License

MIT
