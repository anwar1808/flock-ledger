# ChickenJournal — Setup Guide

A personal Android app for journalling your chicken-keeping adventures. Records general observations, flock notes, hatch batches, and egg weights (read automatically from scale photos using AI).

---

## What you'll need (one-time setup)

1. **Flutter SDK** — the free tool that builds the app
2. **Android Studio** — the free tool that lets you send the app to your phone
3. **USB Debugging** enabled on your Android phone
4. **An Anthropic API key** — for reading egg weights from photos (fractions of a cent per photo)

---

## Step 1 — Install Flutter

1. Go to **flutter.dev** → click "Get started" → choose your Mac.
2. Download the Flutter SDK zip, unzip it, and move the `flutter` folder to your home folder (`/Users/yourname/flutter`).
3. Open Terminal and run:
   ```
   export PATH="$HOME/flutter/bin:$PATH"
   flutter doctor
   ```
4. Follow any instructions `flutter doctor` gives you. It tells you exactly what's missing.

---

## Step 2 — Install Android Studio

1. Download from **developer.android.com/studio** (free).
2. Run the installer and accept all defaults.
3. Open Android Studio → go to **Settings → SDK Manager** → check that "Android SDK" is installed.

---

## Step 3 — Enable USB Debugging on your phone

1. Open **Settings** on your Android phone.
2. Scroll to **About phone** → tap **Build number** 7 times until it says "You are now a developer!".
3. Go back to **Settings → System → Developer options**.
4. Turn on **USB Debugging**.

---

## Step 4 — Connect your phone and run the app

1. Plug your phone into your Mac with a USB cable.
2. On your phone, tap **Allow** when asked "Allow USB debugging?".
3. Open Terminal, go to the app folder:
   ```
   cd ~/chicken_journal
   ```
4. Install the app's dependencies:
   ```
   flutter pub get
   ```
5. Run the app on your phone:
   ```
   flutter run
   ```
   The first time this takes a few minutes to build. You'll see "Running on [your phone name]" and then the app will open.

---

## Step 5 — Get an Anthropic API key

This is what lets the app read egg weights from your scale photos using AI.

1. Go to **console.anthropic.com** and sign up (free).
2. Click **API Keys** → **Create Key** → copy the key (starts with `sk-ant-`).
3. Open the app on your phone → go to **Insights** tab → tap the settings ⚙ icon.
4. Paste your API key and tap **Save Key**.

Each photo costs about **$0.001–0.003** (a fraction of a cent). You only pay for what you use.

---

## How to use the app

### Journal tab
- Tap the **General / Flock / Chick** chips at the top to switch track.
- Tap **+** to record a note. You can set any past date — great for catching up on older observations.
- **Chick tab**: tap "New Clutch" to start tracking an incubation batch. You'll see a 21-day progress bar and milestone markers.

### Eggs tab
- Tap **Add eggs** to choose photos from your gallery.
- The app automatically reads the date from the filename and sends each photo to Claude AI to read the weight and egg colour.
- You can always correct the weight or assign a different hen.
- Tap the **chart icon** (top right) to see weekly production and weight trends.
- Tap the **download icon** to export everything to an Excel file you can open in Google Sheets.

### Flock tab
- Tap **+** to add each of your hens: name, breed, hatch date, egg colour.
- Tap any hen to see her full egg history and stats.

### Insights tab
- Overview dashboard: total eggs, average weight, most productive hen, monthly bar chart.

---

## Keeping the app up to date

When I send you an update, just copy the new files into the `chicken_journal` folder and run `flutter run` again.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `flutter: command not found` | Run `export PATH="$HOME/flutter/bin:$PATH"` in Terminal first |
| Phone not detected | Make sure USB Debugging is on and you tapped "Allow" on the phone |
| "No API key set" warning on egg photos | Go to Insights → Settings ⚙ and paste your key |
| Scale weight not read | Tap the photo card to expand it and type the weight manually |
| App crashes on first run | Run `flutter clean && flutter pub get && flutter run` |

---

## Privacy

- All your journal data stays on your phone (SQLite database, never uploaded anywhere).
- Photos are compressed and stored on your phone only.
- When you analyse an egg photo, **only the compressed photo** is sent to Anthropic's API. Nothing else leaves your device.
- Your API key is stored in your phone's secure encrypted storage.
