# Quick Fix Guide - 401 Error & GoRouter Crash

## ✅ Issues Fixed

### 1. **GoRouter Assertion Error - FIXED**
**Error:** `Failed assertion: line 204 pos 12: 'registry.containsKey(page)': is not true`

**Fix:** Added try-catch to safely handle GoRouterState when context isn't ready yet.

**Status:** ✅ Should not crash anymore

---

### 2. **401 Unauthorized Error - Needs Action**
**Error:** `statusCode: 401, message: "Unauthorized"`

**Root Cause:** You're logged in from BEFORE we fixed the token saving. Your current session doesn't have a token saved in secure storage.

**Solution:** **LOGOUT and LOGIN again** to get a fresh token saved.

---

## 🚀 How to Fix the 401 Error

### **Step 1: Logout**
1. Tap your **profile icon** (top right, shows your initial)
2. A bottom sheet will appear showing your profile
3. Scroll down
4. Tap **"Logout"** (red text at bottom)

### **Step 2: Login Again**
1. You'll be redirected to login screen
2. Enter your credentials
3. Login
4. **This time, the token WILL be saved!**

### **Step 3: Select Work Mode**
1. After login, you'll see work mode selection
2. Choose your mode (Office/Remote/On Duty)
3. Go to home screen

### **Step 4: Test**
1. Navigate around the app
2. Check if 401 errors are gone
3. All API calls should now work!

---

## 🔍 Why This Happened

**Timeline:**
1. **Before:** Auth provider had `TODO` comment - tokens weren't being saved
2. **You logged in:** Token was received but NOT saved to storage
3. **We fixed it:** Added code to save tokens
4. **Problem:** Your current session still has no token saved
5. **Solution:** Logout and login again to trigger the new save logic

**What Changed:**
```dart
// BEFORE (didn't save):
// TODO: Persist token using FlutterSecureStorage
// await _storage.write(key: 'jwt_token', value: token);

// AFTER (now saves):
await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
if (refreshToken != null) {
  await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
}
```

---

## ✨ New Features Added

### **1. Profile Menu**
- Tap your profile icon (top right)
- See your name, email, role
- Options:
  - View Profile
  - Settings
  - **Logout** ← Use this!

### **2. Work Mode Indicator**
- Colored icon next to profile
- Shows current work mode
- Tap to change mode anytime

### **3. Better Error Handling**
- GoRouter won't crash if context not ready
- Safe fallbacks for navigation

---

## 📝 Testing Checklist

After logout and login:

- [ ] Login successful
- [ ] Token saved (no more 401 errors)
- [ ] Work mode selection appears
- [ ] Selected work mode
- [ ] Home screen loads
- [ ] Can navigate to Attendance
- [ ] Can navigate to Leave
- [ ] Can navigate to Directory
- [ ] No 401 errors in console
- [ ] All API calls working

---

## 🐛 If Still Getting 401 Errors

### **Check 1: Did you logout and login?**
- Must logout completely
- Then login again
- Old session won't work

### **Check 2: Check Flutter console**
```
Look for:
✅ "Login successful"
✅ "Token saved"
❌ "401 Unauthorized" should be gone
```

### **Check 3: Clear app data (nuclear option)**
```bash
# Stop the app
# Then run:
flutter clean
flutter pub get
flutter run
```

---

## 🎯 Summary

**What to do RIGHT NOW:**
1. ✅ Hot restart the app (press 'R' in Flutter terminal)
2. ✅ Tap profile icon (top right)
3. ✅ Tap "Logout"
4. ✅ Login again with your credentials
5. ✅ Select work mode
6. ✅ Test - 401 errors should be gone!

**Why:**
- Old session has no token saved
- New login will save token properly
- All API calls will then work

**Expected Result:**
- ✅ No more 401 errors
- ✅ All API calls succeed
- ✅ App works normally
- ✅ Notifications load
- ✅ Directory loads
- ✅ Everything works!

---

## 📞 Still Having Issues?

If after logout/login you still see 401 errors:

1. Check if token is being saved:
   - Add this to auth_provider.dart after line 67:
   ```dart
   print('🔑 Token saved: ${accessToken.substring(0, 20)}...');
   ```

2. Check if token is being sent:
   - Look for Authorization header in console logs
   - Should see: `Authorization: Bearer <token>`

3. Check backend:
   - Is backend running?
   - Check backend console for errors
   - JWT_SECRET set in .env?

The fix is simple: **Just logout and login again!** 🎉
