# SWOOP

A native Swift iOS + watchOS fitness app that reads Apple Watch health data via HealthKit and surfaces a daily **Readiness Score**, **Sleep**, **Load**, **HRV Trends**, and actionable insights — all computed on-device with no backend or subscription.

---

## Screenshots

_Add screenshots here after first run_

---

## Features

### Today Tab
- **Readiness Ring** — animated circular score (0–100) driven by HRV, sleep quality, and resting heart rate
- **AI-style Insight Strip** — rule-based insight engine surfaces the most relevant observation about today's data (HRV spike, sleep debt, high load warning, etc.)
- **4-Metric Chips** — Sleep / Load / HRV / RHR at a glance, each tappable to drill in
- **7-Day Sparkline** — colour-coded readiness bars for the past week

### Trends Tab (D / W / M / Y)
- **Period Selector** — toggle between Day, Week, Month, Year
- **Metric Overview Cards** — mini sparkline + delta badge (vs. previous period) for every tracked metric
- **Metric Deep-Dive** — tap any metric to open a full detail view with:
  - Area + line chart (Swift Charts) with baseline band and avg rule
  - AVG / PEAK / LOW / TREND stat row
  - Insight card tuned to that metric

### Detail Views
- **Sleep Detail** — sleep score hero, hours vs. need gauge, 14-day bar chart, sleep debt
- **Load Detail** — daily TRIMP load score, HR zone key (Z1–Z5), 14-day load history chart
- **HRV Trends** — 30-day area chart with 7-day rolling baseline band and colour-coded data points
- **Readiness Breakdown** — HRV component / Sleep component / RHR component scores, 7-day history bars

### Settings Tab
- **Appearance** — System / Light / Dark mode toggle (applied app-wide instantly)
- **Health Profile** — birth year (for max HR), sleep need (hours), max HR override
- **Notifications** — enable daily reminders with custom time picker
- **Import Full History** — one-tap 90-day HealthKit backfill
- **Data Reset** — wipe all stored snapshots

### Data & Background
- **90-day Backfill** — auto-runs on first launch to populate full history from HealthKit
- **Background Refresh** — daily score update at ~6am via BGTaskScheduler
- **watchOS Glance** — readiness ring + sleep/load/HRV stats synced via WatchConnectivity

---

## Design System

| Token | Value |
|---|---|
| Primary accent | `#a78bfa` (swoopPurple) |
| Blue accent | `#60a5fa` (swoopBlue) |
| Pink accent | `#f472b6` (swoopPink) |
| Green accent | `#34d399` (swoopGreen) |
| Dark background | `#1a0533` → `#0d1f4a` gradient |
| Light background | `#ffffff` → `#f8f8f8` gradient |

**LiquidGlass** — adaptive glass card modifier: semi-transparent fill + top-lit stroke border, automatically adjusts opacity for light and dark modes.

**AmbientGlow** — per-screen blurred radial gradient blobs that add depth without affecting readability.

**AppearanceMode** — `@AppStorage`-backed preference applied at `WindowGroup` root so it propagates reliably through all `TabView` and `NavigationStack` layers.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 6 |
| UI | SwiftUI (iOS 26+, watchOS 11+) |
| Data | SwiftData |
| Health data | HealthKit |
| Charts | Swift Charts |
| Background | BGTaskScheduler |
| Watch sync | WatchConnectivity |
| Tests | XCTest |

---

## Score Algorithms

All computation lives in `ScoreEngine.swift` and is fully unit-tested.

### Sleep Score (0–100)
```
sleep_score = (efficiency × 0.6 + duration_ratio × 0.4) × 100
efficiency  = hours_asleep / hours_in_bed
duration    = min(hours_asleep / sleep_need, 1.0)
```

### Load Score (0–100) via TRIMP
```
trimp              = Σ (duration_min × zone_multiplier)
zone_multipliers:    Z1=1.0  Z2=2.0  Z3=3.0  Z4=4.5  Z5=6.0
HR zones (% of max): Z1 <60%  Z2 60–70%  Z3 70–80%  Z4 80–90%  Z5 >90%
load_score         = min(trimp / 300 × 100, 100)
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
debt = mean(max(sleep_need − night_hours, 0) for each of last 7 nights)
```

### Insight Engine
A priority-ordered rule engine (`InsightEngine.swift`) evaluates today's snapshot against 7-day baselines and returns the single most relevant insight. Rules (in priority order):
1. Critical recovery needed (readiness < 34)
2. HRV spike above baseline
3. HRV drop below baseline
4. Sleep debt accumulation
5. High load warning
6. Low load / consecutive rest days
7. High resting HR
8. Strong readiness streak
9. Consistent sleep

---

## Project Structure

```
Swoop.xcodeproj/              Xcode project (Xcode 16, PBX auto-sync)
Swoop/                        iOS app source
├── SwoopApp.swift             App entry — SwiftData container, BG task reg,
│                              appearance mode applied at WindowGroup root
├── DesignSystem.swift         Color tokens, LiquidGlass, AmbientGlow,
│                              AppBackground, AppearanceMode, score colors
├── Models/
│   ├── DailySnapshot.swift    SwiftData model (one row per calendar day)
│   └── UserSettings.swift     UserDefaults-backed settings (birth year,
│                              sleep need, appearance, notifications)
├── Services/
│   ├── ScoreEngine.swift              Pure score computation (no I/O)
│   ├── InsightEngine.swift            Rule-based insight generation
│   ├── HealthKitService.swift         HealthKit queries
│   ├── BackgroundRefreshService.swift BGTaskScheduler + 90-day backfill
│   └── WatchSyncService.swift         WatchConnectivity send/receive
└── Features/
    ├── ContentView.swift          Tab container + onboarding gate + backfill trigger
    ├── Onboarding/                HealthKit permission screen
    ├── Home/                      Readiness ring, insight strip, metric chips, sparkline
    ├── Sleep/                     Sleep detail + 14-day chart
    ├── Load/                      TRIMP load + HR zone key + 14-day chart
    ├── HRV/                       30-day HRV chart + baseline band
    ├── Readiness/                 Score breakdown + 7-day bar history
    ├── History/                   Trends overview (period selector + metric cards)
    ├── Trends/                    TrendTypes enums + MetricDetailView (area chart)
    └── Settings/                  Appearance, health profile, notifications, data
SwoopTests/                   Unit tests — ScoreEngine + InsightEngine
SwoopWatch Watch App/         watchOS app
├── SwoopWatchApp.swift
├── ReadinessGlanceView.swift
├── WatchSessionManager.swift
└── ComplicationProvider.swift
docs/superpowers/
├── specs/                     Design specs
└── plans/                     Implementation plans
```

---

## Requirements

- Xcode 16+
- iOS 26+ deployment target (uses liquid glass APIs)
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

### 5. Build & Run

Select your **iPhone** as the destination and run the **Swoop** scheme. On first launch:

1. Onboarding screen appears — tap **Connect Health Data** and grant all permissions
2. App automatically backfills up to 90 days of HealthKit history in the background
3. Today tab loads with your current scores

---

## Running Tests

```bash
xcodebuild test \
  -project Swoop.xcodeproj \
  -scheme Swoop \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  | grep -E "(Test Suite|passed|failed)"
```

Tests cover `ScoreEngine` (sleep, TRIMP, readiness, sleep debt) and `InsightEngine` (all 9 rules). No device or HealthKit access required.

---

## Background Refresh

The app schedules a `BGAppRefreshTask` (identifier `com.swoop.refresh`) to run at approximately 6am daily. To manually trigger during development:

In Xcode with the app paused, run in the debug console:
```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.swoop.refresh"]
```

---

## License

MIT
