import { Injectable, BadRequestException } from '@nestjs/common';
import { PunchType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { PunchDto } from './dto/punch.dto';
import { AttendanceHistoryDto } from './dto/attendance-history.dto';
import { AttendanceSummaryDto } from './dto/attendance-summary.dto';

@Injectable()
export class AttendanceService {
  constructor(private prisma: PrismaService) { }

  async punch(userId: string, dto: PunchDto) {
    const punchTime = dto.timestamp ? new Date(dto.timestamp) : new Date();
    const dateOnly = new Date(punchTime);
    dateOnly.setHours(0, 0, 0, 0);

    // 1. Get today's DailyAttendance or create it
    let daily = await this.prisma.dailyAttendance.findUnique({
      where: {
        userId_date: {
          userId,
          date: dateOnly,
        },
      },
    });

    if (!daily) {
      daily = await this.prisma.dailyAttendance.create({
        data: {
          userId,
          date: dateOnly,
          clockInTime: dto.punchType === PunchType.CLOCK_IN ? punchTime : null,
        },
      });
    }

    // 2. Validate Punch Sequence (Simple check against last activity)
    const lastActivity = await this.prisma.attendanceActivity.findFirst({
      where: { userId },
      orderBy: { timestamp: 'desc' },
    });

    const expectedPunchType =
      lastActivity?.punchType === PunchType.CLOCK_IN
        ? PunchType.CLOCK_OUT
        : PunchType.CLOCK_IN;

    if (dto.punchType && dto.punchType !== expectedPunchType) {
      // In a real app, strict validation might block this. 
      // For now, we allow it but log a warning or just proceed if user insists.
      // throw new BadRequestException(`Expected punch type: ${expectedPunchType}`);
    }

    // 3. Create Activity
    const activity = await this.prisma.attendanceActivity.create({
      data: {
        userId,
        dailyAttendanceId: daily.id,
        punchType: dto.punchType || expectedPunchType,
        latitude: dto.latitude,
        longitude: dto.longitude,
        address: dto.address,
        deviceId: dto.deviceId,
        isOffline: dto.isOffline || false,
        timestamp: punchTime,
        syncedAt: dto.isOffline ? new Date() : null,
      },
    });

    // 4. Update Daily Attendance (First In - Last Out Logic per user request)
    // We re-query activities for this day
    const dayActivities = await this.prisma.attendanceActivity.findMany({
      where: { dailyAttendanceId: daily.id },
      orderBy: { timestamp: 'asc' },
    });

    if (dayActivities.length > 0) {
      // User Logic: "One time clock in clock out... once they enter and once they leave... don't consider breaks"
      // Interpretation: Total Duration = Latest Last Out - Earliest First In.

      const firstIn = dayActivities.find(a => a.punchType === PunchType.CLOCK_IN);
      const lastOut = [...dayActivities].reverse().find(a => a.punchType === PunchType.CLOCK_OUT);

      let totalMinutes = 0;

      if (firstIn && lastOut) {
        if (lastOut.timestamp > firstIn.timestamp) {
          const diff = lastOut.timestamp.getTime() - firstIn.timestamp.getTime();
          totalMinutes = diff / (1000 * 60);
        }
      }

      const hours = Math.floor(totalMinutes / 60);
      const minutes = Math.floor(totalMinutes % 60);
      const totalHoursStr = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;

      await this.prisma.dailyAttendance.update({
        where: { id: daily.id },
        data: {
          clockInTime: firstIn?.timestamp || daily.clockInTime,
          clockOutTime: lastOut?.timestamp,
          totalHours: totalHoursStr,
        },
      });
    }

    return {
      activity,
      nextExpectedPunchType:
        activity.punchType === PunchType.CLOCK_IN
          ? PunchType.CLOCK_OUT
          : PunchType.CLOCK_IN,
    };
  }

  async getTodayStatus(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const daily = await this.prisma.dailyAttendance.findUnique({
      where: {
        userId_date: {
          userId,
          date: today,
        },
      },
      include: {
        activities: {
          orderBy: { timestamp: 'asc' },
        },
      },
    });

    if (!daily) {
      return {
        date: today.toISOString().split('T')[0],
        clockInTime: null,
        clockOutTime: null,
        totalHours: '0h 0m',
        totalMinutes: 0,
        punches: [],
        isClockedIn: false,
        nextExpectedPunchType: PunchType.CLOCK_IN,
      };
    }

    const isClockedIn = daily.activities.length > 0 &&
      daily.activities[daily.activities.length - 1].punchType === PunchType.CLOCK_IN;

    // Parse totalHours string "HH:MM" to "Xh Ym" for frontend compatibility if needed, 
    // or keep generic. The mock used "0h 0m".
    // "00:08" -> "0h 8m"
    const [h, m] = (daily.totalHours || "00:00").split(':').map(Number);
    const formattedHours = `${h}h ${m}m`;

    return {
      date: today.toISOString().split('T')[0],
      clockInTime: daily.clockInTime,
      clockOutTime: daily.clockOutTime,
      totalHours: formattedHours,
      totalMinutes: (h * 60) + m,
      punches: daily.activities,
      isClockedIn,
      nextExpectedPunchType: isClockedIn ? PunchType.CLOCK_OUT : PunchType.CLOCK_IN,
    };
  }

  async getSummary(userId: string, dto: AttendanceSummaryDto) {
    const { period = 'week' } = dto;
    const endDate = new Date();
    const startDate = new Date();

    if (period === 'week') startDate.setDate(startDate.getDate() - 7);
    else startDate.setDate(1); // Month start

    const dailies = await this.prisma.dailyAttendance.findMany({
      where: {
        userId,
        date: { gte: startDate, lte: endDate },
      },
      orderBy: { date: 'desc' },
    });

    let grandTotalMinutes = 0;

    const summary = dailies.map(d => {
      const [h, m] = (d.totalHours || "00:00").split(':').map(Number);
      const totalMins = (h * 60) + m;
      grandTotalMinutes += totalMins;

      return {
        date: d.date.toISOString().split('T')[0],
        clockIn: d.clockInTime,
        clockOut: d.clockOutTime,
        totalHours: `${h}h ${m}m`,
        totalMinutes: totalMins,
      };
    });

    const workingDays = dailies.length;
    const averageMinutes = workingDays > 0 ? grandTotalMinutes / workingDays : 0;

    return {
      period,
      startDate: startDate.toISOString().split('T')[0],
      endDate: endDate.toISOString().split('T')[0],
      totalHours: `${Math.floor(grandTotalMinutes / 60)}h ${Math.floor(grandTotalMinutes % 60)}m`,
      totalMinutes: grandTotalMinutes,
      averageHoursPerDay: `${Math.floor(averageMinutes / 60)}h ${Math.floor(averageMinutes % 60)}m`,
      workingDays,
      dailySummary: summary,
    };
  }

  async getHistory(userId: string, dto: AttendanceHistoryDto) {
    const { startDate, endDate, page = 1, limit = 20 } = dto;
    const skip = (page - 1) * limit;

    const where: any = { userId };
    if (startDate) where.timestamp = { gte: new Date(startDate) }; // Note: logic change, query activities is easier for history list

    // Actually, history usually implies List of Punches.
    // Let's query AttendanceActivity
    if (startDate || endDate) {
      where.timestamp = {};
      if (startDate) where.timestamp.gte = new Date(startDate);
      if (endDate) {
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);
        where.timestamp.lte = end;
      }
    }

    const [punches, total] = await Promise.all([
      this.prisma.attendanceActivity.findMany({
        where,
        skip,
        take: limit,
        orderBy: { timestamp: 'desc' },
      }),
      this.prisma.attendanceActivity.count({ where }),
    ]);

    return {
      punches,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async syncOfflinePunches(userId: string, punches: PunchDto[]) {
    const results = [];
    for (const punch of punches) {
      try {
        const result = await this.punch(userId, { ...punch, isOffline: true });
        results.push({ success: true, data: result });
      } catch (error) {
        results.push({
          success: false,
          error: error instanceof Error ? error.message : 'Unknown error',
          punch,
        });
      }
    }
    return { results };
  }
}
