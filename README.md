# HRMS - Human Resource Management System

A production-ready, full-featured Human Resource Management System with Flutter mobile app and NestJS backend.

## Features

### For All Roles (Employee, Manager, HR Admin)
- **Work Mode Selection**: Choose between Office, Remote, or On-Duty mode after login
- **Attendance Tracking**: Real-time clock in/out with GPS location tracking
- **Leave Management**: Apply, view, and track leave requests
- **Profile Management**: View skills, performance metrics, and personal details
- **Notifications**: Real-time notifications for approvals, updates, and alerts
- **Employee Directory**: Search and view colleague profiles

### Role-Specific Features

**Employee Dashboard**
- Personal attendance timer with punch in/out
- Leave balance overview
- Salary information
- Request tracking (tickets, claims)
- Quick actions (Raise Ticket, Submit Claim)

**Manager Dashboard**
- Team overview and management
- Pending approvals (leave, expenses, shifts)
- Team attendance status
- Project and task management

**HR Admin Dashboard**
- Organization-wide overview
- Leave and expense approvals
- Department statistics
- Onboarding management
- Employee management

### Work Modes
- **Office**: Requires biometric + geofence verification + clock in/out
- **Remote**: Simple clock in/out (no location verification)
- **On-Duty (OD)**: GPS location captured on clock in/out with address

## Tech Stack

### Mobile App (Flutter)
- Flutter 3.16+
- Riverpod for state management
- GoRouter for navigation
- Dio for API calls
- Flutter Secure Storage for tokens
- Flutter Map for location features
- Local Auth for biometrics

### Backend (NestJS)
- NestJS with TypeScript
- Prisma ORM
- PostgreSQL database
- JWT authentication
- Passport.js for guards
- Class Validator for DTOs

## Project Structure

```
hrms-app/
├── mobile/                    # Flutter App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/              # Theme, constants, widgets
│   │   ├── features/          # Feature modules
│   │   │   ├── auth/          # Login, work mode selection
│   │   │   ├── home/          # Dashboards (Employee, Manager, HR)
│   │   │   ├── attendance/    # Clock in/out, history
│   │   │   ├── leave/         # Leave management
│   │   │   ├── directory/     # Employee directory
│   │   │   ├── profile/       # User profile
│   │   │   └── notifications/ # Notifications
│   │   ├── shared/            # Shared models, providers
│   │   └── routes/            # GoRouter configuration
│   └── pubspec.yaml
│
├── backend/                   # NestJS API
│   ├── src/
│   │   ├── main.ts
│   │   ├── app.module.ts
│   │   ├── common/            # Guards, decorators, filters
│   │   ├── modules/           # Feature modules
│   │   │   ├── auth/          # Authentication
│   │   │   ├── users/         # User management
│   │   │   ├── attendance/    # Attendance tracking
│   │   │   ├── leave/         # Leave management
│   │   │   ├── notifications/ # Notifications
│   │   │   ├── tickets/       # Support tickets
│   │   │   ├── claims/        # Expense claims
│   │   │   └── assets/        # Asset management
│   │   └── prisma/            # Prisma service
│   ├── prisma/
│   │   ├── schema.prisma      # Database schema
│   │   └── seed.ts            # Seed data
│   └── package.json
│
├── docker-compose.yml
└── README.md
```

## Quick Start

### Prerequisites
- Node.js 18+
- Flutter SDK 3.16+
- PostgreSQL (or use Prisma Accelerate cloud)
- Git

### 1. Clone the Repository
```bash
git clone https://github.com/HemanthKumar52/HRMS.git
cd HRMS
```

### 2. Backend Setup
```bash
cd backend

# Install dependencies
npm install

# Copy environment file and configure
cp .env.example .env
# Edit .env with your database URL and JWT secret

# Generate Prisma client
npx prisma generate

# Push schema to database (creates tables)
npx prisma db push

# Seed the database with test data
npx prisma db seed

# Start development server
npm run start:dev
```

The API will be available at `http://localhost:3000`

### 3. Mobile App Setup
```bash
cd mobile

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## Test Credentials

| Role | Email | Password |
|------|-------|----------|
| HR Admin | hr@acme.com | password123 |
| Manager | manager@acme.com | password123 |
| Employee | employee@acme.com | password123 |
| Additional Employees | alice@acme.com, bob@acme.com, etc. | password123 |

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | Login with email/password |
| POST | `/api/v1/auth/refresh` | Refresh access token |
| POST | `/api/v1/auth/logout` | Logout |
| GET | `/api/v1/auth/profile` | Get current user profile |

### Attendance
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/attendance/punch` | Clock in/out |
| GET | `/api/v1/attendance/today` | Get today's status |
| GET | `/api/v1/attendance/summary` | Get weekly/monthly summary |
| GET | `/api/v1/attendance/history` | Get attendance history |
| POST | `/api/v1/attendance/sync` | Sync offline punches |

### Leave Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/leave/apply` | Apply for leave |
| GET | `/api/v1/leave/balance` | Get leave balances |
| GET | `/api/v1/leave/history` | Get leave history |
| PATCH | `/api/v1/leave/:id/cancel` | Cancel pending leave |
| POST | `/api/v1/leave/:id/approve` | Approve leave (Manager) |
| POST | `/api/v1/leave/:id/reject` | Reject leave (Manager) |

### Users/Directory
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/users` | List employees |
| GET | `/api/v1/users/:id` | Get employee profile |
| GET | `/api/v1/users/:id/team` | Get direct reports |

### Notifications
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/notifications` | List notifications |
| PATCH | `/api/v1/notifications/:id/read` | Mark as read |

### Tickets & Claims
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/tickets` | Create support ticket |
| GET | `/api/v1/tickets` | List tickets |
| POST | `/api/v1/claims` | Submit expense claim |
| GET | `/api/v1/claims` | List claims |

## Environment Variables

### Backend (.env)
```env
NODE_ENV=development
DATABASE_URL=postgresql://user:password@localhost:5432/hrms
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
JWT_EXPIRATION=15m
JWT_REFRESH_EXPIRATION=7d
```

## Production Deployment

### Backend
1. Set `NODE_ENV=production`
2. Use a strong `JWT_SECRET` (min 32 characters)
3. Use managed PostgreSQL (AWS RDS, Supabase, Prisma Accelerate)
4. Enable HTTPS
5. Set up rate limiting
6. Configure CORS for your domain

### Mobile
1. Update API base URL in `lib/core/constants/api_constants.dart`
2. Configure signing keys for Android/iOS
3. Build release version:
   ```bash
   flutter build apk --release
   flutter build ios --release
   ```

## Database Schema

Key models:
- **User**: Employees with roles (EMPLOYEE, MANAGER, HR_ADMIN)
- **Organization**: Company/tenant
- **DailyAttendance**: Daily attendance summary
- **AttendanceActivity**: Individual punch records
- **Leave**: Leave requests
- **LeaveBalance**: Leave quota tracking
- **Ticket**: Support tickets
- **Claim**: Expense claims
- **Asset**: Company assets
- **Notification**: User notifications

## Screenshots

The app includes:
- Modern gradient dashboards
- Interactive attendance timer with pie chart
- Location map with geofencing
- Glass morphism profile sheet
- Animated transitions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

MIT License - feel free to use for personal and commercial projects.

---

Built with Flutter & NestJS
