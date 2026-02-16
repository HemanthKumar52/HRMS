import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { TicketPriority, TicketStatus } from '@prisma/client';

@Injectable()
export class TicketsService {
    constructor(private prisma: PrismaService) { }

    async create(userId: string, data: any) {
        // Get the user to find their reporting manager
        const user = await this.prisma.user.findUnique({
            where: { id: userId },
            include: { manager: true },
        });

        // Create the ticket
        const ticket = await this.prisma.ticket.create({
            data: {
                userId,
                subject: data.subject,
                description: data.description,
                department: data.department || 'General',
                priority: (data.priority as TicketPriority) || TicketPriority.MEDIUM,
                status: TicketStatus.OPEN,
                assignedToId: user?.managerId || null, // Assign to reporting manager
            },
            include: {
                user: {
                    select: {
                        firstName: true,
                        lastName: true,
                        email: true,
                    },
                },
            },
        });

        // Notify the reporting manager if exists
        if (user?.managerId) {
            await this.prisma.notification.create({
                data: {
                    userId: user.managerId,
                    title: 'New Ticket Raised',
                    body: `${user.firstName} ${user.lastName} has raised a ticket: ${data.subject}`,
                    type: 'TICKET',
                    payload: {
                        ticketId: ticket.id,
                        priority: ticket.priority,
                    },
                },
            });
        }

        return ticket;
    }

    async findAll(userId: string) {
        return this.prisma.ticket.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
        });
    }

    // Find tickets assigned to a manager for approval
    async findAssignedToManager(managerId: string) {
        return this.prisma.ticket.findMany({
            where: { assignedToId: managerId },
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

    // Update ticket status (for manager)
    async updateStatus(ticketId: string, status: TicketStatus, resolution?: string) {
        return this.prisma.ticket.update({
            where: { id: ticketId },
            data: {
                status,
                resolution,
                resolvedAt: status === TicketStatus.RESOLVED ? new Date() : null,
            },
        });
    }
}
