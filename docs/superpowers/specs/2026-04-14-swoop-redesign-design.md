# Swoop Redesign — Design Spec
**Date:** 2026-04-14  
**Status:** Approved

---

## Overview

Full visual and feature redesign of the Swoop iOS app. The existing app is functional but sparse — no historical graphs, no insights, no settings depth. This spec covers:

1. Liquid glass design system upgrade
2. Today tab redesign
3. Trends tab (replaces History) with D/W/M/Y period navigation and metric deep-dives
4. Enriched detail views (Sleep, Load, HRV, Readiness)
5. Rule-based InsightEngine
6. Settings tab redesign with appearance + user configuration

---

## 1. Design System

### Liquid Glass Treatment
Replace the existing `GlassCard` modifier with a richer `LiquidGlass` modifier:
- Background: `rgba(255,255,255,0.06)` (dark) / `rgba(0,0,0,0.05)` (light)
- Border: `rgba(255,255,255,0.14)` with specular highlight: `inset 0 1px 0 rgba(255,255,255,0.15)`
- Corner radius: 20px for hero cards, 14px for chips/rows
- Backdrop blur: 20pt via `.ultraThinMaterial` + custom overlay

### Ambient Glow
New `AmbientGlow` view modifier: places radial gradient blobs behind sections using Swoop palette colours (purple top-right, blue bottom-left). Applied to ZStack backgrounds on each screen.

### Appearance Modes
`UserSettings` gets an `appearanceMode: AppearanceMode` field (`system` / `light` / `dark`). Applied via `.preferredColorScheme` on the root `WindowGroup`. All glass treatments adapt — dark uses white-tinted glass, light uses black-tinted glass with reduced opacity.

### Tab Bar
Tab bar gets `.ultraThinMaterial` background + subtle top border. "History" tab renamed to "Trends" with `chart.line.uptrend.xyaxis` icon.

### Color additions
No new colours. Existing palette (`swoopPurple`, `swoopBlue`, `swoopPink`, `swoopGreen`) is sufficient.

---

## 2. Today Tab

**File:** `Swoop/Features/Home/ReadinessRingView.swift` — full rebuild.

### Layout (top to bottom)
1. **Date header** — uppercase date string, unchanged
2. **Hero glass card** — liquid glass card containing:
   - Readiness ring (existing ring drawing code, kept)
   - Score + status label ("Ready to train" / "Moderate" / "Recovery needed")
3. **Insight strip** — gradient glass card with rule-based insight text (from `InsightEngine`)
4. **4-metric row** — Sleep · Load · HRV · RHR chips, each tappable to their detail view
5. **7-day sparkline card** — mini bar chart of the last 7 readiness scores, liquid glass

### Insight strip
- Shows one insight string from `InsightEngine.todayInsight(snapshot:history:)`
- Prefixed with a coloured dot matching the dominant metric
- Empty state: hidden if no snapshot exists

---

## 3. Trends Tab

**File:** `Swoop/Features/History/HistoryView.swift` — full rebuild.

### Overview screen
- **Title:** "Trends"
- **Period selector:** D / W / M / Y segmented control (pill style, stored in `@State var period: TrendPeriod`)
- **Metric cards** (4 total: Readiness, HRV, Sleep, Load): each card shows:
  - Metric name + current/latest value
  - 7-bar mini sparkline (last 7 data points for the selected period granularity)
  - Delta badge: % or absolute change vs previous period
  - Chevron indicating tappability
- Cards are `NavigationLink`s leading to the metric deep-dive

### `TrendPeriod` enum
```swift
enum TrendPeriod: String, CaseIterable {
    case day = "D", week = "W", month = "M", year = "Y"
    var days: Int { switch self { case .day: 1; case .week: 7; case .month: 30; case .year: 365 } }
    var label: String { ... } // "Today", "This Week", "This Month", "This Year"
}
```

### Metric deep-dive screen
**File:** `Swoop/Features/Trends/MetricDetailView.swift` (new file)

Parameters: `metric: TrendMetric`, `period: TrendPeriod`

Layout:
1. **Hero glass card** — current value, period label, vs-previous delta badge, avg/peak/low in subtitle
2. **Period selector** — same pill control, updates chart on change
3. **Area chart** (Swift Charts `AreaMark` + `LineMark`) — gradient fill, baseline `RuleMark`, colored dots at peak/low
4. **Stat row** — 4 glass chips: Avg · Peak · Low · Trend (↑/↓/→)
5. **Insight card** — rule-based insight for this metric + period from `InsightEngine`

**`TrendMetric` enum:**
```swift
enum TrendMetric: String, CaseIterable {
    case readiness, hrv, sleep, load
    var label: String { ... }
    var color: Color { ... }
    var unit: String { ... } // "", "ms", "h", ""
    func values(from snapshots: [DailySnapshot]) -> [Double] { ... }
}
```

---

## 4. Detail Views

Existing `ReadinessDetailView`, `SleepDetailView`, `LoadDetailView`, `HRVTrendsView` each get:
- Background upgraded to `AmbientGlow` + gradient
- `GlassCard` → `LiquidGlass` treatment on all cards
- Insight card added at the bottom (from `InsightEngine`)
- No structural changes to chart logic — charts are already correct

---

## 5. InsightEngine

**File:** `Swoop/Services/InsightEngine.swift` (new file)

Pure functions, no external dependencies. Returns `Insight` structs.

```swift
struct Insight {
    let text: String
    let color: Color   // dot accent color
    let metric: TrendMetric
}
```

### Rules (~10 total)

| Rule | Condition | Text |
|------|-----------|------|
| HRV above baseline | today HRV > 7-day baseline × 1.07 | "HRV {X}% above baseline — prime window for high intensity." |
| HRV below baseline | today HRV < 7-day baseline × 0.93 | "HRV below baseline — favour easy effort today." |
| Sleep debt high | sleepDebt > 1.5h | "Carrying {X}h sleep debt — prioritise 8h+ tonight." |
| Sleep debt clear | sleepDebt < 0.25h | "Sleep debt cleared — recovery is on track." |
| Load spike | today loadScore > 7-day avg load × 1.4 | "High load day — schedule easy effort tomorrow." |
| Load low streak | last 3 days loadScore < 30 | "3 low-load days — body is well rested, ready to build." |
| RHR elevated | today RHR > 7-day baseline RHR + 4 | "Resting HR elevated by {X} bpm — signs of accumulated fatigue." |
| RHR normal | today RHR ≤ 7-day baseline RHR + 1 | "Resting HR normal — cardiovascular recovery looks good." |
| Readiness trending up | last 3 readiness scores all increasing | "Readiness trending up 3 days straight — momentum is building." |
| Recovery needed | readinessScore < 34 | "Body signalling full recovery — avoid intensity today." |

`InsightEngine.todayInsight(snapshot:history:) -> Insight?` evaluates rules in priority order and returns the most relevant one. `InsightEngine.metricInsight(metric:snapshots:period:) -> Insight?` evaluates metric-specific rules for the deep-dive view.

---

## 6. Settings Tab

**File:** `Swoop/Features/Settings/SettingsView.swift` — full rebuild.

### Sections

**Appearance**
- Appearance mode: System / Light / Dark (segmented picker)

**Health Profile**
- Sleep need: stepper 6h–10h in 0.5h increments (default 8h)
- Max heart rate: stepper 160–210 bpm (default 190, used for load zone calc)
- Age: optional number field (future: used for max HR formula)

**Notifications** *(UI only in this pass — no UNUserNotificationCenter wiring)*
- Daily readiness reminder: toggle
- Reminder time: time picker (shown when toggle is on)

**Data**
- Refresh now: button → calls `BackgroundRefreshService.refresh`
- Clear all data: destructive button with confirmation alert

**About**
- App version string

### Persistence
`UserSettings` already uses `UserDefaults` via `@AppStorage`. Add:
- `appearanceMode: AppearanceMode` (raw `String`, default `"system"`)
- `maxHR: Int` (default 190)
- `notificationsEnabled: Bool` (default false)
- `notificationHour: Int`, `notificationMinute: Int` (default 8:00)

---

## 7. Data Flow

No changes to `DailySnapshot` model, `HealthKitService`, `BackgroundRefreshService`, or `ScoreEngine`. All new features are pure view + logic layer on top of existing data.

`InsightEngine` reads `[DailySnapshot]` via `@Query` at the call site and is passed values — it has no SwiftData dependency itself.

---

## 8. Files Changed / Created

| File | Action |
|------|--------|
| `Swoop/DesignSystem.swift` | Update `GlassCard` → `LiquidGlass`, add `AmbientGlow`, add `AppearanceMode` |
| `Swoop/Features/Home/ReadinessRingView.swift` | Rebuild |
| `Swoop/Features/History/HistoryView.swift` | Rebuild as Trends overview |
| `Swoop/Features/Trends/MetricDetailView.swift` | **New** |
| `Swoop/Features/Readiness/ReadinessDetailView.swift` | Polish pass |
| `Swoop/Features/Sleep/SleepDetailView.swift` | Polish pass |
| `Swoop/Features/Load/LoadDetailView.swift` | Polish pass |
| `Swoop/Features/HRV/HRVTrendsView.swift` | Polish pass |
| `Swoop/Features/Settings/SettingsView.swift` | Rebuild |
| `Swoop/Services/InsightEngine.swift` | **New** |
| `Swoop/Models/UserSettings.swift` | Add new settings fields |
| `Swoop/Features/ContentView.swift` | Apply `appearanceMode` to root |

---

## 9. Out of Scope

- Push notifications wiring (UNUserNotificationCenter)
- Claude API / LLM insights
- watchOS companion redesign
- HealthKit permission re-prompting
- Onboarding redesign
