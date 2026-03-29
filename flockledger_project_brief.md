# FlockLedger — Full Project Context

> Feed this file to Claude.ai to continue work on the app with full context.
> Current date captured: 2026-03-29 | Current version: **1.8.1+24**
> GitHub: https://github.com/anwar1808/flock-ledger

---

## What this app is

**FlockLedger** is a personal Android app (Flutter) for tracking a backyard chicken flock. It records:
- General / flock / chick journal entries
- Egg records (weight, colour, hen, photo) — weights read automatically from scale photos via Claude Vision AI
- Flock management (individual birds, groups, status tracking, purpose: layer/meat/dual)
- Chick batches (incubation tracking with breed-aware progress bar and hatch window)
- AI-powered chick sexing assessments via Claude Vision
- Export to Excel

All data is local (SQLite on-device). Only compressed photos are ever sent externally (to Anthropic API for AI analysis).

---

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart), targets Android |
| State management | `provider` ^6.1.2 — `ChangeNotifier` pattern |
| Local DB | `sqflite` ^2.3.3, schema version **7** |
| AI | Anthropic Claude API (`claude-opus-4-6`) via `http` ^1.2.0 |
| Charts | `fl_chart` ^0.68.0 |
| Export | `excel` ^4.0.3 + `share_plus` ^9.0.0 |
| Image | `image_picker` ^1.0.7, `flutter_image_compress` ^2.3.0 |
| EXIF | `exif` ^3.3.0 (date extraction from photo filenames) |
| Secure storage | `flutter_secure_storage` ^9.0.0 (API key + settings) |
| IDs | `uuid` ^4.3.3 |
| Localisation | `intl` ^0.19.0 |

**pubspec version:** `1.8.1+24`

---

## Project structure

```
lib/
├── main.dart                    # Entry point; initialises DB, sets up providers
├── app.dart                     # MaterialApp, theme (earthy green #5D8A3C + amber #D4A017)
├── database/
│   └── database_helper.dart     # Singleton DB; all CRUD; schema v7
├── models/
│   ├── chicken.dart             # Chicken model (inc. purpose, liveWeightGrams, dressedWeightGrams)
│   ├── egg_record.dart          # EggRecord model; sizeGrade uses active grading standard
│   ├── journal_entry.dart       # JournalEntry model + track/stage constants
│   ├── chick_batch.dart         # ChickBatch model + incubation maths + lockdown fields
│   ├── flock_group.dart         # FlockGroup model + colour presets
│   ├── loss_event.dart          # LossEvent model; kLossStatuses order: slaughtered → deceased → missing
│   └── sexing_assessment.dart   # SexingAssessment model (AI chick sexing)
├── providers/
│   ├── chicken_provider.dart    # Chickens, flock groups, loss events
│   ├── egg_provider.dart        # Egg records + stats
│   ├── journal_provider.dart    # Journal entries + chick batches
│   ├── settings_provider.dart   # EggGradeStandard + WeightUnit; persisted in secure storage
│   └── sexing_provider.dart     # Sexing assessments (lazy-loaded per bird)
├── services/
│   └── claude_service.dart      # Anthropic API calls (egg analysis + sexing)
├── screens/
│   ├── main_screen.dart         # Bottom nav: Home / Eggs / Flock / Insights
│   ├── home/
│   │   └── home_screen.dart     # Dashboard; dynamic greeting + lockdown prompt + incubation cards
│   ├── eggs/
│   │   ├── egg_tracker_screen.dart   # Egg list; colour dot + size grade on same line
│   │   ├── egg_capture_screen.dart   # Photo → Claude → review/edit → save
│   │   └── egg_stats_screen.dart     # Charts (weekly/monthly production, weight trends)
│   ├── flock/
│   │   ├── flock_screen.dart         # Bird list with drag-and-drop between groups
│   │   ├── chicken_detail_screen.dart # Per-bird stats, photo lightbox, slaughter weights
│   │   ├── chicken_edit_screen.dart   # Add/edit a bird; purpose, slaughter weights, camera overlay
│   │   ├── flock_group_edit_screen.dart
│   │   ├── batch_hatch_screen.dart    # Add multiple birds from a hatch
│   │   └── loss_event_screen.dart     # Log loss; default Slaughtered; order S→D→M
│   ├── journal/
│   │   ├── journal_screen.dart        # Tab bar: General / Flock / Chick
│   │   ├── entry_list_screen.dart
│   │   ├── entry_edit_screen.dart
│   │   ├── chick_batch_screen.dart    # Batch detail + dynamic progress bar + eggsToLockdown field
│   │   └── chick_sexing_screen.dart
│   ├── insights/
│   │   └── insights_screen.dart       # Stats dashboard; _StatCard accepts icon or iconWidget
│   └── settings/
│       └── settings_screen.dart       # API key + egg grading standard + weight unit
├── utils/
│   ├── breed_incubation_table.dart  # Local breed→incubation lookup (~80 breeds) + AI fallback
│   ├── date_parser.dart
│   ├── egg_color_matcher.dart
│   ├── egg_grade_standard.dart      # EggGradeStandard enum (ukEu, usda) + EggGradeHelper
│   └── export_utils.dart
└── widgets/
    ├── hen_icon.dart             # Custom CustomPainter hen silhouette
    ├── skull_icon.dart           # Custom CustomPainter skull (for loss event button)
    └── coop_icon.dart
```

---

## Database schema (v7)

> **Schema history:** v1→v2→v3→v4→v5 (legacy) → v6 (added incubation_days, hatch_window_days to chick_batches) → v7 (added purpose, live_weight_grams, dressed_weight_grams to chickens; added eggs_to_lockdown, lockdown_dismissed_date to chick_batches)

### `flock_groups`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| name | TEXT | |
| color_hex | TEXT | e.g. `#5D8A3C` |
| notes | TEXT | nullable |
| created_at | TEXT | ISO 8601 |

### `chickens`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| name | TEXT | |
| breed | TEXT | nullable |
| hatch_date | TEXT | nullable ISO 8601 |
| color | TEXT | feather colour, nullable |
| notes | TEXT | nullable |
| photo_path | TEXT | nullable local path |
| egg_color_category | TEXT | nullable; one of 12 categories |
| egg_sample_photos_json | TEXT | nullable JSON array of paths |
| is_active | INTEGER | 1/0 legacy field (status preferred) |
| status | TEXT | `active` / `deceased` / `missing` / `slaughtered` |
| status_date | TEXT | nullable |
| status_note | TEXT | nullable |
| flock_group_id | TEXT | FK → flock_groups, nullable |
| gender | TEXT | `female` / `male` / `probably_female` / `probably_male` / `unknown` |
| acquired_via | TEXT | `hatched` / `bought` |
| buy_date | TEXT | nullable |
| age_at_purchase_weeks | INTEGER | nullable |
| purpose | TEXT | `layer` (default) / `meat` / `dual` |
| live_weight_grams | REAL | nullable — live weight at slaughter |
| dressed_weight_grams | REAL | nullable — oven-ready weight |
| created_at | TEXT | |

**Computed getters on `Chicken` model:**
- `estimatedHatchDate` — back-calculates for bought birds from buyDate + ageAtPurchaseWeeks
- `currentAgeInDays`, `ageDisplay` — "9 weeks", "7 months", "2 years 3 months"
- `displayTerm` — Pullet / Hen / Cockerel / Rooster / Chicken (age + gender aware)
- `isActive`, `isProbableGender`, `resolvedGender`
- `dressingPercentage` — dressed ÷ live × 100, null if either weight missing
- `purposeLabel` — "Meat Bird" / "Dual Purpose" / "Layer"

### `loss_events`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | |
| title | TEXT | e.g. "Fox attack" |
| status_applied | TEXT | `slaughtered` / `deceased` / `missing` |
| date | TEXT | |
| affected_chicken_ids_json | TEXT | JSON array |
| notes | TEXT | nullable |
| created_at | TEXT | |

### `journal_entries`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | |
| track_type | TEXT | `general` / `flock` / `chick` |
| title | TEXT | |
| content | TEXT | |
| date | TEXT | fully retroactive |
| tags | TEXT | comma-separated |
| photo_paths_json | TEXT | nullable JSON array |
| chick_batch_id | TEXT | FK → chick_batches, nullable |
| chick_stage | TEXT | nullable; one of 5 stages |
| created_at | TEXT | |
| updated_at | TEXT | |

### `chick_batches`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | |
| name | TEXT | |
| breed | TEXT | nullable |
| start_date | TEXT | day 0 of incubation |
| egg_count | INTEGER | eggs set |
| eggs_hatched | INTEGER | nullable |
| incubator_type | TEXT | nullable |
| notes | TEXT | nullable |
| status | TEXT | `incubating` / `hatching` / `raising` / `growing` / `completed` |
| incubation_days | INTEGER | default 21; breed-aware via lookup |
| hatch_window_days | INTEGER | default 3; extra days past expected hatch |
| eggs_to_lockdown | INTEGER | nullable; eggs after candling — usually < egg_count |
| lockdown_dismissed_date | TEXT | nullable; prevents lockdown prompt re-firing same day |
| created_at | TEXT | |

**Computed getters on `ChickBatch` model:**
- `expectedHatchDate`, `lastHatchDate`, `totalTrackedDays`
- `daysIncubated` — capped at totalTrackedDays
- `isOverdue` — past the full hatch window
- `lockdownDate` — incubationDays - 3
- `isOnLockdownDay`, `lockdownDismissedToday`, `showLockdownPrompt`
- `incubationProgress`, `isInHatchWindow`, `hatchRate`

### `egg_records`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | |
| chicken_id | TEXT | FK → chickens, nullable |
| breed_note | TEXT | nullable free-text for unassigned |
| weight_grams | REAL | always stored in grams |
| egg_color_category | TEXT | one of 12 categories |
| date | TEXT | |
| photo_path | TEXT | nullable |
| notes | TEXT | nullable |
| created_at | TEXT | |

**Computed:** `sizeGrade` — derived at display time from active `EggGradeStandard`. Raw grams are always stored.

### `sexing_assessments`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | |
| chicken_id | TEXT | FK → chickens |
| assessed_at | TEXT | |
| age_weeks | INTEGER | nullable |
| claude_result | TEXT | `female` / `male` / `uncertain` |
| claude_confidence | TEXT | `high` / `medium` / `low` |
| claude_reasoning | TEXT | |
| claude_caveats | TEXT | nullable |
| user_call | TEXT | nullable |
| displayed_gender | TEXT | what was saved to the bird |

---

## Egg grading system (`utils/egg_grade_standard.dart`)

```dart
enum EggGradeStandard { ukEu, usda }
```

**UK/EU (default):** S <53g · M 53–63g · L 63–73g · XL ≥73g

**US USDA (6-tier):** Peewee <42g · Small 42–49g · Medium 49–56g · Large 56–63g · XL 63–70g · Jumbo ≥70g

- Raw weights stored in grams always
- `EggGradeHelper.sizeGrade(weightGrams, standard)` derives the label at display time
- Switching standard re-grades all historical data instantly with no data loss
- User sets standard in Settings; persisted in `flutter_secure_storage`

## Weight unit preference (`providers/settings_provider.dart`)

```dart
enum WeightUnit { grams, oz }
```

- Default: grams
- Raw weights always stored internally in grams; conversion at input + display
- `settings.formatWeight(grams)` → display string e.g. "62.3g" or "2.2oz"
- `settings.toGrams(value, unit)` / `settings.fromGrams(grams, unit)`
- Independent of grading standard

### Claude Vision + weight units
The egg capture screen asks Claude to read the scale weight from a photo. If the unit is ambiguous:
1. Claude returns the value without unit and flags ambiguity
2. App shows inline prompt: "We couldn't confirm the unit — is this in g or oz?"
3. User confirms; app stores in grams after conversion

---

## AI service — `ClaudeService`

Model: `claude-opus-4-6`
API key: stored in `flutter_secure_storage`, set via Settings screen.

### `analyzeEggPhoto(File imageFile) → ClaudeEggResult`
- Compresses photo, sends base64 to Claude Vision
- Prompt reads scale weight + egg colour; respects user's weight unit
- Returns `{ weightGrams: double?, eggColorCategory: string, unitAmbiguous: bool }`

### `analyzeChickSex(List<File> images, {breed?, ageWeeks?}) → ChickSexResult`
- Returns `{ likelySex, confidence, reasoning, caveats }`
- Stored as `SexingAssessment`; user can override before saving to bird profile

---

## Screens in detail

### Home screen (`home_screen.dart`)
- **Consumer3<JournalProvider, ChickenProvider, EggProvider>**
- **Dynamic greeting** (`_buildGreeting()`) — rotating farm phrases by time of day, flock-aware lines (egg counts, hen names, hatch days), occasional chicken facts. Seed = `DateTime.now().hour` so it rotates hourly. Implemented as a single swappable method — can revert to static greeting by replacing one call.
- **Lockdown prompt** (`_LockdownPromptCard`) — shown when `batch.showLockdownPrompt` is true; inline number input + Save; dismissible with X; does not reappear same day
- **Incubation cards** (`_IncubationCard`) — one per active batch:
  - Within hatch window: two-tone progress bar (green = incubation, amber = hatch window) + milestone markers
  - Past hatch window (`isOverdue`): replaces bar with compact "Finalise this clutch" prompt → taps to batch screen
  - All uses `batch.incubationDays` and `batch.hatchWindowDays` — no hardcoded 21

### Flock screen (`flock_screen.dart`)
- **Drag-and-drop** — `LongPressDraggable<Chicken>` wraps each bird card (delay 350ms); `DragTarget<Chicken>` wraps each group header; dropping on a header calls `chickenProvider.updateChicken(chicken.copyWith(flockGroupId: targetGroup?.id))`; target group highlights with translucent colour on hover
- **Meat bird cards** — if `chicken.purpose == 'meat'`, card shows prime roasting window instead of egg count:
  - Cornish/broiler/Ross: 6–8 weeks from hatch
  - Ranger/Freedom Ranger/hybrid: 9–11 weeks
  - Default/heritage: 16–20 weeks
  - Shows "In prime window" (green) / "Prime window: 5 Apr – 3 Jun" (orange) / "Past prime window" (grey)
  - Falls back to "Set hatch date" prompt if no hatch date recorded
- **Loss event** — skull icon top-right; default status = Slaughtered; dropdown order: Slaughtered → Deceased → Missing
- **Manage groups** — HenIcon top-right
- **Archived section** — expandable at bottom

### Bird detail screen (`chicken_detail_screen.dart`)
- Tap photo → fullscreen lightbox (`_PhotoLightbox` with `InteractiveViewer`; dismiss by tap or swipe down)
- Purpose badge, live weight, dressed weight, dressing % shown in header if set

### Bird edit screen (`chicken_edit_screen.dart`)
- Camera overlay on photo (dark 28% scrim + camera icon) in edit mode — signals photo is tappable
- **Purpose** SegmentedButton: Layer / Meat / Dual Purpose
- **Slaughter weights** — live weight + dressed weight fields shown when status = Slaughtered; dressing % auto-calculated and displayed

### Eggs tab (`egg_tracker_screen.dart`)
- Each card right column: weight (bold) → Row containing [12px colour dot] [size grade badge]
- Size grade derived from active `EggGradeStandard` (Settings)

### Clutch / batch screen (`chick_batch_screen.dart`)
- **Eggs to lockdown** field — between "Eggs hatched" and "Incubator" fields; optional; accepts retro entry at any point; saves to `batch.eggsToLockdown`
- Two-tone progress bar — dynamic based on `_incubationDays` + `_hatchWindowDays`
- Breed lookup — on blur, calls `lookupBreedIncubation(breed)` (local table first, Claude Haiku fallback)
- Steppers for incubation period (14–42 days) and hatch window (0–7 days)

### Insights tab (`insights_screen.dart`)
- `_StatCard` accepts either `icon: IconData` or `iconWidget: Widget` (allows custom icons)
- **Total Clutches**: `Icons.bubble_chart_outlined`
- **Chicks Hatched**: `HenIcon(size: 20)`
- **Active Birds**: `HenIcon(size: 20)` (NOT Icons.pets)

### Settings screen (`settings_screen.dart`)
- API key (stored in secure storage)
- **Egg Settings** card: grading standard SegmentedButton (UK/EU | US USDA) + weight unit SegmentedButton (g | oz)

---

## Provider summary

### `ChickenProvider`
- Holds: `_chickens`, `_flockGroups`, `_lossEvents`
- Getters: `activeChickens`, `archivedChickens`, `chickensInGroup(id)`, `ungroupedChickens`, `getById(id)`
- Methods: `addChicken`, `updateChicken`, `deleteChicken`, `addFlockGroup`, `updateFlockGroup`, `deleteFlockGroup`, `deleteFlockGroupWithBirds`, `logLossEvent`, `deleteLossEvent`, `nameUngroupedChickens`, `addHatchBatch`, `findByEggColor`
- `addChicken` / `updateChicken` accept: `purpose`, `liveWeightGrams`, `dressedWeightGrams`

### `EggProvider`
- Holds: `_records`
- Stats: `averageWeight`, `eggsThisWeek(chickenId?)`, `eggsPerWeek`, `eggsPerMonth`, `sizeGradeDistribution`
- Methods: `addRecord`, `updateRecord`, `deleteRecord`, `removeRecordsForChicken`

### `JournalProvider`
- Holds: `_entries`, `_batches`
- Methods: `addEntry`, `updateEntry`, `deleteEntry`, `addBatch`, `updateBatch`, `deleteBatch`, `getBatchById(id)`

### `SettingsProvider` (ChangeNotifier)
- Persisted in `flutter_secure_storage`
- `gradingStandard` (EggGradeStandard) + `weightUnit` (WeightUnit)
- `setGradingStandard(s)`, `setWeightUnit(u)`
- `formatWeight(grams)` → display string respecting unit
- `toGrams(value, unit)` / `fromGrams(grams, unit)`

### `SexingProvider`
- Lazy-loaded per chicken
- Methods: `forChicken(id)`, `loadForChicken(id)`, `addAssessment`, `deleteAssessment`, `removeForChicken`

---

## Theme

```dart
seedColor = Color(0xFF5D8A3C)   // earthy green
accentAmber = Color(0xFFD4A017) // golden amber
surfaceTint = Colors.transparent // prevents yellow-green Material 3 surface tint
```
Material 3, light + dark mode. FAB: green. Cards: elevation 1, 12px radius.

---

## Custom widgets

### `HenIcon` (`widgets/hen_icon.dart`)
`CustomPainter` hen silhouette. Parameters: `size` (default 24), `color` (default onPrimary). Used in Flock bottom nav, Manage Groups button, Insights stat cards, empty-state placeholders.

### `SkullIcon` (`widgets/skull_icon.dart`)
`CustomPainter` chicken skull. Parameters: `size`, `color`. Used in Flock screen top-right (Log Loss Event button).

---

## Egg colour categories (12)

```
white, cream, light_brown, medium_brown, dark_brown, speckled_brown,
blue, blue_green, pink, olive, green, unknown
```

---

## Build & release conventions (ALWAYS follow)

1. Bump `pubspec.yaml` — `major.minor.patch+buildNumber` — buildNumber must always increase
   - Major: redesign / architectural overhaul | Minor: new feature | Patch: bug fix / polish
2. `flutter build apk --release` (Flutter at `/opt/homebrew/share/flutter/bin/flutter`)
3. Rename APK: `FlockLedger_v{version}+{build}.apk` — never overwrite old ones
4. `git commit` the version bump
5. `git tag v{version}` + `git push origin main --tags`
6. `gh release create v{version} {apk} --title "..." --notes "..."`
7. Open Finder at APK output folder

**Signing:** Always `~/.android/debug.keystore` — never delete, never regenerate.
**Install:** Always over existing app — never uninstall first (wipes data).
**applicationId / DB filename:** `chicken_journal` (kept intentionally to preserve existing on-device data despite app rename).

---

## Version history

| Version | Build | What shipped |
|---|---|---|
| 1.8.1 | 24 | Loss event order/default fix; egg size grade on colour dot line; Active Birds → HenIcon; meat bird prime roasting window; drag-and-drop birds between groups; eggsToLockdown field in clutch screen |
| 1.8.0 | 23 | Bird purpose (layer/meat/dual); slaughter weights + dressing %; bird photo lightbox; camera edit overlay; egg grading standard (UK/EU + USDA); weight unit (g/oz); dynamic home greeting; lockdown day prompt; overdue hatch state; SkullIcon + HenIcon for flock buttons; Insights icon updates; DB v7 |
| 1.7.0 | 22 | App renamed FlockLedger; breed incubation lookup (local + AI fallback); hatch window stepper; two-tone progress bar; DB v6; surfaceTint fixed |

---

## Pending / not yet built

### Total Clutches icon
The current icon `Icons.bubble_chart_outlined` needs replacing. Options offered (not yet chosen):
- `Icons.workspaces_outlined` — three overlapping circles
- `Icons.apps_outlined` — grid of dots
- `Icons.scatter_plot_outlined` — scattered dots (egg-like)
- `Icons.grid_view_outlined` — grid squares
- `Icons.layers_outlined` — stacked layers (was the original before bubble_chart)

### App icon
Needs further refinement (details TBD — user to specify).

### Deferred (complex — own build)
- **Same-colour egg attribution** — dual mode per group: Collective (daily total ÷ active hens) vs Individual (per-hen logging via trapnest/leg ring)
- **Drag-and-drop between groups** — ✅ shipped in v1.8.1

---

## How to run locally

```bash
cd ~/Annie-Claude/chicken_journal
flutter pub get
flutter run          # deploys to connected Android phone via USB
```

Build release APK:
```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```
