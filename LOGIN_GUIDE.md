# Login Credentials Guide

This guide details the default login credentials available in the database (via `prisma/seed.ts`) and how the mobile app processes them.

## Backend Credentials (Database)
These users are created when you run `npx prisma db seed`.

| Role | Email | Password |
|---|---|---|
| **HR Admin** | `hr@acme.com` | `password123` |
| **Manager** | `manager@acme.com` | `password123` |
| **Employee** | `employee@acme.com` | `password123` |

## Mobile App "Mock" Login Logic
Currently, the mobile app uses a **simulated login** system for testing purposes (in `lib/features/auth/providers/auth_provider.dart`).

It assigns roles based on the email address you enter:

1.  **HR Dashboard**: Enter an email containing **"hr"** or **"admin"** (e.g., `hr@acme.com`, `admin@test.com`).
2.  **Manager Dashboard**: Enter an email containing **"manager"** (e.g., `manager@acme.com`).
3.  **Employee Dashboard**: Enter any other email (e.g., `employee@acme.com`, `john.doe@gmail.com`).

**Note:** The password field is currently ignored in the mobile app simulation, but should be filled out for realism.
