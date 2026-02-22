import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { ShiftRequestStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateShiftRequestDto } from './dto/create-shift-request.dto';

@Injectable()
export class ShiftRequestService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateShiftRequestDto) {
    return this.prisma.shiftRequest.create({
      data: {
        userId,
        title: dto.title,
        fromShift: dto.fromShift,
        toShift: dto.toShift,
        requestDate: new Date(dto.requestDate),
        reason: dto.reason,
      },
      include: {
        user: {
          select: {
            firstName: true,
            lastName: true,
          },
        },
      },
    });
  }

  async getUserRequests(userId: string) {
    return this.prisma.shiftRequest.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getPendingRequests() {
    return this.prisma.shiftRequest.findMany({
      where: { status: ShiftRequestStatus.PENDING },
      include: {
        user: {
          select: {
            firstName: true,
            lastName: true,
            email: true,
            department: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async approve(id: string, approverId: string) {
    const request = await this.prisma.shiftRequest.findUnique({
      where: { id },
    });

    if (!request) {
      throw new NotFoundException('Shift request not found');
    }

    if (request.status !== ShiftRequestStatus.PENDING) {
      throw new BadRequestException('Only pending requests can be approved');
    }

    return this.prisma.shiftRequest.update({
      where: { id },
      data: {
        status: ShiftRequestStatus.APPROVED,
        approvedBy: approverId,
        approvedAt: new Date(),
      },
    });
  }

  async reject(id: string, approverId: string, reason?: string) {
    const request = await this.prisma.shiftRequest.findUnique({
      where: { id },
    });

    if (!request) {
      throw new NotFoundException('Shift request not found');
    }

    if (request.status !== ShiftRequestStatus.PENDING) {
      throw new BadRequestException('Only pending requests can be rejected');
    }

    return this.prisma.shiftRequest.update({
      where: { id },
      data: {
        status: ShiftRequestStatus.REJECTED,
        approvedBy: approverId,
        approvedAt: new Date(),
        ...(reason && { reason }),
      },
    });
  }

  async cancel(id: string, userId: string) {
    const request = await this.prisma.shiftRequest.findUnique({
      where: { id },
    });

    if (!request) {
      throw new NotFoundException('Shift request not found');
    }

    if (request.userId !== userId) {
      throw new BadRequestException(
        'You can only cancel your own shift requests',
      );
    }

    if (request.status !== ShiftRequestStatus.PENDING) {
      throw new BadRequestException('Only pending requests can be cancelled');
    }

    return this.prisma.shiftRequest.update({
      where: { id },
      data: { status: ShiftRequestStatus.CANCELLED },
    });
  }
}
