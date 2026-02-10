import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ClaimType, ClaimStatus } from '@prisma/client';

@Injectable()
export class ClaimsService {
    constructor(private prisma: PrismaService) { }

    async create(userId: string, data: any) {
        return this.prisma.claim.create({
            data: {
                userId,
                type: data.type,
                amount: Number(data.amount),
                description: data.description,
                attachmentUrl: data.attachmentUrl,
                status: ClaimStatus.PENDING,
            },
        });
    }

    async findAll(userId: string) {
        return this.prisma.claim.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
        });
    }
}
