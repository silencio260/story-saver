---
name: immersive-ui
description: Mandatory implementation pattern for premium edge-to-edge "borderless" Flutter UIs where the background flows into the status and navigation bar areas without dead zones
---

# Immersive Borderless UI Skill

## Overview
This skill defines the mandatory implementation pattern for achieving premium, edge-to-edge "borderless" user interfaces in Flutter, as required for the Note AI project. It ensures the application background flows into the status and navigation bar areas without intrusive "dead zones".

## Critical Rules

### 1. No Outer SafeArea
- **DO NOT** use `SafeArea` as a top-level wrapper for your `Scaffold` or main `body`. This creates "dark spots" and "dead zones" that break the immersive experience.
- Instead, allow the `Scaffold` background (usually `Colors.white`) to bleed into the system UI areas.

### 2. Manual Padding via MediaQuery
- To protect interactive content (like titles, buttons, or notches) from being obscured, use **manual padding** using `MediaQuery`:
    - **Header Padding**: `padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top)`
    - **Footer Padding**: `padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom)`
- This keeps the UI functional while the background remains 100% immersive.

### 3. AnnotatedRegion Control
- Always wrap the top-level screen in an **`AnnotatedRegion<SystemUiOverlayStyle>`**.
- This ensures the status bar and navigation bar are:
    - **Transparent**: `statusBarColor: Colors.transparent`, `systemNavigationBarColor: Colors.transparent`.
    - **No Scrim**: Set `systemNavigationBarContrastEnforced: false` and `systemStatusBarContrastEnforced: false` to remove the automatic grey bar on Android 10+.
    - **Themed correctly**: Use `statusBarIconBrightness: Brightness.dark` for white backgrounds to ensure system icons (Time, Battery) are visible.

### 4. Scaffold Configuration
- Always set **`extendBody: true`** in your `Scaffold`.
- This tells Flutter to allow the body content to flow behind the bottom navigation bar/system gesture area.

### 5. Preference for Dart-Only Fixes
- Prioritize Flutter/Dart solutions (like those above) for UI immersion.
- Avoid modified native Android/Kotlin code unless the Dart-only approach is technically impossible on a specific platform version.

## Usage Scenarios

### Scenario A: Immersive "Bleed-Through" (Primary Choice)
- **Applicable for**: All screens where the main background color (usually white) should reach the very edge of the physical screen (e.g., Home, Login, Profile).
- **Technique**: Set `extendBody: true`, remove the `SafeArea` wrapper, and use `MediaQuery.of(context).padding` for internal content padding.

### Scenario B: Content-Dense Scrolling
- **Applicable for**: Lists or long text areas that should scroll *behind* the status or navigation bars while they are transparent.
- **Technique**: Use `ListView.builder` with `padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top)`. This ensures the list doesn't start *under* the notch but allows content to scroll *through* it beautifully.

### Scenario C: Nested Interactive Elements
- **Applicable for**: Specific small widgets (like a "Close" button in a corner) that need to be "safe" without affecting the rest of the screen's layout.
- **Technique**: You may use a targeted `SafeArea` *inside* the widget hierarchy for that specific element only.

---

## Design Goal
The goal is a seamless, modern look where the app and the system UI feel like a single unit. Avoid Any alignment or padding that results in black/grey bars around the screen edges.
