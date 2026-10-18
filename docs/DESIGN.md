# Pala — Responsive Flutter UI/UX & Architecture Specification (`DESIGN.md`)

## 1. Project Overview & Architectural Vision
- **App Name**: Pala (Open-Source Kréta e-Napló Client)
- **Framework**: Flutter (Dart) — Single codebase targeting Android, iOS, Windows, macOS, and Linux.
- **Core Principle**: **One Codebase, Adaptive Layouts**. Mobile portrait and desktop landscape views run off the exact same business logic and state management layer, dynamically adapting based on screen constraints.
- **Privacy & Security Guarantee**: All Kréta API credentials, tokens, grades, and personal student data remain strictly localized on device storage. Zero external telemetry or third-party tracking.

---

## 2. Responsive Breakpoints & Adaptive Layout Rules

### **Breakpoint Threshold**: `600dp` screen width

### **A. Mobile View (`< 600dp` — Portrait / Mobile)**
* **Navigation Pattern**: Bottom `NavigationBar` featuring 3–5 core destinations (Dashboard, Grades, Absence, Settings) within natural thumb reach.
* **Layout Structure**: Single-column vertical layout (`ListView` / `CustomScrollView`).
* **Interaction**: Swipe gestures for tab switches, bottom sheets for filters and quick actions.

### **B. Desktop / Wide View (`≥ 600dp` — Landscape / Resizable Windows)**
* **Navigation Pattern**: Left-side `NavigationRail` or collapsible side navigation drawer to utilize horizontal screen real estate effectively.
* **Layout Structure**: Master-Detail Split Panels (`Row` containing `Expanded` flex panels):
  * **Left Panel (Master)**: Subject list, recent activity feed, or date selector.
  * **Right Panel (Detail)**: Selected subject grade history, trend charts, Szellem Jegy (ghost grade) calculator, or absence breakdown.
* **Window Resizing**: Must handle live window resizing without state reset or visual clipping.

---

## 3. Screen Specifications & Feature Hierarchy

### **1. Live Dashboard**
* **Primary Focus**: Immediate actionable student context upon app open.
* **Hero Section**: Next class card with countdown, classroom number, and teacher substitution/cancellation badges.
* **Secondary Cards**: Recent grades list, unread teacher messages, and overall grade point average (GPA).

### **2. Grades & Trend Analysis**
* **Subject Averages**: Color-coded subject lists with grade trends (improving vs declining).
* **Szellem Jegy (Ghost Grade) Calculator**: Interactive tool allowing students to simulate hypothetical future grades to calculate required scores for target term averages.
* **Visualizations**: Interactive line charts showing grade progression over the school semester.

### **3. Attendance & Absences**
* **Overview**: Clear metric cards displaying total absence hours, unexcused vs excused status.
* **Alert Thresholds**: Proactive warning banners when total missing hours approach critical thresholds (e.g., 250-hour limit).

---

## 4. UI/UX Design Standards & Micro-interactions

* **Color Psychology & Functional Palette**:
  * **Success / High Grade (5)**: Functional Green (`#2E7D32`)
  * **Caution / Low Grade (2-3)**: Functional Orange (`#ED6C02`)
  * **Critical / Failing (1) / Unexcused Absence**: Functional Red (`#D32F2F`)
  * **Neutral Backgrounds**: Clean light/dark adaptive theme surfaces.
* **Feedback Mechanics**:
  * **Non-Blocking Loading**: Use skeleton shimmer loaders instead of full-screen spinners during Kréta API synchronization.
  * **Status Updates**: Floating toast notifications (`SnackBar`) for background sync completions or offline mode alerts.
  * **Touch Target Size**: Minimum `48x48dp` clickable targets on mobile portrait mode.

---

## 5. Development Guidelines for AI Agents (Antigravity & Claude Code)

1. **State Isolation**: Separate UI widgets from business logic (`Bloc` / `Provider` / `Riverpod`).
2. **Adaptive Widgets**: Use `LayoutBuilder` or `MediaQuery.sizeOf(context).width` to swap UI branches cleanly.
3. **Overflow Prevention**: Wrap list content in `SingleChildScrollView` or `Flexible`/`Expanded` widgets to avoid `RenderFlex` yellow-and-black stripes on edge-case window dimensions.
4. **Dart Strict Null Safety**: Ensure all Kréta JSON parser models handle missing or null fields gracefully with default fallback values.
