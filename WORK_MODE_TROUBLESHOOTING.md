# Work Mode System - Updated Requirements

## ✅ Changes Made

### 1. **Removed FIELD_WORK Mode**
- Only 3 work modes now: **OFFICE**, **REMOTE**, **ON_DUTY**
- Updated schema, UI, and providers

### 2. **Updated Work Mode Requirements**

#### **OFFICE Mode** - ALL THREE REQUIRED
```
✅ Biometric Authentication (Fingerprint/Face ID)
AND
✅ Geofence Verification (must be within 200m of office)
AND
✅ Clock In/Out

ALL THREE must pass for attendance to be verified!
```

#### **REMOTE Mode** - Simple
```
✅ Clock In/Out only
❌ No location verification
❌ No biometric required
```

#### **ON_DUTY Mode** - GPS Tracking
```
✅ GPS Location (Latitude + Longitude) captured on Clock In
✅ GPS Location (Latitude + Longitude) captured on Clock Out
✅ Location name/address recorded (via reverse geocoding)
✅ Requires manager approval
```

---

## 🗺️ Location Not Updating - Troubleshooting

### **Check 1: Location Permissions**
The app needs location permissions to track your position.

**On Android:**
1. Go to **Settings** → **Apps** → **HRMS Mobile**
2. Tap **Permissions**
3. Tap **Location**
4. Select **"Allow all the time"** or **"Allow only while using the app"**

**In the app:**
- When you first open the Attendance screen, you should see a permission request
- Tap **"Allow"** or **"While using the app"**

### **Check 2: GPS/Location Services Enabled**
Make sure your device's GPS is turned on:
1. Swipe down from the top of the screen
2. Look for **Location** icon
3. Make sure it's **ON** (blue/green)

### **Check 3: You're Actually at Olympia Pinnacle**
The office location is set to:
- **Latitude**: 13.010236
- **Longitude**: 80.220626
- **Address**: Olympia Pinnacle, Chennai

**Geofence Radius**: 200 meters (about 650 feet)

You must be **within 200m** of this location for the geofence to pass.

### **Check 4: Wait for GPS Lock**
- GPS can take 10-30 seconds to get an accurate location
- Make sure you're near a window or outside
- Indoor GPS can be less accurate

### **Check 5: Restart the App**
- Close the app completely
- Reopen it
- Go to Attendance screen
- Wait for location to update (you'll see your position on the map)

---

## 📍 How to See Your Current Location

### **On the Attendance Screen:**
1. Open the app
2. Go to **Attendance** tab
3. You should see a **map** (unless you're in Remote mode)
4. Your current location appears as a **blue marker**
5. The office location appears as a **red marker**
6. A **blue circle** shows the 200m geofence

### **Location Status Indicator:**
At the top of the map, you'll see:
- **"Inside Geofence ✓"** - You're within 200m of office (green)
- **"Outside Geofence ✗"** - You're too far from office (red)
- **"Locating..."** - GPS is still finding your position (yellow)

---

## 🔐 Office Mode - How It Works

### **Step 1: Be at the Office**
- You must be **physically present** at Olympia Pinnacle
- Within **200 meters** of the office coordinates

### **Step 2: Check Geofence**
- Open Attendance screen
- Wait for GPS to lock (10-30 seconds)
- Map shows your location
- Status should say **"Inside Geofence ✓"**

### **Step 3: Biometric Authentication**
- Tap **"Clock In"** button
- Biometric prompt appears
- Use **fingerprint** or **face ID**
- Must pass biometric check

### **Step 4: Clock In**
- After biometric passes
- AND you're inside geofence
- Attendance is recorded

**All three must pass:**
1. ✅ Geofence (within 200m)
2. ✅ Biometric (fingerprint/face)
3. ✅ Clock In button pressed

If ANY ONE fails, attendance is NOT verified!

---

## 🏠 Remote Mode - How It Works

### **Simple Clock In/Out:**
1. Select **Remote** work mode
2. No map is shown (not needed)
3. Just tap **"Clock In"**
4. That's it! No other checks

**No verification needed:**
- ❌ No location check
- ❌ No biometric
- ✅ Just clock in/out

---

## 🚗 ON_DUTY Mode - How It Works

### **Clock In:**
1. When you arrive at your field location
2. Tap **"Clock In"**
3. App captures:
   - Your GPS coordinates (lat/long)
   - Your current address (via reverse geocoding)
   - Timestamp

### **Clock Out:**
1. When you finish your visit
2. Tap **"Clock Out"**
3. App captures:
   - Your GPS coordinates (lat/long)
   - Your current address (via reverse geocoding)
   - Timestamp

### **Manager Approval:**
- All ON_DUTY attendance requires manager approval
- Manager can see:
  - Where you clocked in (address + map)
  - Where you clocked out (address + map)
  - Total time spent
  - Distance traveled (if multiple locations)

---

## 🐛 Common Issues & Solutions

### **"Location permissions are permanently denied"**
**Solution:**
1. Go to device Settings
2. Apps → HRMS Mobile → Permissions
3. Enable Location permission
4. Restart the app

### **"Location services are disabled"**
**Solution:**
1. Swipe down from top
2. Turn on Location/GPS
3. Go back to app

### **"Outside Geofence" but I'm at the office**
**Possible causes:**
1. **GPS not accurate yet** - Wait 30 seconds
2. **Indoor location** - Move closer to window
3. **Wrong office coordinates** - Contact admin
4. **Geofence too small** - Contact admin to increase radius

### **Map not showing**
**Check:**
1. Are you in Remote mode? (Remote doesn't show map)
2. Is internet connected? (Map tiles need internet)
3. Restart the app

### **Biometric not working**
**Check:**
1. Is fingerprint/face ID set up on your device?
2. Go to device Settings → Security → Biometrics
3. Add fingerprint or face data
4. Try again in app

---

## 📊 What Gets Recorded

### **OFFICE Mode:**
```json
{
  "workMode": "OFFICE",
  "latitude": 13.010236,
  "longitude": 80.220626,
  "address": "Olympia Pinnacle, Chennai",
  "isInsideGeofence": true,
  "biometricVerified": true,
  "timestamp": "2026-02-09T10:30:00Z"
}
```

### **REMOTE Mode:**
```json
{
  "workMode": "REMOTE",
  "latitude": null,
  "longitude": null,
  "address": null,
  "timestamp": "2026-02-09T10:30:00Z"
}
```

### **ON_DUTY Mode:**
```json
{
  "workMode": "ON_DUTY",
  "clockIn": {
    "latitude": 13.012345,
    "longitude": 80.223456,
    "address": "Client Site A, Anna Nagar, Chennai",
    "timestamp": "2026-02-09T10:30:00Z"
  },
  "clockOut": {
    "latitude": 13.015678,
    "longitude": 80.226789,
    "address": "Client Site B, T Nagar, Chennai",
    "timestamp": "2026-02-09T15:30:00Z"
  },
  "requiresApproval": true
}
```

---

## 🔄 Next Steps

1. **Install geocoding package:**
   ```bash
   cd mobile
   flutter pub get
   ```

2. **Restart the app:**
   - Stop the current flutter run
   - Run `flutter run` again

3. **Test each mode:**
   - Login
   - Select OFFICE mode
   - Check if location updates on map
   - Try clock in (should require biometric + geofence)
   
4. **Check location permissions:**
   - Make sure location is enabled
   - Grant "Allow all the time" or "While using app"

5. **Be at the office:**
   - You must physically be at Olympia Pinnacle
   - Within 200m radius
   - GPS needs clear sky view (near window)

---

## 📞 Support

If location still not updating:
1. Check Android/iOS location permissions
2. Make sure GPS is ON
3. Wait 30 seconds for GPS lock
4. Restart the app
5. Check if you're actually at Olympia Pinnacle coordinates

The system is now configured correctly. The issue is likely permissions or GPS signal!
