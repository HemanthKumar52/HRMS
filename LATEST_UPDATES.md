# Features Implemented ✅

## 1. Ticket & Claim System (Full Stack) 🎫
- **Backend**: Implemented `Tickets` and `Claims` modules in NestJS with PostgreSQL database.
- **Database**: Added `Ticket` and `Claim` models to Prisma schema.
- **Frontend**: Connected `Raise Ticket` and `Submit Claim` screens to the new backend endpoints.
- **Status**: Fully functional. You can now submit tickets and claims, and they are saved to the database.

## 2. Attendance Improvements 📍
- **Simulate Location**: Added a button to teleport to the office location, enabling `Clock In/Out` testing on emulator.
- **Dynamic Attendance**: Replaced static mock data with real backend API calls. Clock In/Out now updates database in real-time.
- **Map Label**: Fixed map marker label to "Olympia Pinnacle".
- **Distance Indicator**: Shows distance to office to diagnose location issues.

## 3. Leave Management 📅
- **Filters**: Added "Requested", "Approved", "Expired", "History" filters to Leave Screen.
- **CRUD**: Verified Apply Leave and Cancel Leave functionality.
