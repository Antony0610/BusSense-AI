# BusSense AI — UI/UX Design System & Rulebook

This document serves as the permanent design system specification for BusSense AI, derived directly from Google Stitch Project `14259704318600090723`.

---

## 1. Design Ethos & Core Philosophy

- **Minimalist Mobility Architecture:** Clean, calm, high-legibility interfaces inspired by world-class transit systems (Apple Maps Transit, Swiss Rail SBB, Tokyo Metro).
- **Less UI, More Design:** Eliminate visual friction. Avoid clutter, decorative cyberpunk lines, fake pulsing halos, and generic SaaS card overload.
- **Role-Specific Ergonomics:**
  - **Passenger:** Calm, glanceable, reassuring, high-contrast countdown timers.
  - **Driver & Conductor:** Ultra-high contrast, one-handed touch targets (minimum 48px), night-vision friendly, safety-first.
  - **Transport Authority:** Map-first, high information density, dual-pane GIS layout with tabular precision.

---

## 2. Color Palette & Semantic Tokens

| Semantic Token | Hex Code | Purpose & Usage |
|---|---|---|
| `primary` | `#002620` | Deepest Kerala Evergreen. Primary typography, dark buttons, brand headers. |
| `primary-container` | `#123c35` | Rich Forest Slate. Hero celebration banners, active drawer headers. |
| `secondary` | `#006c49` | Vibrant Emerald. On-time indicators, LOW crowd badges, confirmed states. |
| `secondary-container`| `#6cf8bb` | Mint Highlight. Active indicator badges, high-contrast icon backgrounds. |
| `background` / `surface` | `#f3fbf7` | Warm Ivory Mist. Main page canvas, zero harsh pure-white eye strain. |
| `surface-container` | `#e8f0ec` | Soft Sage Grey. Metric pill containers, inactive tab backgrounds. |
| `surface-container-low`| `#eef5f1` | Neutral Card Substrate. Grouped telemetry boxes, checklist items. |
| `surface-container-lowest`| `#ffffff` | Elevated Cards. Main content containers, QR boarding pass substrate. |
| `on-surface` | `#161d1b` | Charcoal Slate. Primary body copy, table figures. |
| `on-surface-variant`| `#414846` | Muted Mineral Slate. Labels, secondary timestamps, sub-headers. |
| `outline` | `#717976` | Hairline dividers, subtle borders (`#c0c8c5/30`). |
| `amber-500` / `warn` | `#d97706` | MODERATE crowd level (50–80%), schedule delay warnings. |
| `error` | `#ba1a1a` | CROWDED crowd level (>80%), incident hazard badges, rejected passes. |

---

## 3. Typography System

- **Primary Typeface:** `Plus Jakarta Sans`, sans-serif (Google Fonts).
- **Tabular Figures:** Always apply `tnum` (`font-variant-numeric: tabular-nums`) to all countdown timers, speeds, occupancy percentages, and fares to prevent jitter during live updates.

| Style Name | Font Size | Line Height | Weight | Letter Spacing |
|---|---|---|---|---|
| `display-hero` | `44px` | `52px` | 700 (Bold) | `-0.03em` |
| `headline-lg` | `32px` | `40px` | 700 (Bold) | `-0.025em` |
| `headline-md` | `22px` | `28px` | 600 (SemiBold) | `-0.015em` |
| `headline-sm` | `18px` | `24px` | 600 (SemiBold) | `-0.01em` |
| `eta-display` | `28px` | `32px` | 800 (ExtraBold) | `-0.03em` |
| `title-card` | `16px` | `22px` | 600 (SemiBold) | `-0.005em` |
| `body-lg` | `16px` | `24px` | 400 (Regular) | `0em` |
| `body-md` | `14px` | `20px` | 400 (Regular) | `0em` |
| `body-sm` | `13px` | `18px` | 400 (Regular) | `+0.005em` |
| `caption` | `12px` | `16px` | 500 (Medium) | `+0.01em` |
| `label-caps` | `11px` | `14px` | 700 (Bold) | `+0.06em` (Uppercase) |

---

## 4. Spacing & Border Radius

- **Corner Radii:**
  - Standard cards & containers: `rounded-2xl` (`16px`)
  - Inner metric pills & buttons: `rounded-xl` (`12px`)
  - Tags, badges & avatars: `rounded-full` (`9999px`)
- **Spacing Grid:**
  - Base margin: `16px` (`p-4`)
  - Section gaps: `12px` (`gap-3`) or `16px` (`gap-4`)
  - Container padding: Mobile shell capped at `max-w-xl mx-auto`.

---

## 5. Component Guidelines

### Buttons:
- Primary Actions: Background `#002620` or `#123c35`, text `#ffffff`, height 56px (`h-14`), active scale `active:scale-[0.985]`.
- Secondary Actions: White background with subtle `#c0c8c5/30` border, text `#161d1b`, height 48px (`h-12`).

### Truth Badges:
Every card displaying calculated data must include a micro badge:
```tsx
<span className="text-[10px] font-bold text-[#006c49] tracking-wider uppercase">
  PREDICTION • 60-MIN HORIZON
</span>
```

### Iconography:
- **Font:** Google Material Symbols Outlined (`material-symbols-outlined`).
- Standard sizes: `16px`, `20px`, `24px`, `28px`.
- Optical sizing enabled; filled glyphs reserved for active state confirmation.
