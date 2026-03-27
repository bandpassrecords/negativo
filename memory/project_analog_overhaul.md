---
name: Analog Camera App Overhaul
description: Full overhaul of retro1 Flutter app into an analog camera film roll simulator
type: project
---

Completed full overhaul of the Flutter app from a "1 second per day" video app into an analog camera simulator called "Analog".

**Core concept:** Film rolls (12/24/36 frames), shoot without seeing photos, development takes real time (configurable 1-7 days), notification when ready, reveal all photos at once.

**Why:** User wanted a mindful photography experience that simulates real analog cameras — one roll per trip, think before you shoot.

**How to apply:** The app is now fully rewritten. All future work should build on the new models (FilmRoll, Exposure) and the new screen/service architecture.

**Architecture:**
- Models: FilmRoll (typeId:5), Exposure (typeId:6), AppSettings (typeId:1, extended)
- Services: HiveService, FilmService (business logic), NotificationService (development-complete only), MediaService (kept)
- Screens: HomeScreen, NewRollScreen, ViewfinderScreen (camera package), FilmRollDetailScreen, DevelopedGalleryScreen, SettingsScreen
- Color scheme: amber/golden (seed Color(0xFFB8860B))

**Status (as of 2026-03-27):** Code complete, zero compile errors, 2 cosmetic lint hints remaining (const Offset and FilledButton in viewfinder painter). Not yet tested on device.
