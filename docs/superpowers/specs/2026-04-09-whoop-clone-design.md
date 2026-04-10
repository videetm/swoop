# SWOOP — Native Swift iOS App Design Spec
**Date:** 2026-04-09  
**Status:** Approved

---

## Overview

A native Swift iOS + watchOS app that reads local Apple Watch health data via HealthKit and presents it through a WHOOP-inspired interface: a daily Recovery Score as the hero metric, backed by Sleep, Strain, and HRV Trends. App name: **SWOOP**.

**Target:** Personal use / sideloaded first. Architecture must support App Store submission as a follow-up with minimal changes.

---

## Features

Four core pillars, all sourced from HealthKit:

| Pillar | Source Data | Output |
|---|---|---|
| **Recovery Score** | HRV (SDNN), resting HR, sleep performance | 0–100 daily readiness score |
| **Sleep Tracking** | HKCategoryTypeIdentifierSleepAnalysis | Sleep score, stages, duration, debt |
| **Strain / Exertion** | HKWorkoutType, heart rate samples | 0–21 cardiovascular load (TRIMP) |
| **HRV Trends** | HKQuantityTypeIdentifierHeartRateVariabilitySDNN | 30-day chart with 7-day baseline band |

---

## Design

- **Aesthetic:** Deep Gradient — dark purple/blue gradient backgrounds (`#1a0533` → `#0d1f4a`), glassy frosted cards, vibrant accent colors (purple `#a78bfa`, blue `#60a5fa`, pink `#f472b6`, green `#34d399`)
- **Typography:** SF Pro (system font), bold numerics, small-caps labels
- **Visual language:** Rings for scores, bar charts for HR zones, line charts for trends

---

## Navigation

**iOS App — 3-tab structure:**

```
Tab 1: Today
  └── RecoveryRingView (home)
        ├── → SleepDetailView
        ├── → StrainDetailView
        ├── → HRVTrendsView
        └── → RecoveryDetailView

Tab 2: History
  └── HistoryView (30-day calendar + sparklines)

Tab 3: Settings
  └── SettingsView (HealthKit permissions, sleep need, birthdate for HR zones, baseline reset)
```

**watchOS App:**
- Complication on watch face showing recovery score
- Glance app showing Recovery · Sleep · Strain · HRV at a glance
- No input on Watch — display only, synced from iPhone via WatchConnectivity

---

## Architecture

### Tech Stack
- **SwiftUI** — iOS 17+, watchOS 10+
- **SwiftData** — local persistence of computed daily scores
- **HealthKit** — source of truth for all raw sensor data; raw data is never duplicated into SwiftData
- **BGTaskScheduler** — `BGAppRefreshTask` scheduled daily after 6am to recompute scores once Watch sync is complete
- **WatchConnectivity** — transfers the latest `DailySnapshot` values from iPhone to Watch after each refresh

### Data Model

```swift
@Model
class DailySnapshot {
    var date: Date           // normalized to midnight
    var recoveryScore: Double  // 0–100
    var sleepScore: Double     // 0–100
    var strainScore: Double    // 0–21
    var hrv: Double            // ms (SDNN, morning measurement)
    var restingHR: Double      // bpm
    var sleepHours: Double     // total sleep time in hours
    var sleepDebt: Double      // rolling 7-day average nightly deficit vs 8hr need
}
```

HealthKit is queried each refresh cycle; only the derived scores are persisted. Raw HRV samples, sleep stages, and heart rate data remain exclusively in HealthKit.

### Score Algorithms

**Recovery Score (0–100)**
```
hrv_component   = clamp((today_hrv / mean(last_7_days_hrv)) * 50, 0, 50)
sleep_component = sleep_score * 0.30
rhr_component   = clamp((1 - (today_rhr - baseline_rhr) / baseline_rhr) * 20, 0, 20)
recovery_score  = hrv_component + sleep_component + rhr_component
```

**Sleep Score (0–100)**
```
efficiency      = time_asleep / time_in_bed
duration_ratio  = clamp(sleep_hours / 8.0, 0, 1)
sleep_score     = (efficiency * 0.6 + duration_ratio * 0.4) * 100
```

**Strain Score (0–21) — TRIMP model**
```
For each heart rate sample in workouts:
  zone_multiplier = { zone1: 1.0, zone2: 2.0, zone3: 3.0, zone4: 4.5, zone5: 6.0 }
  trimp += duration_in_zone_minutes * zone_multiplier
strain_score = clamp(trimp / 300.0 * 21, 0, 21)
```
`max_trimp` is fixed at 300 (≈ 60 minutes at zone 5 intensity), giving a 21-point ceiling for extreme training days. HR zones calculated from age-estimated max HR (220 − age); user provides birthdate in Settings.

**HRV Baseline**
```
baseline = trimmed_mean(last_7_days_hrv, trim: 1)  // drop highest and lowest
```
Trimming prevents single outlier nights (illness, alcohol, travel) from skewing the baseline.

### Service Layer

| Service | Responsibility |
|---|---|
| `HealthKitService` | Request permissions, execute all HK queries, return typed result structs |
| `ScoreEngine` | Pure functions: takes raw HealthKit data, returns computed scores. No I/O. |
| `BackgroundRefreshService` | Schedules and handles `BGAppRefreshTask`, orchestrates HealthKitService → ScoreEngine → SwiftData write |
| `WatchSyncService` | Sends latest `DailySnapshot` to Watch via `WCSession` after each refresh |

### Project Structure

```
Swoop/
├── SwoopApp.swift
├── Features/
│   ├── Home/RecoveryRingView.swift
│   ├── Sleep/SleepDetailView.swift
│   ├── Strain/StrainDetailView.swift
│   ├── HRV/HRVTrendsView.swift
│   ├── Recovery/RecoveryDetailView.swift
│   ├── History/HistoryView.swift
│   └── Settings/SettingsView.swift
├── Models/
│   └── DailySnapshot.swift
├── Services/
│   ├── HealthKitService.swift
│   ├── ScoreEngine.swift
│   ├── BackgroundRefreshService.swift
│   └── WatchSyncService.swift
└── SwoopWatch/
    ├── SwoopWatchApp.swift
    ├── RecoveryGlanceView.swift
    └── ComplicationProvider.swift
```

---

## HealthKit Permissions Required

```
Read:
  HKQuantityTypeIdentifierHeartRateVariabilitySDNN
  HKQuantityTypeIdentifierRestingHeartRate
  HKQuantityTypeIdentifierHeartRate
  HKCategoryTypeIdentifierSleepAnalysis
  HKWorkoutTypeIdentifier
  HKQuantityTypeIdentifierActiveEnergyBurned
```

---

## Background Refresh

- Register `com.swoop.refresh` as a `BGAppRefreshTaskRequest`
- Schedule for ~6am daily (after Watch overnight sync typically completes)
- Task: query last 24h HealthKit → compute scores → write `DailySnapshot` → sync to Watch
- Reschedule itself at end of each execution

---

## Error Handling

- HealthKit permission denied: show onboarding screen explaining why each permission is needed, deep-link to Settings
- No data available (e.g., Watch not worn last night): show placeholder state with explanation, not an error
- Background task killed by OS: app refreshes on next foreground launch as fallback

---

## App Store Path (future)

The following additions are needed when ready for App Store — no architectural changes required:
1. Privacy policy URL in App Store Connect
2. HealthKit usage description strings already in Info.plist (needed for sideloading too)
3. App Store review notes explaining HealthKit usage
4. Age-gating if required by Apple review

---

## Out of Scope

- Social features / sharing scores
- Coach or AI recommendations
- Manual journal entries
- Nutrition tracking
- Subscription / paywall
