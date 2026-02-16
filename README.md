

# HRMS Mobile Application

A comprehensive Human Resource Management System with a Flutter mobile app and NestJS backend.

## Project Structure

```
hrms-app/
├── mobile/                    # Flutter App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/              # Core utilities
│   │   ├── features/          # Feature-based modules
│   │   ├── shared/            # Shared widgets, models
│   │   └── routes/            # GoRouter configuration
│   └── pubspec.yaml
│
├── backend/                   # NestJS API
│   ├── src/
│   │   ├── main.ts
│   │   ├── app.module.ts
│   │   ├── common/            # Guards, decorators, filters
│   │   ├── modules/           # Feature modules
│   │   └── prisma/            # Prisma service
│   ├── prisma/
│   │   └── schema.prisma
│   └── package.json
│
├── docker-compose.yml
└── README.md
```

## Features (Sprint 1 MVP)

- **Authentication**: Email/password login with JWT tokens
- **Leave Management**: Apply, view, cancel, approve/reject leave requests
- **Attendance**: Clock in/out with GPS tracking, offline support
- **Employee Directory**: Search and view employee profiles
- **Notifications**: In-app and push notifications

## Prerequisites

- Docker and Docker Compose
- Flutter SDK (3.16+)
- Node.js (18+)

## Quick Start

### 1. Start Infrastructure

```bash
# Start PostgreSQL and Redis
docker-compose up -d postgres redis
```

### 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Generate Prisma client
npx prisma generate

# Run database migrations
npx prisma migrate dev

# Seed the database (optional)
npx prisma db seed

# Start development server
npm run start:dev
```

The API will be available at `http://localhost:3000`

### 3. Mobile App Setup

```bash
cd mobile

# Initialize Flutter project (REQUIRED - creates android/, ios/, etc.)
flutter create . --org com.hrms --project-name hrms_mobile

# Get dependencies
flutter pub get

# Run the app (choose your platform)
flutter run -d android
flutter run -d ios
flutter run -d windows
flutter run -d macos
flutter run -d linux
flutter run -d chrome
```

**Important**: See `mobile/SETUP.md` for platform-specific configuration (permissions, etc.)

## Test Credentials

| Role | Email | Password |
|------|-------|----------|
| HR Admin | hr@acme.com | password123 |
| Manager | manager@acme.com | password123 |
| Employee | employee@acme.com | password123 |

## API Documentation

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | Login with email/password |
| POST | `/api/v1/auth/refresh` | Refresh access token |
| POST | `/api/v1/auth/logout` | Logout and invalidate tokens |
| GET | `/api/v1/auth/me` | Get current user profile |

### Leave Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/leave/apply` | Apply for leave |
| GET | `/api/v1/leave/balance` | Get leave balances |
| GET | `/api/v1/leave/history` | Get leave history |
| PATCH | `/api/v1/leave/:id/cancel` | Cancel pending leave |
| POST | `/api/v1/leave/:id/approve` | Approve leave (Manager) |
| POST | `/api/v1/leave/:id/reject` | Reject leave (Manager) |

### Attendance

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/attendance/punch` | Clock in/out |
| GET | `/api/v1/attendance/today` | Get today's status |
| GET | `/api/v1/attendance/summary` | Get weekly/monthly summary |
| GET | `/api/v1/attendance/history` | Get attendance history |

### Employee Directory

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

## Environment Variables

### Backend

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | - |
| `REDIS_URL` | Redis connection string | - |
| `JWT_SECRET` | JWT signing secret | - |
| `JWT_REFRESH_SECRET` | Refresh token secret | - |
| `JWT_EXPIRATION` | Access token expiration | 15m |

## Testing

### Backend

```bash
cd backend
npm run test        # Unit tests
npm run test:e2e    # E2E tests
```

### Mobile

```bash
cd mobile
flutter test
```

## License

MIT
