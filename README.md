# Emirates Wash

UAE's smartest car wash finder — locate the nearest free or quickest car wash in real time.

---

## What's been built

### Onboarding flow
- **Splash screen** — animated logo (scale + fade, ~2s), auto-navigates to Login
- **Login screen** — UAE `+971` phone number input with OTP flow; "Continue as Guest" bypass for demo
- **OTP screen** — 6-box auto-advance input, 60s resend countdown, "Skip (Demo)" button for instant access

### Map screen (main experience)
- Full-screen interactive map centred on Dubai (zoom 11)
- 10 dummy car washes across Dubai
- Colour-coded bubble markers — **green** (free), **orange** (busy), **red** (full) — each showing live wait time
- Tap a marker → draggable detail sheet with name, status, wait time, cars in queue, rating, address, opening hours, phone, price range, and services
- **Fully draggable bottom sheet** — grab the handle and drag to four snap points: hidden sliver → partial (30%) → half-map (74%) → full-list (92%); drag all the way up to hide the map entirely
- **Filters are fully dynamic** — status chips, service filter, and sort all update both the bottom sheet list and the map markers simultaneously; filtered-out washes disappear from the map
- Status filter chips: **All / Free / Busy / Full** with animated count badge
- **Sort & Filter** — sort by distance / shortest wait / highest rating; multi-select service filter (Exterior Wash, Interior Clean, Full Detail, Polish, Tyre Shine, Engine Clean, Ceramic Coating)
- Empty state when no washes match active filters
- "My Location" FAB with real GPS (graceful fallback if denied)
- Language toggle **(EN ↔ AR)** in top bar — switches entire UI and swaps map tile provider

### Reserve & Pay (demo payment flow)
Users can reserve a slot directly from the detail sheet:

1. **Package selection** — Basic / Standard / Premium with AED pricing and what's included
2. **Time slot picker** — 30-minute slots from 7 AM to 10 PM
3. **Card entry** — card number (auto-spaced), expiry, CVV, cardholder name with live validation
4. **Booking confirmation** — animated checkmark + unique booking reference

Payment is a fully mocked demo flow (no real transaction).

### Queue detection (works without business sign-up)
Every wash has a `DetectionMethod`:

| Method | How it works |
|---|---|
| 📷 AI Camera | Queue counted automatically via computer vision |
| ✅ Business Verified | Business owner reports via the app |

---

## Tech stack

| Layer | Tech |
|---|---|
| Framework | **Flutter 3.x** (Dart 3) — iOS & Android |
| Maps | **flutter_map 6.x** (OpenStreetMap wrapper) |
| Map tiles (EN) | **Esri World Street Map** — English labels globally, no API key |
| Map tiles (AR) | **CartoDB Voyager** — Arabic/local labels in MENA, no API key |
| Coordinates | **latlong2** |
| GPS | **geolocator 11.x** |
| Localisation | Manual `AppLocalizations` delegate — English + Arabic (RTL auto-handled by Flutter) |
| State | `StatefulWidget` + `setState` (appropriate for demo scale) |
| Navigation | Custom `PageRouteBuilder` — fade and slide-up transitions |
| UI style | Google Maps–inspired: white, `#1A73E8` blue, Google status palette |

---

## Project structure

```
lib/
  main.dart                      ← App root, locale state
  models/car_wash.dart           ← CarWash, WashStatus, DetectionMethod
  data/dummy_data.dart           ← 10 Dubai car washes (dummy data)
  l10n/app_localizations.dart    ← EN + AR strings
  theme/app_theme.dart           ← Colours, ThemeData
  utils/distance.dart            ← Haversine formula
  utils/page_routes.dart         ← Fade + slide-up transitions
  screens/
    splash_screen.dart
    login_screen.dart
    otp_screen.dart
    home_screen.dart             ← Map, sort/filter, bottom sheet
    payment_screen.dart          ← Reserve & Pay flow (3 steps)
  widgets/
    wash_marker.dart             ← Map bubble markers
    wash_list_card.dart          ← Bottom sheet list item (shows price)
    wash_detail_sheet.dart       ← Draggable detail modal
    status_badge.dart            ← Free/Busy/Full pill
    detection_badge.dart         ← Detection method indicator
```

---

## Getting started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed and on your `PATH`

### First-time setup
```bash
# Scaffolds Android/iOS platform files, patches location permissions, runs pub get
bash setup.sh
```

### Run
```bash
flutter run
```

> **Demo mode:** On the login screen tap **Continue as Guest**, or on the OTP screen tap **Skip Verification (Demo)** to go straight to the map without a real phone number.

---

## Current status

This is a **Stage 1 demo** using dummy data. All car wash locations, queue lengths, wait times, and payments are simulated. Real-time data integration, live payments, user accounts, and business onboarding are planned for subsequent stages.
