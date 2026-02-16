import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { LeaveStatus, LeaveType, Role } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { ApplyLeaveDto } from './dto/apply-leave.dto';
import { LeaveHistoryDto } from './dto/leave-history.dto';

@Injectable()
export class LeaveService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  async applyLeave(userId: string, dto: ApplyLeaveDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { manager: true },
    });

    if (!user) {
      throw new BadRequestException('User not found');
    }

    const fromDate = new Date(dto.fromDate);
    const toDate = new Date(dto.toDate);

    if (fromDate > toDate) {
      throw new BadRequestException('From date cannot be after to date');
    }

    const daysDiff = Math.ceil(
      (toDate.getTime() - fromDate.getTime()) / (1000 * 60 * 60 * 24),
    ) + 1;
    const leaveDays = dto.isHalfDay ? 0.5 : daysDiff;

    const year = new Date().getFullYear();
    const balance = await this.prisma.leaveBalance.findUnique({
      where: {
        userId_leaveType_year: {
          userId,
          leaveType: dto.type,
          year,
        },
      },
    });

    if (balance) {
      const availableDays = balance.totalDays - balance.usedDays;
      if (leaveDays > availableDays && dto.type !== LeaveType.UNPAID) {
        throw new BadRequestException(
          `Insufficient ${dto.type.toLowerCase()} leave balance. Available: ${availableDays} days`,
        );
      }
    }

    const leave = await this.prisma.leave.create({
      data: {
        userId,
        type: dto.type,
        fromDate,
        toDate,
        isHalfDay: dto.isHalfDay || false,
        halfDayType: dto.halfDayType,
        reason: dto.reason,
      },
    });

    if (user.manager) {
      await this.notificationsService.create({
        userId: user.manager.id,
        title: 'New Leave Request',
        body: `${user.firstName} ${user.lastName} has requested ${dto.type.toLowerCase()} leave`,
        type: 'LEAVE_REQUEST',
        payload: { leaveId: leave.id },
      });
    }

    return leave;
  }

  async getBalance(userId: string) {
    const year = new Date().getFullYear();
    const balances = await this.prisma.leaveBalance.findMany({
      where: { userId, year },
    });

    const leaveTypes = Object.values(LeaveType);
    const result = leaveTypes.map((type) => {
      const balance = balances.find((b) => b.leaveType === type);
      return {
        type,
        total: balance?.totalDays || 0,
        used: balance?.usedDays || 0,
        available: (balance?.totalDays || 0) - (balance?.usedDays || 0),
      };
    });

    return { balances: result, year };
  }

  async getHistory(userId: string, dto: LeaveHistoryDto) {
    const { status, type, page = 1, limit = 20 } = dto;
    const skip = (page - 1) * limit;

    const where: any = { userId };

    if (status) {
      where.status = status;
    }

    if (type) {
      where.type = type;
    }

    const [leaves, total] = await Promise.all([
      this.prisma.leave.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.leave.count({ where }),
    ]);

    return {
      leaves,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getLeaveById(userId: string, leaveId: string) {
    const leave = await this.prisma.leave.findFirst({
      where: { id: leaveId, userId },
      include: {
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            managerId: true,
            manager: {
              select: { id: true, firstName: true, lastName: true },
            },
          },
        },
      },
    });

    if (!leave) {
      throw new NotFoundException('Leave not found');
    }

    return leave;
  }

  async cancelLeave(userId: string, leaveId: string) {
    const leave = await this.prisma.leave.findFirst({
      where: { id: leaveId, userId },
    });

    if (!leave) {
      throw new NotFoundException('Leave not found');
    }

    if (leave.status !== LeaveStatus.PENDING) {
      throw new BadRequestException('Only pending leaves can be cancelled');
    }

    return this.prisma.leave.update({
      where: { id: leaveId },
      data: { status: LeaveStatus.CANCELLED },
    });
  }

  async approveLeave(
    approverId: string,
    approverRole: string,
    leaveId: string,
  ) {
    const leave = await this.prisma.leave.findUnique({
      where: { id: leaveId },
      include: { user: true },
    });

    if (!leave) {
      throw new NotFoundException('Leave not found');
    }

    if (leave.status !== LeaveStatus.PENDING) {
      throw new BadRequestException('Only pending leaves can be approved');
    }

    const approver = await this.prisma.user.findUnique({
      where: { id: approverId },
    });

    const isManager = leave.user.managerId === approverId;
    const isHrAdmin = approverRole === Role.HR_ADMIN;

    if (!isManager && !isHrAdmin) {
      throw new ForbiddenException(
        'You are not authorized to approve this leave',
      );
    }

    const updatedLeave = await this.prisma.leave.update({
      where: { id: leaveId },
      data: {
        status: LeaveStatus.APPROVED,
        approvedBy: approverId,
        approvedAt: new Date(),
      },
    });

    const fromDate = new Date(leave.fromDate);
    const toDate = new Date(leave.toDate);
    const daysDiff =
      Math.ceil(
        (toDate.getTime() - fromDate.getTime()) / (1000 * 60 * 60 * 24),
      ) + 1;
    const leaveDays = leave.isHalfDay ? 0.5 : daysDiff;

    const year = fromDate.getFullYear();
    await this.prisma.leaveBalance.upsert({
      where: {
        userId_leaveType_year: {
          userId: leave.userId,
          leaveType: leave.type,
          year,
        },
      },
      update: {
        usedDays: { increment: leaveDays },
      },
      create: {
        userId: leave.userId,
        leaveType: leave.type,
        year,
        totalDays: 0,
        usedDays: leaveDays,
      },
    });

    await this.notificationsService.create({
      userId: leave.userId,
      title: 'Leave Approved',
      body: `Your ${leave.type.toLowerCase()} leave request has been approved`,
      type: 'LEAVE_APPROVED',
      payload: { leaveId: leave.id },
    });

    return updatedLeave;
  }

  async rejectLeave(
    approverId: string,
    approverRole: string,
    leaveId: string,
    reason?: string,
  ) {
    const leave = await this.prisma.leave.findUnique({
      where: { id: leaveId },
      include: { user: true },
    });

    if (!leave) {
      throw new NotFoundException('Leave not found');
    }

    if (leave.status !== LeaveStatus.PENDING) {
      throw new BadRequestException('Only pending leaves can be rejected');
    }

    const isManager = leave.user.managerId === approverId;
    const isHrAdmin = approverRole === Role.HR_ADMIN;

    if (!isManager && !isHrAdmin) {
      throw new ForbiddenException(
        'You are not authorized to reject this leave',
      );
    }

    const updatedLeave = await this.prisma.leave.update({
      where: { id: leaveId },
      data: {
        status: LeaveStatus.REJECTED,
        rejectReason: reason,
      },
    });

    await this.notificationsService.create({
      userId: leave.userId,
      title: 'Leave Rejected',
      body: `Your ${leave.type.toLowerCase()} leave request has been rejected`,
      type: 'LEAVE_REJECTED',
      payload: { leaveId: leave.id, reason },
    });

    return updatedLeave;
  }

  async getPendingApprovals(managerId: string) {
    const reports = await this.prisma.user.findMany({
      where: { managerId },
      select: { id: true },
    });

    const reportIds = reports.map((r) => r.id);

    const leaves = await this.prisma.leave.findMany({
      where: {
        userId: { in: reportIds },
        status: LeaveStatus.PENDING,
      },
      include: {
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return { leaves };
  }
}
