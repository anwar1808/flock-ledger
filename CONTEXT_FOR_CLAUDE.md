# FlockLedger — Full Project Context

> Feed this file to Claude.ai to continue work on the app with full context.
> Current date captured: 2026-03-29 | Current version: **1.7.0+22**
> GitHub: https://github.com/anwar1808/flock-ledger

---

## What this app is

**FlockLedger** (formerly FlockLedger) is a personal Android app (Flutter) for tracking a backyard chicken flock. It records:
- General / flock / chick journal entries
- Egg records (weight, colour, hen, photo) — weights read automatically from scale photos via Claude Vision AI
- Flock management (individual birds, groups, status tracking)
- Chick batches (incubation tracking with 21-day progress bar)
- AI-powered chick sexing assessments via Claude Vision
- Export to Excel

All data is local (SQLite on-device). Only compressed photos are ever sent externally (to Anthropic API for AI analysis).

---

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart), targets Android |
| State management | `provider` ^6.1.2 — `ChangeNotifier` pattern |
| Local DB | `sqflite` ^2.3.3, schema version 5 |
| AI | Anthropic Claude API (`claude-opus-4-6`) via `http` ^1.2.0 |
| Charts | `fl_chart` ^0.68.0 |
| Export | `excel` ^4.0.3 + `share_plus` ^9.0.0 |
| Image | `image_picker` ^1.0.7, `flutter_image_compress` ^2.3.0 |
| EXIF | `exif` ^3.3.0 (date extraction from photo filenames) |
| Secure storage | `flutter_secure_storage` ^9.0.0 (API key) |
| IDs | `uuid` ^4.3.3 |
| Localisation | `intl` ^0.19.0 |

**pubspec version:** `1.7.0+22`

---

## Project structure

```
lib/
├── main.dart                    # Entry point; initialises DB, sets up providers
├── app.dart                     # MaterialApp, theme (earthy green #5D8A3C + amber #D4A017)
├── database/
│   └── database_helper.dart     # Singleton DB; all CRUD; schema v5
├── models/
│   ├── chicken.dart             # Chicken model + egg colour constants
│   ├── egg_record.dart          # EggRecord model + USDA size grades
│   ├── journal_entry.dart       # JournalEntry model + track/stage constants
│   ├── chick_batch.dart         # ChickBatch model + incubation maths
│   ├── flock_group.dart         # FlockGroup model + colour presets
│   ├── loss_event.dart          # LossEvent model
│   └── sexing_assessment.dart   # SexingAssessment model (AI chick sexing)
├── providers/
│   ├── chicken_provider.dart    # Chickens, flock groups, loss events
│   ├── egg_provider.dart        # Egg records + stats
│   ├── journal_provider.dart    # Journal entries + chick batches
│   └── sexing_provider.dart     # Sexing assessments (lazy-loaded per bird)
├── services/
│   └── claude_service.dart      # Anthropic API calls (egg analysis + sexing)
├── screens/
│   ├── main_screen.dart         # Bottom nav: Home / Eggs / Flock / Insights
│   ├── home/
│   │   └── home_screen.dart     # Dashboard / Journal tab
│   ├── eggs/
│   │   ├── egg_tracker_screen.dart   # Egg list + export button
│   │   ├── egg_capture_screen.dart   # Photo → Claude → review/edit → save
│   │   └── egg_stats_screen.dart     # Charts (weekly/monthly production, weight trends)
│   ├── flock/
│   │   ├── flock_screen.dart         # Bird list grouped by flock group
│   │   ├── chicken_detail_screen.dart # Per-bird stats, egg history, sexing history
│   │   ├── chicken_edit_screen.dart   # Add/edit a bird
│   │   ├── flock_group_edit_screen.dart # Add/edit a group
│   │   ├── batch_hatch_screen.dart    # Add multiple birds from a hatch
│   │   └── loss_event_screen.dart     # Log a loss/death/missing event
│   ├── journal/
│   │   ├── journal_screen.dart        # Tab bar: General / Flock / Chick
│   │   ├── entry_list_screen.dart     # Scrollable entry list per track
│   │   ├── entry_edit_screen.dart     # Add/edit a journal entry
│   │   ├── chick_batch_screen.dart    # Batch detail + 21-day progress
│   │   └── chick_sexing_screen.dart   # Upload photos → Claude sex assessment
│   ├── insights/
│   │   └── insights_screen.dart       # Overview stats dashboard
│   └── settings/
│       └── settings_screen.dart       # API key management
├── utils/
│   ├── date_parser.dart         # Extract date from image filename (IMG_YYYYMMDD…)
│   ├── egg_color_matcher.dart   # Match egg colour category to a hen
│   └── export_utils.dart        # Build and share Excel file
└── widgets/
    ├── hen_icon.dart             # Custom SVG-like hen icon widget
    └── coop_icon.dart            # Custom coop icon widget
```

---

## Database schema (v5)

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
| flock_group_id | TEXT | FK → flock_groups |
| gender | TEXT | `female` / `male` / `probably_female` / `probably_male` / `unknown` |
| acquired_via | TEXT | `hatched` / `bought` |
| buy_date | TEXT | nullable |
| age_at_purchase_weeks | INTEGER | nullable |
| created_at | TEXT | |

**Computed getters on `Chicken` model:**
- `estimatedHatchDate` — back-calculates for bought birds
- `currentAgeInDays`, `ageDisplay` — "9 weeks", "7 months", "2 years 3 months"
- `displayTerm` — Pullet / Hen / Cockerel / Rooster / Chicken (age + gender aware)
- `isActive`, `isProbableGender`, `resolvedGender`

### `loss_events`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | |
| title | TEXT | e.g. "Fox attack" |
| status_applied | TEXT | `deceased` / `missing` / `slaughtered` |
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
| date | TEXT | fully retroactive — can be any past date |
| tags | TEXT | comma-separated |
| photo_paths_json | TEXT | nullable JSON array |
| chick_batch_id | TEXT | FK → chick_batches, nullable |
| chick_stage | TEXT | nullable; one of 5 stages |
| created_at | TEXT | when actually typed |
| updated_at | TEXT | |

**Track types:** `general`, `flock`, `chick`
**Chick stages:** `incubating`, `hatching`, `brooding`, `weaning`, `graduated`

### `chick_batches`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | |
| name | TEXT | |
| breed | TEXT | nullable |
| start_date | TEXT | day 0 of incubation |
| egg_count | INTEGER | |
| eggs_hatched | INTEGER | nullable |
| incubator_type | TEXT | nullable |
| notes | TEXT | nullable |
| status | TEXT | `incubating` / `hatching` / `raising` / `growing` / `completed` |
| created_at | TEXT | |

**Computed:** `expectedHatchDate` (start + 21 days), `daysIncubated`, `daysRemaining`, `incubationProgress` (0.0–1.0), `hatchRate`

### `egg_records`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | |
| chicken_id | TEXT | FK → chickens, nullable (unassigned egg) |
| breed_note | TEXT | nullable free-text for unassigned |
| weight_grams | REAL | |
| egg_color_category | TEXT | one of 12 categories |
| date | TEXT | |
| photo_path | TEXT | nullable |
| notes | TEXT | nullable |
| created_at | TEXT | |

**Computed:** `sizeGrade` — Peewee / Small / Medium / Large / XL / Jumbo (USDA weights)

### `sexing_assessments`
| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | |
| chicken_id | TEXT | FK → chickens |
| assessed_at | TEXT | |
| age_weeks | INTEGER | nullable |
| claude_result | TEXT | `female` / `male` / `uncertain` |
| claude_confidence | TEXT | `high` / `medium` / `low` |
| claude_reasoning | TEXT | 1–3 sentences |
| claude_caveats | TEXT | nullable breed/age warnings |
| user_call | TEXT | nullable; `probably_female` / `probably_male` |
| displayed_gender | TEXT | what was saved to the flock page |

**Indexes:** `journal_entries(date DESC)`, `journal_entries(track_type)`, `egg_records(date DESC)`, `egg_records(chicken_id)`, `sexing_assessments(chicken_id)`

---

## Egg colour categories (12)

```
white, cream, light_brown, medium_brown, dark_brown, speckled_brown,
blue, blue_green, pink, olive, green, unknown
```

---

## AI service — `ClaudeService`

Model: `claude-opus-4-6`
API key: stored in `flutter_secure_storage`, set via Settings screen.

### `analyzeEggPhoto(File imageFile) → ClaudeEggResult`
- Compresses photo, sends base64 to Claude Vision
- Prompt: reads scale weight + egg colour from the image
- Returns: `{ weightGrams: double?, eggColorCategory: string }`
- `weightGrams` is null if Claude can't read the display

### `analyzeChickSex(List<File> images, {breed?, ageWeeks?}) → ChickSexResult`
- Sends 1+ chick photos + breed/age context
- Returns: `{ likelySex: 'female'|'male'|'uncertain', confidence: 'high'|'medium'|'low', reasoning: string, caveats: string? }`
- Result is stored as a `SexingAssessment`; user can accept or override the gender saved to the bird's profile

---

## Screens overview

### Bottom navigation (4 tabs)
1. **Home** (Coop icon) — Journal screen with General/Flock/Chick tabs
2. **Eggs** (egg icon) — Egg tracker list; top-right: chart button + Excel export
3. **Flock** (hen icon) — Bird list grouped by flock; top-right: loss event + manage groups
4. **Insights** (chart icon) — Stats dashboard; top-right: settings (API key)

### Journal tab
- Three filter chips: **General / Flock / Chick**
- Chick tab shows active batches with progress bars then entry list
- Entries fully retroactive (any past date)
- Entries can have photos attached

### Eggs tab
- Lists all egg records sorted by date descending
- Each card: photo thumbnail, date, hen name, weight, colour, size grade
- Tap card: expand to edit weight/hen/colour/notes
- **Add eggs**: opens `EggCaptureScreen` — pick photos from gallery → each photo sent to Claude → review results → save
- Date auto-extracted from filename (IMG_YYYYMMDD pattern)
- **Chart button**: weekly production bar chart + weight trend line, per-hen filter, monthly view, size grade pie
- **Export**: shares Excel file (egg records + per-hen sheets + batch records)

### Flock tab
- Birds listed in coloured group sections, ungrouped at bottom
- Each card: photo/avatar, name, breed, age, gender, eggs-this-week badge
- Tap: `ChickenDetailScreen` — egg history, stats, AI sexing history
- Long-press: edit or delete bird
- **Add sheet**: "Add one bird" or "Add from a hatch" (batch create)
- **Manage groups**: create/rename/delete flock groups
- **Log loss event**: mark birds as deceased/missing/slaughtered with a named event
- Archived section at bottom for non-active birds

### Chicken detail screen
- Header: photo, name, breed, age, gender (with probable indicator), flock group
- Stats: total eggs, average weight, eggs this week
- Full egg history list
- AI sexing history with confidence badges
- "Assess sex" button → `ChickSexingScreen`

### Insights tab
- Total eggs all-time, average weight, most productive hen
- Monthly egg count bar chart
- Settings gear → API key entry + test

---

## Provider summary

### `ChickenProvider`
- Holds: `_chickens`, `_flockGroups`, `_lossEvents`
- Getters: `activeChickens`, `archivedChickens`, `chickensInGroup(id)`, `ungroupedChickens`
- Methods: `addChicken`, `updateChicken`, `deleteChicken`, `addFlockGroup`, `updateFlockGroup`, `deleteFlockGroup`, `deleteFlockGroupWithBirds`, `logLossEvent`, `deleteLossEvent`, `nameUngroupedChickens`, `addHatchBatch`, `findByEggColor`

### `EggProvider`
- Holds: `_records` (all egg records)
- Stats: `averageWeight`, `averageWeightForChicken`, `eggsPerWeek`, `eggsPerMonth`, `sizeGradeDistribution`, `eggsThisWeek`
- Methods: `addRecord`, `updateRecord`, `deleteRecord`, `removeRecordsForChicken`

### `JournalProvider`
- Holds: `_entries`, `_batches`
- Getters: `entriesByTrack(type)`, `entriesForBatch(id)`
- Methods: `addEntry`, `updateEntry`, `deleteEntry`, `addBatch`, `updateBatch`, `deleteBatch`

### `SexingProvider`
- Lazy-loaded per chicken: `forChicken(id)`, `loadForChicken(id)`
- Methods: `addAssessment`, `deleteAssessment`, `removeForChicken`

---

## Theme

```dart
seedColor = Color(0xFF5D8A3C)   // earthy green
accentAmber = Color(0xFFD4A017) // golden amber

// AppBar bg:
// light: Color(0xFFEFF5E8)
// dark:  Color(0xFF1A2212)
```
Material 3, supports light + dark mode. FAB: green. Cards: elevation 1, 12px border radius. Chips: 20px radius.

---

## Build & release conventions (ALWAYS follow)

1. Bump `pubspec.yaml` version — format `major.minor.patch+buildNumber`
   - `+buildNumber` must always increase (Android uses it to decide whether to update without wiping data)
   - Major: redesign / architectural overhaul | Minor: new feature/screen | Patch: bug fix / polish
2. `flutter build apk --release`
3. Rename APK: `chicken-journal-v{version}.apk` (never overwrite old APKs)
4. `git commit` the version bump
5. `git tag v{version}` + `git push origin main --tags`
6. `gh release create v{version} {apk} --title "..." --notes "..."`
7. Open Finder at APK output folder

**Signing:** Always uses `~/.android/debug.keystore`. Never delete it. Never uninstall the app before installing a new version — it wipes data.

**APK history in project folder:**
`v1.4.0`, `v1.4.1`, `v1.4.2`, `v1.5.0`, `v1.5.1`, `v1.5.2`, `v1.5.3`, `v1.5.4`, `v1.5.5`, `v1.5.6`
(v1.6.x APKs are in `build/app/outputs/flutter-apk/` and GitHub Releases)

---

## Key design decisions

- **All data on-device** — SQLite, nothing uploaded except compressed photos to Anthropic API
- **Retroactive entries** — journal entries and egg records can be backdated to any past date; `isRetroactive` flag on `JournalEntry`
- **Unassigned eggs** — egg records don't require a hen; `breedNote` is a free-text alternative
- **Flock groups** — optional colour-coded groups; birds can be ungrouped
- **Loss events** — named events (e.g. "Fox attack") that batch-update bird statuses; stored separately for history
- **Sexing** — AI assessment is advisory only; user can override; both AI result and user call stored; `displayedGender` is what shows on the flock page
- **Egg colour matching** — `egg_color_matcher.dart` utility can suggest which hen laid an unassigned egg based on their registered egg colour

---

## File: `utils/export_utils.dart`
Builds a multi-sheet Excel file:
- Sheet 1: All egg records (date, hen, weight, colour, size grade, notes)
- One sheet per hen: her individual egg history
- Sheet: Chick batches (name, breed, dates, count, hatch rate)
Shared via `share_plus`.

## File: `utils/date_parser.dart`
Extracts date from image filename. Pattern: `IMG_YYYYMMDD_…` or `YYYYMMDD_…`. Falls back to `DateTime.now()`.

## File: `utils/egg_color_matcher.dart`
Given an egg colour category, returns a list of hens registered with that colour. Used in `EggCaptureScreen` to auto-suggest the hen assignment.

---

## Recent changes (v1.7.0)
- App renamed from ChickenJournal to FlockLedger
- `ChickenJournalApp` class renamed to `FlockLedgerApp`
- GitHub repo: `anwar1808/chicken-journal` → `anwar1808/flock-ledger`
- `applicationId` and DB filename intentionally kept as `chicken_journal` to preserve existing data on-device
- Added `lib/utils/breed_incubation_table.dart` — local breed→incubation lookup (~80 breeds) + Claude AI fallback (Haiku model, bundled obfuscated key + user key priority)
- `ChickBatch` model: added `incubationDays` (default 21) + `hatchWindowDays` (default 3); all hardcoded `21`s replaced with dynamic values
- DB schema v5→v6: two new columns on `chick_batches` with DEFAULT fallbacks for existing records
- Batch creation screen: breed field triggers lookup on blur; two steppers (incubation period + hatch window); two-tone progress bar (green = incubation, amber = hatch window); milestones reposition dynamically
- Theme: added `surfaceTint: Colors.transparent` to remove yellow-green Material 3 surface tint — reversible by deleting that one line in `lib/app.dart`

## Pending iterations (not yet built)
1. Overdue hatch state (Option D) — past hatch window shows "finalise this clutch" prompt instead of progress bar; fix home screen hardcoded `21`
2. Dynamic home greeting (Option 6) — farm time-of-day language + flock-aware data + fun facts; behind a single swappable method for easy revert
3. Lockdown day prompt — home screen action item on lockdown day asking how many eggs are going into lockdown (separate from eggs-set count)
4. Bird detail screen — tap photo to open fullscreen lightbox
5. Bird edit screen — camera/edit icon overlay on photo to indicate it's tappable
6. Flock screen top-right icons — loss event icon → chicken skull; manage groups icon → hen icon (same as bottom nav)

---

## How to run locally

```bash
cd ~/Annie-Claude/chicken_journal
flutter pub get
flutter run          # deploys to connected Android phone via USB
```

To build release APK:
```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```
