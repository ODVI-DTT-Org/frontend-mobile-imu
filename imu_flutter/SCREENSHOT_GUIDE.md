# Google Play Store Screenshot Guide - IMU App

**App Name:** IMU - Itinerary Manager Uniformed
**Required:** At least 2 screenshots
**Recommended:** 5-8 screenshots
**Last Updated:** April 7, 2026

---

## 📱 Screenshot Requirements

### Technical Specifications
| Requirement | Value |
|-------------|--------|
| **Minimum Resolution** | 320px width × 1080px height |
| **Maximum Resolution** | 3840px width × 2160px height |
| **Aspect Ratio** | Must not exceed 16:9 |
| **File Format** | JPG or PNG (24-bit color) |
| **File Size** | Max 8MB per screenshot |

### Screen Types Required
- ✅ **Phone screenshots** (at least 2)
- ⚠️ **Tablet screenshots** (if you support tablets - optional)

---

## 🎯 Recommended Screenshots (8 Screens)

### Screenshot #1: Login Screen
**Purpose:** Show secure authentication

**What to Capture:**
- Login page with email/password fields
- Clean, professional appearance
- Show "IMU" branding clearly

**Composition Tips:**
- Center the login form
- Ensure text is readable
- No keyboard covering the form
- Show the app icon/logo if visible

**Filename:** `01-login-1080x1920.jpg` or `01-login-1080x1920.png`

---

### Screenshot #2: Home Dashboard
**Purpose:** Show main app navigation and quick actions

**What to Capture:**
- Home screen with 6-icon grid (Clients, Itinerary, My Day, Reports, Settings, Logout)
- Sync status indicator in top-right
- Bottom navigation visible
- Clean, uncluttered view

**Composition Tips:**
- Show all 6 icons clearly
- Ensure bottom navigation tabs are visible
- Show sync status indicator (green/yellow/red)
- No notification overlays or toasts

**Filename:** `02-home-dashboard-1080x1920.jpg` or `02-home-dashboard-1080x1920.png`

---

### Screenshot #3: Client List
**Purpose:** Show client management capabilities

**What to Capture:**
- Client list with search bar
- Sample client cards showing names and status
- Filter/Sort options visible
- Starred/favorite indicator

**Composition Tips:**
- Show 2-3 client cards with realistic data
- Ensure search bar is visible at top
- Show client status badges (Interested, Undecided, etc.)
- Clean, professional appearance

**Filename:** `03-client-list-1080x1920.jpg` or `03-client-list-1080x1920.png`

---

### Screenshot #4: Client Detail
**Purpose:** Show comprehensive client information

**What to Capture:**
- Client detail page with personal information
- Touchpoint history (7-step sequence)
- Contact information and addresses
- Action buttons (Create Touchpoint, Edit)

**Composition Tips:**
- Show a complete client profile
- Display touchpoint sequence (1-7)
- Show GPS location information
- Ensure all text is readable

**Filename:** `04-client-detail-1080x1920.jpg` or `04-client-detail-1080x1920.png`

---

### Screenshot #5: Touchpoint Creation
**Purpose:** Show touchpoint recording functionality

**What to Capture:**
- Touchpoint form with date, time, reason fields
- GPS location capture indicator
- Photo capture button
- Call/Visit type selector

**Composition Tips:**
- Show the simplified form (5 fields)
- Display GPS location indicator
- Show camera button for photo capture
- Ensure form fields are filled with realistic data

**Filename:** `05-touchpoint-form-1080x1920.jpg` or `05-touchpoint-form-1080x1920.png`

---

### Screenshot #6: Itinerary View
**Purpose:** Show daily schedule management

**What to Capture:**
- Itinerary list with date selector
- Scheduled visit cards
- Time slots and client names
- Visit status indicators

**Composition Tips:**
- Show multiple itinerary cards
- Display date/times clearly
- Show visit completion status
- Ensure scrolling view looks natural

**Filename:** `06-itinerary-view-1080x1920.jpg` or `06-itinerary-view-1080x1920.png`

---

### Screenshot #7: My Day Dashboard
**Purpose:** Show daily task management

**What to Capture:**
- Today's tasks summary
- Progress indicator
- Quick action buttons
- Sync status

**Composition Tips:**
- Show task completion progress
- Display quick actions prominently
- Ensure clean, modern UI
- Show positive progress (50-75% complete)

**Filename:** `07-my-day-1080x1920.jpg` or `07-my-day-1080x1920.png`

---

### Screenshot #8: Sync Status
**Purpose:** Show offline-first capabilities

**What to Capture:**
- Sync status indicator
- Pending changes count
- Offline functionality indicator
- Success message (synced)

**Composition Tips:**
- Show green "Synced" status
- Display pending count badge (0 or low number)
- Ensure status is clearly visible
- Show bottom navigation

**Filename:** `08-sync-status-1080x1920.jpg` or `08-sync-status-1080x1920.png`

---

## 📸 How to Capture Screenshots

### Method 1: Using Built-in Screenshot Tools
**Android Device:**
1. Navigate to the screen you want to capture
2. Press **Power + Volume Down** buttons simultaneously
3. Screenshot saved in Photos/Gallery
4. Transfer to computer for submission

**Android Emulator:**
1. Open Android Studio Emulator
2. Press **Ctrl + S** (Windows) or **Cmd + S** (Mac)
3. Screenshot saved in device gallery

### Method 2: Using Flutter DevTools
```bash
# Connect your device
flutter devices

# Run app
flutter run

# Take screenshot via DevTools
# Open Chrome: chrome://inspect
# Click "Screenshot" button
```

### Method 3: Using ADB Command Line
```bash
# List connected devices
adb devices

# Capture screenshot
adb shell screencap -p /sdcard/screenshot.png

# Pull screenshot to computer
adb pull /sdcard/screenshot.png ./screenshot.png
```

---

## 🎨 Screenshot Best Practices

### DO's ✅
- Use a clean device with no extra apps running
- Clear notification panel before capturing
- Use consistent device orientation (portrait)
- Ensure device time is realistic (not 11:11)
- Show realistic data (not "Test User", "Sample Client")
- Use high-quality PNG format for sharpness
- Ensure text is readable at small sizes
- Show app in normal state (no debug overlays)

### DON'Ts ❌
- Don't include status bar with low battery
- Don't show notification overlays
- Don't include keyboard on screen
- Don't show error messages or warnings
- Don't use blur effects or filters
- Don't include other apps in background
- Don't show developer/debug menus
- Don't include watermarks or time stamps

---

## 📐 Resolution Guide

### Recommended Resolutions
| Device | Resolution | Aspect Ratio |
|--------|------------|--------------|
| **Phone (Standard)** | 1080 × 1920 | 9:16 |
| **Phone (Large)** | 1440 × 2560 | 9:16 |
| **Phone (XL)** | 1080 × 2400 | 9:20 |

### How to Resize Screenshots
**Using Online Tools:**
- https://screenshot.guru/google-play (Recommended)
- https://www.photopea.com (Free Photoshop alternative)

**Using Command Line (ImageMagick):**
```bash
# Resize to 1080x1920
magick input.png -resize 1080x1920 -gravity center -background white -extent 1080x1920 output.png

# Batch resize all screenshots
magick mogrify -resize 1080x1920 -path ./resized *.png
```

---

## 🚀 Quick Capture Checklist

### Before Capturing
- [ ] App is in release mode (not debug mode)
- [ ] Device is connected to WiFi
- [ ] Notifications are cleared
- [ ] Status bar shows full battery
- [ ] Device time is realistic
- [ ] App has sample data loaded

### During Capture
- [ ] Orientation is portrait (not landscape)
- [ ] No keyboard visible
- [ ] No notification overlays
- [ ] No toast messages visible
- [ ] Clean, professional appearance

### After Capture
- [ ] Verify resolution (min 320x1080, max 3840x2160)
- [ ] Check aspect ratio (≤ 16:9)
- [ ] Ensure file size < 8MB
- [ ] Verify text is readable
- [ ] Check for any sensitive data in screenshot

---

## 📦 File Naming Convention

Use consistent naming for easy identification:
```
01-login-1080x1920.png
02-home-dashboard-1080x1920.png
03-client-list-1080x1920.png
04-client-detail-1080x1920.png
05-touchpoint-form-1080x1920.png
06-itinerary-view-1080x1920.png
07-my-day-1080x1920.png
08-sync-status-1080x1920.png
```

---

## 🎯 Final Review Before Upload

### Quality Check
- [ ] All screenshots are sharp and clear
- [ ] No pixelation or blur
- [ ] Consistent brightness and color
- [ ] Professional appearance
- [ ] Accurate representation of app features

### Content Check
- [ ] Shows actual app functionality
- [ ] Realistic sample data
- [ ] No placeholder text
- [ ] No test/debug information
- [ ] Reflects current app version

### Technical Check
- [ ] Meets resolution requirements
- [ ] Correct aspect ratio
- [ ] File format is JPG or PNG
- [ ] File size under 8MB
- [ ] At least 2 screenshots (recommended 5-8)

---

**Next Steps:**
1. Capture screenshots using your preferred method
2. Resize to 1080x1920 (or appropriate resolution)
3. Review for quality and accuracy
4. Upload to Google Play Console in Store Listing > Graphics

**Upload Location:** Google Play Console → All Apps → [Your App] → Setup → Store Listing → Graphics
