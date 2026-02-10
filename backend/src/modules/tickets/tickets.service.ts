import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { TicketPriority, TicketStatus } from '@prisma/client';

@Injectable()
export class TicketsService {
    constructor(private prisma: PrismaService) { }

    async create(userId: string, data: any) {
        return this.prisma.ticket.create({
            data: {
                userId,
                subject: data.subject,
                description: data.description,
                department: data.department,
                priority: (data.priority as TicketPriority) || TicketPriority.MEDIUM,
                status: TicketStatus.OPEN,
            },
        });
    }

    async findAll(userId: string) {
        return this.prisma.ticket.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
        });
    }
}
