import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTimesheetTaskDto } from './dto/create-timesheet-task.dto';

@Injectable()
export class TimesheetService {
  private readonly logger = new Logger(TimesheetService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Parse an "HH:MM" string into total minutes.
   */
  private parseHoursToMinutes(hoursStr: string): number {
    const [h, m] = (hoursStr || '00:00').split(':').map(Number);
    return (h || 0) * 60 + (m || 0);
  }

  /**
   * Convert total minutes to "HH:MM" string.
   */
  private minutesToHoursStr(totalMinutes: number): string {
    const h = Math.floor(totalMinutes / 60);
    const m = Math.floor(totalMinutes % 60);
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
  }

  /**
   * Compute totalHours for a task by summing mon-sun hours.
   */
  private computeTaskTotalHours(data: Partial<CreateTimesheetTaskDto>): string {
    const days = [
      data.monHours,
      data.tueHours,
      data.wedHours,
      data.thuHours,
      data.friHours,
      data.satHours,
      data.sunHours,
    ];
    let totalMinutes = 0;
    for (const day of days) {
      totalMinutes += this.parseHoursToMinutes(day || '00:00');
    }
    return this.minutesToHoursStr(totalMinutes);
  }

  /**
   * Compute WFO and WFH hours from task rows.
   */
  private computeLocationHours(tasks: Array<{ workLocation?: string | null; totalHours: string }>) {
    let wfoMinutes = 0;
    let wfhMinutes = 0;
    for (const task of tasks) {
      const minutes = this.parseHoursToMinutes(task.totalHours);
      if (task.workLocation === 'WFO') {
        wfoMinutes += minutes;
      } else if (task.workLocation === 'WFH') {
        wfhMinutes += minutes;
      }
    }
    return {
      wfoHours: this.minutesToHoursStr(wfoMinutes),
      wfhHours: this.minutesToHoursStr(wfhMinutes),
    };
  }

  async getCurrentWeekTimesheet(userId: string) {
    // Calculate current week's Monday
    const now = new Date();
    const day = now.getDay();
    const diff = now.getDate() - day + (day === 0 ? -6 : 1);
    const monday = new Date(now);
    monday.setDate(diff);
    monday.setHours(0, 0, 0, 0);

    // Saturday = Monday + 5 days
    const saturday = new Date(monday);
    saturday.setDate(monday.getDate() + 5);
    saturday.setHours(23, 59, 59, 999);

    const weekStart = new Date(monday);
    const weekEnd = new Date(saturday);
    weekEnd.setHours(0, 0, 0, 0);

    // Upsert the timesheet for this week
    const timesheet = await this.prisma.timesheet.upsert({
      where: {
        userId_weekStart: {
          userId,
          weekStart,
        },
      },
      create: {
        userId,
        weekStart,
        weekEnd,
        status: 'DRAFT',
      },
      update: {},
      include: {
        entries: {
          orderBy: { date: 'asc' },
        },
        tasks: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    // Query DailyAttendance records for this user between weekStart and weekEnd
    const dailyAttendances = await this.prisma.dailyAttendance.findMany({
      where: {
        userId,
        date: {
          gte: weekStart,
          lte: weekEnd,
        },
      },
      orderBy: { date: 'asc' },
    });

    // For each day Mon-Sat (6 days), create or update TimesheetEntry with hours from DailyAttendance
    for (let i = 0; i < 6; i++) {
      const entryDate = new Date(monday);
      entryDate.setDate(monday.getDate() + i);
      entryDate.setHours(0, 0, 0, 0);

      const dailyRecord = dailyAttendances.find(
        (d) => d.date.toISOString().split('T')[0] === entryDate.toISOString().split('T')[0],
      );

      const hoursWorked = dailyRecord?.totalHours || '00:00';
      const clockIn = dailyRecord?.clockInTime || null;
      const clockOut = dailyRecord?.clockOutTime || null;

      await this.prisma.timesheetEntry.upsert({
        where: {
          timesheetId_date: {
            timesheetId: timesheet.id,
            date: entryDate,
          },
        },
        create: {
          timesheetId: timesheet.id,
          date: entryDate,
          hoursWorked,
          clockIn,
          clockOut,
        },
        update: {
          hoursWorked,
          clockIn,
          clockOut,
        },
      });
    }

    // Compute totalHours by summing all entries
    const updatedEntries = await this.prisma.timesheetEntry.findMany({
      where: { timesheetId: timesheet.id },
      orderBy: { date: 'asc' },
    });

    let totalMinutes = 0;
    for (const entry of updatedEntries) {
      totalMinutes += this.parseHoursToMinutes(entry.hoursWorked || '00:00');
    }

    const totalHoursStr = this.minutesToHoursStr(totalMinutes);

    // Update the timesheet with computed totalHours
    const updatedTimesheet = await this.prisma.timesheet.update({
      where: { id: timesheet.id },
      data: { totalHours: totalHoursStr },
      include: {
        entries: {
          orderBy: { date: 'asc' },
        },
        tasks: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    // Compute WFO/WFH hours from tasks
    const { wfoHours, wfhHours } = this.computeLocationHours(updatedTimesheet.tasks);

    return {
      ...updatedTimesheet,
      weekStart: weekStart.toISOString(),
      weekEnd: weekEnd.toISOString(),
      wfoHours,
      wfhHours,
    };
  }

  async submitTimesheet(userId: string, timesheetId: string) {
    const timesheet = await this.prisma.timesheet.findUnique({
      where: { id: timesheetId },
    });

    if (!timesheet) {
      throw new NotFoundException('Timesheet not found');
    }

    if (timesheet.userId !== userId) {
      throw new BadRequestException('You can only submit your own timesheet');
    }

    if (timesheet.status !== 'DRAFT') {
      throw new BadRequestException('Only DRAFT timesheets can be submitted');
    }

    const updated = await this.prisma.timesheet.update({
      where: { id: timesheetId },
      data: {
        status: 'SUBMITTED',
        submittedAt: new Date(),
      },
      include: {
        entries: {
          orderBy: { date: 'asc' },
        },
        tasks: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    const { wfoHours, wfhHours } = this.computeLocationHours(updated.tasks);

    return { ...updated, wfoHours, wfhHours };
  }

  @Cron('0 23 * * 6')
  async autoSubmitWeeklyTimesheets() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const result = await this.prisma.timesheet.updateMany({
      where: {
        status: 'DRAFT',
        weekEnd: {
          lte: today,
        },
      },
      data: {
        status: 'SUBMITTED',
        submittedAt: new Date(),
      },
    });

    this.logger.log(`Auto-submitted ${result.count} timesheet(s)`);
  }

  async getTimesheetHistory(userId: string, page = 1, limit = 10) {
    const skip = (page - 1) * limit;

    const [timesheets, total] = await Promise.all([
      this.prisma.timesheet.findMany({
        where: { userId },
        orderBy: { weekStart: 'desc' },
        skip,
        take: limit,
        include: {
          entries: {
            orderBy: { date: 'asc' },
          },
          tasks: {
            orderBy: { createdAt: 'asc' },
          },
        },
      }),
      this.prisma.timesheet.count({ where: { userId } }),
    ]);

    const timesheetsWithLocation = timesheets.map((ts) => {
      const { wfoHours, wfhHours } = this.computeLocationHours(ts.tasks);
      return { ...ts, wfoHours, wfhHours };
    });

    return {
      timesheets: timesheetsWithLocation,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getSubmittedTimesheets(page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [timesheets, total] = await Promise.all([
      this.prisma.timesheet.findMany({
        where: { status: 'SUBMITTED' },
        orderBy: { submittedAt: 'desc' },
        skip,
        take: limit,
        include: {
          user: {
            select: {
              firstName: true,
              lastName: true,
              email: true,
              department: true,
            },
          },
          entries: {
            orderBy: { date: 'asc' },
          },
          tasks: {
            orderBy: { createdAt: 'asc' },
          },
        },
      }),
      this.prisma.timesheet.count({ where: { status: 'SUBMITTED' } }),
    ]);

    const timesheetsWithLocation = timesheets.map((ts) => {
      const { wfoHours, wfhHours } = this.computeLocationHours(ts.tasks);
      return { ...ts, wfoHours, wfhHours };
    });

    return {
      timesheets: timesheetsWithLocation,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async approveTimesheet(timesheetId: string, approverId: string) {
    const timesheet = await this.prisma.timesheet.findUnique({
      where: { id: timesheetId },
    });

    if (!timesheet) {
      throw new NotFoundException('Timesheet not found');
    }

    const updated = await this.prisma.timesheet.update({
      where: { id: timesheetId },
      data: {
        status: 'APPROVED',
        approvedBy: approverId,
        approvedAt: new Date(),
      },
      include: {
        entries: {
          orderBy: { date: 'asc' },
        },
        tasks: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    const { wfoHours, wfhHours } = this.computeLocationHours(updated.tasks);

    return { ...updated, wfoHours, wfhHours };
  }

  // ─── TimesheetTask CRUD ───────────────────────────────────────────────

  async addTask(userId: string, timesheetId: string, data: CreateTimesheetTaskDto) {
    const timesheet = await this.prisma.timesheet.findUnique({
      where: { id: timesheetId },
    });

    if (!timesheet) {
      throw new NotFoundException('Timesheet not found');
    }

    if (timesheet.userId !== userId) {
      throw new BadRequestException('You can only add tasks to your own timesheet');
    }

    if (timesheet.status !== 'DRAFT') {
      throw new BadRequestException('Tasks can only be added to DRAFT timesheets');
    }

    const totalHours = this.computeTaskTotalHours(data);

    const task = await this.prisma.timesheetTask.create({
      data: {
        timesheetId,
        project: data.project,
        activity: data.activity,
        description: data.description,
        workLocation: data.workLocation,
        monHours: data.monHours || '00:00',
        tueHours: data.tueHours || '00:00',
        wedHours: data.wedHours || '00:00',
        thuHours: data.thuHours || '00:00',
        friHours: data.friHours || '00:00',
        satHours: data.satHours || '00:00',
        sunHours: data.sunHours || '00:00',
        totalHours,
      },
    });

    return task;
  }

  async updateTask(userId: string, taskId: string, data: Partial<CreateTimesheetTaskDto>) {
    const task = await this.prisma.timesheetTask.findUnique({
      where: { id: taskId },
      include: {
        timesheet: true,
      },
    });

    if (!task) {
      throw new NotFoundException('Task not found');
    }

    if (task.timesheet.userId !== userId) {
      throw new BadRequestException('You can only update your own tasks');
    }

    if (task.timesheet.status !== 'DRAFT') {
      throw new BadRequestException('Tasks can only be updated on DRAFT timesheets');
    }

    // Merge existing values with incoming updates for recomputing totalHours
    const merged = {
      monHours: data.monHours ?? task.monHours,
      tueHours: data.tueHours ?? task.tueHours,
      wedHours: data.wedHours ?? task.wedHours,
      thuHours: data.thuHours ?? task.thuHours,
      friHours: data.friHours ?? task.friHours,
      satHours: data.satHours ?? task.satHours,
      sunHours: data.sunHours ?? task.sunHours,
    };

    const totalHours = this.computeTaskTotalHours(merged);

    const updated = await this.prisma.timesheetTask.update({
      where: { id: taskId },
      data: {
        ...data,
        ...merged,
        totalHours,
      },
    });

    return updated;
  }

  async deleteTask(userId: string, taskId: string) {
    const task = await this.prisma.timesheetTask.findUnique({
      where: { id: taskId },
      include: {
        timesheet: true,
      },
    });

    if (!task) {
      throw new NotFoundException('Task not found');
    }

    if (task.timesheet.userId !== userId) {
      throw new BadRequestException('You can only delete your own tasks');
    }

    if (task.timesheet.status !== 'DRAFT') {
      throw new BadRequestException('Tasks can only be deleted from DRAFT timesheets');
    }

    await this.prisma.timesheetTask.delete({
      where: { id: taskId },
    });

    return { message: 'Task deleted successfully' };
  }

  async getTimesheetDetail(userId: string, timesheetId: string) {
    const timesheet = await this.prisma.timesheet.findUnique({
      where: { id: timesheetId },
      include: {
        entries: {
          orderBy: { date: 'asc' },
        },
        tasks: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!timesheet) {
      throw new NotFoundException('Timesheet not found');
    }

    if (timesheet.userId !== userId) {
      throw new BadRequestException('You can only view your own timesheets');
    }

    const { wfoHours, wfhHours } = this.computeLocationHours(timesheet.tasks);

    return {
      ...timesheet,
      wfoHours,
      wfhHours,
    };
  }
}
