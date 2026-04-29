# PressureMonitor

A macOS menu bar app that polls barometric pressure for any location and alerts you when the pressure will drop below a configurable threshold (in inches of mercury).

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![No API key](https://img.shields.io/badge/API%20key-none%20required-green)

<img width="312" height="361" alt="main" src="https://github.com/user-attachments/assets/f7a73dc2-7a85-41da-ba96-1a5b97d6f838" />
<img width="367" height="514" alt="settings" src="https://github.com/user-attachments/assets/8d3a679e-9680-4cc0-9937-04887e839a39" />

---

## What it does

- Shows current sea-level and surface pressure in the menu bar, color-coded by value
- Displays a 24-hour forecast chart when you click the menu bar icon
- Sends a local notification when the forecast predicts pressure will drop below a configurable threshold
- Supports any location by ZIP code or latitude/longitude

### Pressure color scale

| Color | Range | Meaning |
|---|---|---|
| 🔴 Red | < 29.70 inHg | Very low / storm conditions |
| 🔵 Blue | 29.70 – 29.92 inHg | Low pressure |
| ⚪ White | 29.92 – 30.12 inHg | Normal / neutral |
| 🟠 Orange | > 30.12 inHg | High pressure |

---

## Running a pre-built binary (no Xcode needed)

If someone has shared a `PressureMonitor.zip` with you:

1. Unzip it and move `PressureMonitor.app` to your `/Applications` folder
2. **First launch only** — because the app is unsigned, macOS Gatekeeper will block it:
   - Right-click (or Control-click) `PressureMonitor.app` → **Open**
   - Click **Open** again in the dialog that appears
3. The barometer icon will appear in your menu bar

> **Requires macOS 14 or later.**

---

## Building from source

You need **Xcode 15 or later**.

```bash
git clone git@github.com:boboTjones/PressureMonitor.git
cd PressureMonitor
open PressureMonitor.xcodeproj
```

In Xcode:
1. Set the deployment target to **macOS 13.0** (General tab)
2. Confirm `PressureMonitor.entitlements` has `Outgoing Connections (Client)` set to YES
3. Press **⌘R** to build and run

Or from the terminal (still requires Xcode to be installed):

```bash
xcodebuild -project PressureMonitor.xcodeproj \
           -scheme PressureMonitor \
           -configuration Release \
           build
```

---

## Creating a shareable .app (for distributing to others)

1. In Xcode: **Product → Archive**
2. In the Organizer that opens: **Distribute App → Copy App**
3. Zip the exported `PressureMonitor.app` and share it

Recipients follow the "pre-built binary" steps above.

---

## First-time setup

Click the barometer icon in the menu bar → **gear icon → Settings**:

- **Location** — enter a US ZIP code, or switch to coordinates (lat/lon)
- **Alert threshold** — pressure level (inHg) below which you want a notification (default: 29.70)
- **Polling interval** — how often to fetch fresh data (default: 15 minutes)
- **Notifications** — toggle low-pressure alerts on/off

---

## Data source

Weather data is provided by [Open-Meteo](https://open-meteo.com) — free, no account or API key required.

| Rate limit | Cap |
|---|---|
| Per minute | 600 requests |
| Per hour | 5,000 requests |
| Per day | 10,000 requests |

At the default 15-minute polling interval the app uses ~96 requests/day.

---

## Privacy

No data leaves your machine except the coordinates/ZIP sent to Open-Meteo's public API. No account, no telemetry, no tracking.
