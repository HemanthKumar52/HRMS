# RBAC Permissions & UI Functionality Guide

## 📋 Overview

This document outlines all the permissions and UI functionality for different user roles in the HRMS system.

---

## 👥 User Roles

### 1. **EMPLOYEE**
- Basic staff members
- Can manage their own attendance, leave, and profile
- Requests require approval from managers/HR

### 2. **MANAGER**
- Team leads and supervisors
- Can view and approve team requests
- Has all EMPLOYEE permissions plus team management

### 3. **HR_ADMIN**
- HR department staff
- Full access to all HR functions
- Can approve payroll, manage users, process payslips
- Has all MANAGER permissions plus organization-wide access

---

## 🎯 Attendance Permissions

### **EMPLOYEE**
| Action | Permission | UI Element | Approval Required |
|--------|-----------|------------|-------------------|
| Clock In/Out | ✅ `ATTENDANCE_MARK_OWN` | Clock In/Out buttons | ❌ No (auto-approved) |
| View own attendance | ✅ `ATTENDANCE_VIEW_OWN` | Attendance history | ❌ No |
| View team attendance | ❌ No | Hidden | N/A |
| Approve attendance | ❌ No | Hidden | N/A |

**UI Behavior:**
- ✅ Shows: Clock In/Out buttons, own attendance history, calendar view
- ❌ Hides: Team attendance, approval buttons, edit buttons
- 📍 Work Mode: Must select Office/Remote/On Duty
- ✅ Office Mode: Requires biometric + geofence + clock in (ALL THREE)
- ✅ Remote Mode: Just clock in/out
- ✅ On Duty Mode: GPS location captured on clock in/out

**Approval Flow:**
```
Employee clocks in → Automatically approved (no approval needed)
```

---

### **MANAGER**
| Action | Permission | UI Element | Approval Required |
|--------|-----------|------------|-------------------|
| Clock In/Out | ✅ `ATTENDANCE_MARK_OWN` | Clock In/Out buttons | ❌ No |
| View own attendance | ✅ `ATTENDANCE_VIEW_OWN` | Own history | ❌ No |
| View team attendance | ✅ `ATTENDANCE_VIEW_TEAM` | Team attendance tab | ❌ No |
| Approve team attendance | ✅ `ATTENDANCE_APPROVE_TEAM` | Approve buttons | N/A |
| View all attendance | ❌ No | Hidden | N/A |

**UI Behavior:**
- ✅ Shows: All EMPLOYEE features + Team attendance tab + Approve buttons
- ❌ Hides: Organization-wide attendance (only HR can see)
- 📊 Dashboard: Shows team attendance summary

**Approval Flow:**
```
Team member clocks in → Auto-approved
Manager can view team attendance → Can mark as verified if needed
```

---

### **HR_ADMIN**
| Action | Permission | UI Element | Approval Required |
|--------|-----------|------------|-------------------|
| View all attendance | ✅ `ATTENDANCE_VIEW_ALL` | All attendance tab | ❌ No |
| Edit any attendance | ✅ `ATTENDANCE_EDIT_ALL` | Edit buttons | N/A |
| Delete attendance | ✅ `ATTENDANCE_DELETE` | Delete buttons | N/A |
| Export reports | ✅ `ATTENDANCE_EXPORT` | Export button | ❌ No |

**UI Behavior:**
- ✅ Shows: ALL features + Organization-wide view + Edit/Delete buttons + Export
- 📊 Dashboard: Full attendance analytics
- 📈 Reports: Can generate attendance reports

---

## 🏖️ Leave Permissions

### **EMPLOYEE**
| Action | Permission | UI Element | Approval Required |
|--------|-----------|------------|-------------------|
| Apply for leave | ✅ `LEAVE_APPLY` | Apply Leave button | ✅ YES (Manager/HR) |
| View own leave | ✅ `LEAVE_VIEW_OWN` | My Leaves tab | ❌ No |
| Cancel own leave | ✅ `LEAVE_CANCEL_OWN` | Cancel button | ✅ YES (if approved) |
| View team leave | ❌ No | Hidden | N/A |
| Approve leave | ❌ No | Hidden | N/A |

**UI Behavior:**
- ✅ Shows: Apply Leave button, own leave history, leave balance, calendar
- ❌ Hides: Team leave, approval buttons, other employees' leave
- 📅 Calendar: Shows only own leave

**Approval Flow:**
```
Employee applies for leave
  ↓
Sent to Manager for approval
  ↓
Manager approves/rejects
  ↓
If approved → Sent to HR for final approval (optional based on company policy)
  ↓
HR approves → Leave confirmed
```

**UI States:**
- 🟡 **Pending**: Yellow badge, "Waiting for approval"
- ✅ **Approved**: Green badge, "Approved by Manager/HR"
- ❌ **Rejected**: Red badge, "Rejected - [reason]"
- 🔵 **Cancelled**: Grey badge, "Cancelled"

---

### **MANAGER**
| Action | Permission | UI Element | Approval Required |
|--------|-----------|------------|-------------------|
| Apply for leave | ✅ `LEAVE_APPLY` | Apply Leave button | ✅ YES (HR) |
| View team leave | ✅ `LEAVE_VIEW_TEAM` | Team Leaves tab | ❌ No |
| Approve team leave | ✅ `LEAVE_APPROVE_TEAM` | Approve/Reject buttons | N/A |
| View all leave | ❌ No | Hidden | N/A |

**UI Behavior:**
- ✅ Shows: All EMPLOYEE features + Team Leaves tab + Approve/Reject buttons
- 📊 Dashboard: Team leave calendar, pending approvals count
- 🔔 Notifications: Alert when team member applies for leave

**Approval Flow:**
```
Team member applies for leave
  ↓
Manager receives notification
  ↓
Manager reviews and approves/rejects
  ↓
If approved → Optionally sent to HR for final approval
  ↓
Employee notified of decision
```

---

### **HR_ADMIN**
| Action | Permission | UI Element | Approval Required |
|--------|-----------|------------|-------------------|
| View all leave | ✅ `LEAVE_VIEW_ALL` | All Leaves tab | ❌ No |
| Approve any leave | ✅ `LEAVE_APPROVE_ALL` | Approve/Reject buttons | N/A |
| Edit leave balance | ✅ `LEAVE_EDIT_BALANCE` | Edit Balance button | ❌ No |
| Configure leave types | ✅ `LEAVE_CONFIGURE` | Settings | ❌ No |

**UI Behavior:**
- ✅ Shows: ALL features + Organization-wide leave view + Edit balance + Configure leave types
- 📊 Dashboard: Full leave analytics, leave balance summary
- 📈 Reports: Can generate leave reports

**Approval Flow:**
```
HR can approve any leave directly (final authority)
HR can edit leave balances
HR can configure leave policies
```

---

## 💰 Payroll Permissions

### **EMPLOYEE**
| Action | Permission | UI Element | Approval Required |
|--------|-----------|------------|-------------------|
| View own payslip | ✅ `PAYROLL_VIEW_OWN` | My Payslips tab | ❌ No |
| Download payslip | ✅ `PAYROLL_DOWNLOAD_OWN` | Download button | ❌ No |
| View salary details | ✅ `PAYROLL_VIEW_OWN` | Salary breakdown | ❌ No |
| View payroll | ❌ No | Hidden | N/A |

**UI Behavior:**
- ✅ Shows: Own payslips, download button, salary breakdown, tax details
- ❌ Hides: Other employees' payslips, payroll processing
- 📄 Payslip: PDF format, downloadable

**Features:**
- View monthly payslips
- Download payslips as PDF
- See salary breakdown (basic, allowances, deductions)
- View tax deductions (TDS, PF, ESI)
- Year-to-date summary

---

### **MANAGER**
| Action | Permission | UI Element | Approval Required |
|--------|-----------|------------|-------------------|
| View own payslip | ✅ `PAYROLL_VIEW_OWN` | My Payslips tab | ❌ No |
| View team payroll (summary) | ⚠️ Limited | Team summary (no details) | ❌ No |
| Approve claims | ✅ `CLAIMS_APPROVE_TEAM` | Approve button | N/A |

**UI Behavior:**
- ✅ Shows: Own payslips + Team payroll summary (total cost, not individual salaries)
- ❌ Hides: Individual team member salaries (privacy)
- 📊 Dashboard: Team payroll cost summary

**Note:** Managers typically don't see individual salaries for privacy reasons.

---

### **HR_ADMIN**
| Action | Permission | UI Element | Approval Required |
|--------|-----------|------------|-------------------|
| View all payroll | ✅ `PAYROLL_VIEW_ALL` | All Payroll tab | ❌ No |
| Process payroll | ✅ `PAYROLL_PROCESS` | Process Payroll button | ✅ YES (requires confirmation) |
| Generate payslips | ✅ `PAYROLL_GENERATE_PAYSLIPS` | Generate button | ❌ No |
| Edit salary | ✅ `PAYROLL_EDIT` | Edit Salary button | ✅ YES (audit trail) |
| Approve payroll | ✅ `PAYROLL_APPROVE` | Approve button | N/A |

**UI Behavior:**
- ✅ Shows: ALL payroll features + Process payroll + Generate payslips + Edit salary
- 📊 Dashboard: Full payroll analytics, pending payroll, total cost
- 📈 Reports: Can generate payroll reports, tax reports

**Payroll Processing Flow:**
```
HR prepares payroll for the month
  ↓
Reviews attendance, leaves, claims
  ↓
Calculates salaries (basic + allowances - deductions)
  ↓
Generates payslips for all employees
  ↓
Approves payroll (requires confirmation)
  ↓
Payslips available for employees to download
  ↓
Audit trail created
```

**Features:**
- Process monthly payroll
- Generate payslips in bulk
- Edit individual salaries
- Manage salary components (basic, HRA, DA, etc.)
- Configure tax slabs
- Export payroll data
- Audit trail for all changes

---

## 📄 Claims & Reimbursements

### **EMPLOYEE**
| Action | Permission | UI Element | Approval Required |
|--------|-----------|------------|-------------------|
| Submit claim | ✅ `CLAIMS_SUBMIT` | Submit Claim button | ✅ YES (Manager → HR) |
| View own claims | ✅ `CLAIMS_VIEW_OWN` | My Claims tab | ❌ No |
| Cancel claim | ✅ `CLAIMS_CANCEL_OWN` | Cancel button | ✅ YES (if approved) |

**Claim Types:**
- Travel reimbursement
- Medical expenses
- Food allowance
- Mobile/Internet
- Other expenses

**Approval Flow:**
```
Employee submits claim with receipts
  ↓
Manager reviews and approves/rejects
  ↓
If approved → Sent to HR
  ↓
HR verifies and approves
  ↓
Finance processes payment
  ↓
Amount added to next payslip
```

---

### **MANAGER**
| Action | Permission | UI Element | Approval Required |
|--------|-----------|------------|-------------------|
| View team claims | ✅ `CLAIMS_VIEW_TEAM` | Team Claims tab | ❌ No |
| Approve team claims | ✅ `CLAIMS_APPROVE_TEAM` | Approve/Reject buttons | N/A |

---

### **HR_ADMIN**
| Action | Permission | UI Element | Approval Required |
|--------|-----------|------------|-------------------|
| View all claims | ✅ `CLAIMS_VIEW_ALL` | All Claims tab | ❌ No |
| Approve any claim | ✅ `CLAIMS_APPROVE_ALL` | Approve button | N/A |
| Process payment | ✅ `CLAIMS_PROCESS_PAYMENT` | Process Payment button | ✅ YES |

---

## 👤 User Management

### **EMPLOYEE**
- ❌ Cannot create/edit/delete users
- ✅ Can edit own profile
- ✅ Can view directory

### **MANAGER**
- ❌ Cannot create/edit/delete users
- ✅ Can view team profiles
- ✅ Can view directory

### **HR_ADMIN**
- ✅ Can create new users
- ✅ Can edit any user
- ✅ Can delete users
- ✅ Can assign roles
- ✅ Can manage departments
- ✅ Can manage designations

---

## 🔔 Notifications

### **All Roles**
- ✅ View own notifications
- ✅ Mark as read
- ✅ Delete notifications

### **MANAGER**
- ✅ Send notifications to team

### **HR_ADMIN**
- ✅ Send organization-wide notifications
- ✅ Send targeted notifications

---

## 📊 Summary Table

| Feature | EMPLOYEE | MANAGER | HR_ADMIN |
|---------|----------|---------|----------|
| **Attendance** |
| Clock In/Out | ✅ Own | ✅ Own | ✅ Own |
| View | ✅ Own | ✅ Team | ✅ All |
| Approve | ❌ | ✅ Team | ✅ All |
| Edit | ❌ | ❌ | ✅ All |
| **Leave** |
| Apply | ✅ Own | ✅ Own | ✅ Own |
| View | ✅ Own | ✅ Team | ✅ All |
| Approve | ❌ | ✅ Team | ✅ All |
| Edit Balance | ❌ | ❌ | ✅ All |
| **Payroll** |
| View Payslip | ✅ Own | ✅ Own | ✅ All |
| Download | ✅ Own | ✅ Own | ✅ All |
| Process | ❌ | ❌ | ✅ Yes |
| Edit Salary | ❌ | ❌ | ✅ Yes |
| **Claims** |
| Submit | ✅ Yes | ✅ Yes | ✅ Yes |
| Approve | ❌ | ✅ Team | ✅ All |
| Process Payment | ❌ | ❌ | ✅ Yes |
| **Users** |
| Create | ❌ | ❌ | ✅ Yes |
| Edit | ✅ Own | ✅ Own | ✅ All |
| Delete | ❌ | ❌ | ✅ Yes |
| Assign Roles | ❌ | ❌ | ✅ Yes |

---

## 🎨 UI Implementation Status

### ✅ **Implemented**
1. Work mode selection (Office/Remote/On Duty)
2. Attendance screen with work mode adaptation
3. Geofencing for office mode
4. Biometric authentication
5. RBAC permission system (frontend + backend)
6. Permission guards and buttons
7. Dynamic Island notifications
8. Profile menu with logout

### 🚧 **To Be Implemented**
1. Leave approval UI for managers
2. Payroll processing UI for HR
3. Payslip generation and download
4. Claims submission and approval
5. User management UI
6. Attendance approval workflow
7. Leave balance management
8. Salary editing UI

---

## 🔄 Next Steps to Complete RBAC UI

### **1. Leave Management**
```dart
// Apply leave screen - already exists
// Need to add:
- Manager approval screen
- HR final approval screen
- Leave status tracking
- Notifications for approvals
```

### **2. Payroll Management**
```dart
// Need to create:
- Payslip viewer (PDF)
- Payslip download button
- HR payroll processing screen
- Salary editing form
- Payroll approval workflow
```

### **3. Claims Management**
```dart
// Need to create:
- Submit claim form
- Upload receipt
- Manager approval screen
- HR approval screen
- Payment processing
```

### **4. User Management**
```dart
// Need to create:
- Create user form (HR only)
- Edit user form
- Role assignment dropdown
- Department management
```

---

## 📝 Testing Checklist

### **EMPLOYEE Role**
- [ ] Can clock in/out based on work mode
- [ ] Can apply for leave
- [ ] Can view own payslips
- [ ] Can download payslips
- [ ] Can submit claims
- [ ] Cannot see team data
- [ ] Cannot approve anything
- [ ] Cannot edit other users

### **MANAGER Role**
- [ ] Can do everything EMPLOYEE can
- [ ] Can view team attendance
- [ ] Can approve team leave
- [ ] Can approve team claims
- [ ] Cannot see organization-wide data
- [ ] Cannot process payroll
- [ ] Cannot create users

### **HR_ADMIN Role**
- [ ] Can do everything MANAGER can
- [ ] Can view all attendance
- [ ] Can approve any leave
- [ ] Can process payroll
- [ ] Can generate payslips
- [ ] Can edit salaries
- [ ] Can create/edit/delete users
- [ ] Can assign roles

---

This document serves as the complete specification for RBAC permissions and UI functionality. Use it as a reference when implementing new features!
