import { PrismaClient, Role, LeaveType, PunchType, WorkMode, LeaveStatus, TicketPriority, TicketStatus, ClaimType, ClaimStatus, User } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const org = await prisma.organization.upsert({
    where: { domain: 'acme.com' },
    update: {},
    create: {
      name: 'Acme Corporation',
      domain: 'acme.com',
    },
  });

  console.log('Created organization:', org.name);

  const passwordHash = await bcrypt.hash('password123', 10);

  // Create HR Admin
  const hrAdmin = await prisma.user.upsert({
    where: { email: 'hr@acme.com' },
    update: {},
    create: {
      email: 'hr@acme.com',
      passwordHash,
      firstName: 'Sarah',
      lastName: 'Williams',
      phone: '+1-555-0101',
      role: Role.HR_ADMIN,
      organizationId: org.id,
      department: 'Human Resources',
      designation: 'HR Manager',
    },
  });
  console.log('Created HR Admin:', hrAdmin.email);

  // Create Manager
  const manager = await prisma.user.upsert({
    where: { email: 'manager@acme.com' },
    update: {},
    create: {
      email: 'manager@acme.com',
      passwordHash,
      firstName: 'John',
      lastName: 'Smith',
      phone: '+1-555-0102',
      role: Role.MANAGER,
      organizationId: org.id,
      department: 'Engineering',
      designation: 'Engineering Manager',
    },
  });
  console.log('Created Manager:', manager.email);

  // Create Multiple Employees
  const employeeData = [
    { email: 'employee@acme.com', firstName: 'Jane', lastName: 'Doe', designation: 'Software Engineer', department: 'Engineering' },
    { email: 'alice@acme.com', firstName: 'Alice', lastName: 'Johnson', designation: 'Senior Developer', department: 'Engineering' },
    { email: 'bob@acme.com', firstName: 'Bob', lastName: 'Brown', designation: 'UI/UX Designer', department: 'Design' },
    { email: 'charlie@acme.com', firstName: 'Charlie', lastName: 'Davis', designation: 'QA Engineer', department: 'Quality Assurance' },
    { email: 'diana@acme.com', firstName: 'Diana', lastName: 'Miller', designation: 'DevOps Engineer', department: 'Engineering' },
    { email: 'evan@acme.com', firstName: 'Evan', lastName: 'Wilson', designation: 'Product Manager', department: 'Product' },
    { email: 'fiona@acme.com', firstName: 'Fiona', lastName: 'Taylor', designation: 'Data Analyst', department: 'Analytics' },
    { email: 'george@acme.com', firstName: 'George', lastName: 'Anderson', designation: 'Backend Developer', department: 'Engineering' },
  ];

  const employees: User[] = [];
  for (const emp of employeeData) {
    const employee: User = await prisma.user.upsert({
      where: { email: emp.email },
      update: {},
      create: {
        email: emp.email,
        passwordHash,
        firstName: emp.firstName,
        lastName: emp.lastName,
        phone: `+1-555-0${employees.length + 103}`,
        role: Role.EMPLOYEE,
        organizationId: org.id,
        managerId: manager.id,
        department: emp.department,
        designation: emp.designation,
      },
    });
    employees.push(employee);
    console.log('Created Employee:', employee.email);
  }

  const allUsers: User[] = [hrAdmin, manager, ...employees];

  // Create Leave Balances for all users
  const currentYear = new Date().getFullYear();
  const leaveTypes = [
    { type: LeaveType.CASUAL, days: 12 },
    { type: LeaveType.SICK, days: 10 },
    { type: LeaveType.EARNED, days: 15 },
  ];

  for (const user of allUsers) {
    for (const lt of leaveTypes) {
      await prisma.leaveBalance.upsert({
        where: {
          userId_leaveType_year: {
            userId: user.id,
            leaveType: lt.type,
            year: currentYear,
          },
        },
        update: {},
        create: {
          userId: user.id,
          leaveType: lt.type,
          totalDays: lt.days,
          usedDays: Math.floor(Math.random() * 3), // Random used days 0-2
          year: currentYear,
        },
      });
    }
  }
  console.log('Created leave balances for all users');

  // Create Attendance Records for last 7 days
  const today = new Date();
  for (const user of allUsers) {
    for (let i = 0; i < 7; i++) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      date.setHours(0, 0, 0, 0);

      // Skip weekends
      if (date.getDay() === 0 || date.getDay() === 6) continue;

      // Random clock in time between 8:30 and 9:30 AM
      const clockInHour = 8 + Math.floor(Math.random() * 2);
      const clockInMinute = Math.floor(Math.random() * 60);
      const clockInTime = new Date(date);
      clockInTime.setHours(clockInHour, clockInMinute, 0, 0);

      // Random clock out time between 5:00 and 7:00 PM
      const clockOutHour = 17 + Math.floor(Math.random() * 3);
      const clockOutMinute = Math.floor(Math.random() * 60);
      const clockOutTime = new Date(date);
      clockOutTime.setHours(clockOutHour, clockOutMinute, 0, 0);

      // Calculate total hours
      const diffMs = clockOutTime.getTime() - clockInTime.getTime();
      const totalMinutes = Math.floor(diffMs / (1000 * 60));
      const hours = Math.floor(totalMinutes / 60);
      const minutes = totalMinutes % 60;
      const totalHoursStr = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;

      // Create DailyAttendance
      const daily = await prisma.dailyAttendance.upsert({
        where: {
          userId_date: {
            userId: user.id,
            date: date,
          },
        },
        update: {
          clockInTime,
          clockOutTime,
          totalHours: totalHoursStr,
        },
        create: {
          userId: user.id,
          date: date,
          clockInTime,
          clockOutTime,
          totalHours: totalHoursStr,
          isValidated: true,
        },
      });

      // Create Clock In Activity
      await prisma.attendanceActivity.create({
        data: {
          userId: user.id,
          dailyAttendanceId: daily.id,
          punchType: PunchType.CLOCK_IN,
          workMode: WorkMode.OFFICE,
          timestamp: clockInTime,
          latitude: 12.9669 + Math.random() * 0.001,
          longitude: 80.2459 + Math.random() * 0.001,
        },
      });

      // Create Clock Out Activity
      await prisma.attendanceActivity.create({
        data: {
          userId: user.id,
          dailyAttendanceId: daily.id,
          punchType: PunchType.CLOCK_OUT,
          workMode: WorkMode.OFFICE,
          timestamp: clockOutTime,
          latitude: 12.9669 + Math.random() * 0.001,
          longitude: 80.2459 + Math.random() * 0.001,
        },
      });
    }
  }
  console.log('Created attendance records for last 7 days');

  // Create some Leave Requests
  const leaveReasons = ['Family vacation', 'Medical appointment', 'Personal work', 'Travel', 'Rest day'];
  for (let i = 0; i < 5; i++) {
    const randomEmployee = employees[Math.floor(Math.random() * employees.length)];
    const fromDate = new Date();
    fromDate.setDate(fromDate.getDate() + Math.floor(Math.random() * 30) + 1);
    const toDate = new Date(fromDate);
    toDate.setDate(toDate.getDate() + Math.floor(Math.random() * 3));

    await prisma.leave.create({
      data: {
        userId: randomEmployee.id,
        type: Object.values(LeaveType)[Math.floor(Math.random() * 3)] as LeaveType,
        status: i < 2 ? LeaveStatus.PENDING : LeaveStatus.APPROVED,
        fromDate,
        toDate,
        reason: leaveReasons[Math.floor(Math.random() * leaveReasons.length)],
        approvedBy: i >= 2 ? manager.id : null,
        approvedAt: i >= 2 ? new Date() : null,
      },
    });
  }
  console.log('Created sample leave requests');

  // Create Asset Categories
  const categories = [
    { name: 'Laptops', description: 'Portable computers', icon: 'laptop', colorCode: '#3B82F6' },
    { name: 'Monitors', description: 'Display screens', icon: 'monitor', colorCode: '#10B981' },
    { name: 'Accessories', description: 'Keyboards, mice, etc.', icon: 'keyboard', colorCode: '#8B5CF6' },
    { name: 'Phones', description: 'Mobile devices', icon: 'phone', colorCode: '#F59E0B' },
  ];

  const createdCategories = [];
  for (const cat of categories) {
    const category = await prisma.assetCategory.upsert({
      where: { name: cat.name },
      update: {},
      create: cat,
    });
    createdCategories.push(category);
  }
  console.log('Created asset categories');

  // Create some Assets
  const assets = [
    { name: 'MacBook Pro 14"', trackingId: 'ASSET-001', categoryIndex: 0, cost: 2499 },
    { name: 'Dell XPS 15', trackingId: 'ASSET-002', categoryIndex: 0, cost: 1899 },
    { name: 'LG UltraWide 34"', trackingId: 'ASSET-003', categoryIndex: 1, cost: 699 },
    { name: 'Logitech MX Keys', trackingId: 'ASSET-004', categoryIndex: 2, cost: 149 },
    { name: 'iPhone 15 Pro', trackingId: 'ASSET-005', categoryIndex: 3, cost: 999 },
  ];

  for (const asset of assets) {
    await prisma.asset.upsert({
      where: { trackingId: asset.trackingId },
      update: {},
      create: {
        assetName: asset.name,
        trackingId: asset.trackingId,
        purchaseDate: new Date(2024, 0, 15),
        purchaseCost: asset.cost,
        status: 'Available',
        categoryId: createdCategories[asset.categoryIndex].id,
      },
    });
  }
  console.log('Created sample assets');

  // Create Tickets
  const ticketSubjects = ['VPN not working', 'Email sync issue', 'Software installation request', 'Password reset'];
  for (let i = 0; i < 4; i++) {
    const randomEmployee = employees[Math.floor(Math.random() * employees.length)];
    await prisma.ticket.create({
      data: {
        userId: randomEmployee.id,
        subject: ticketSubjects[i],
        description: `Description for ${ticketSubjects[i]}. Need assistance.`,
        department: 'IT Support',
        priority: Object.values(TicketPriority)[Math.floor(Math.random() * 4)] as TicketPriority,
        status: i < 2 ? TicketStatus.OPEN : TicketStatus.RESOLVED,
      },
    });
  }
  console.log('Created sample tickets');

  // Create Claims
  const claimDescriptions = ['Travel reimbursement', 'Medical expense', 'Team lunch', 'Office supplies'];
  for (let i = 0; i < 4; i++) {
    const randomEmployee = employees[Math.floor(Math.random() * employees.length)];
    await prisma.claim.create({
      data: {
        userId: randomEmployee.id,
        type: Object.values(ClaimType)[Math.floor(Math.random() * 5)] as ClaimType,
        amount: Math.floor(Math.random() * 500) + 50,
        description: claimDescriptions[i],
        status: i < 2 ? ClaimStatus.PENDING : ClaimStatus.APPROVED,
      },
    });
  }
  console.log('Created sample claims');

  // Create Notifications
  const notificationTemplates = [
    { title: 'Welcome to HRMS', body: 'Welcome to the HRMS application. You can now manage your leaves and attendance.', type: 'SYSTEM' },
    { title: 'Leave Approved', body: 'Your leave request has been approved.', type: 'LEAVE' },
    { title: 'New Policy Update', body: 'Please review the updated HR policy.', type: 'POLICY' },
    { title: 'Payslip Available', body: 'Your payslip for this month is now available.', type: 'PAYROLL' },
  ];

  for (const user of allUsers) {
    for (const notif of notificationTemplates) {
      await prisma.notification.create({
        data: {
          userId: user.id,
          title: notif.title,
          body: notif.body,
          type: notif.type,
          isRead: Math.random() > 0.5,
        },
      });
    }
  }
  console.log('Created notifications for all users');

  console.log('\n--- Test Credentials ---');
  console.log('HR Admin: hr@acme.com / password123');
  console.log('Manager: manager@acme.com / password123');
  console.log('Employee: employee@acme.com / password123');
  console.log('(All other employees also use password123)');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
