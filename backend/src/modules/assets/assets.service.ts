import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class AssetsService {
    constructor(private prisma: PrismaService) { }

    // --- ASSETS ---
    async createAsset(data: Prisma.AssetUncheckedCreateInput) {
        return this.prisma.asset.create({ data });
    }

    async getAssets(where?: Prisma.AssetWhereInput) {
        return this.prisma.asset.findMany({
            where,
            include: {
                category: true,
                owner: true,
                assignments: {
                    where: { isActive: true },
                    include: { assignedTo: true },
                },
            },
            orderBy: { createdAt: 'desc' },
        });
    }

    async getAssetById(id: string) {
        const asset = await this.prisma.asset.findUnique({
            where: { id },
            include: {
                category: true,
                owner: true,
                assignments: {
                    include: { assignedTo: true, assignedBy: true },
                    orderBy: { assignedDate: 'desc' },
                },
            },
        });
        if (!asset) throw new NotFoundException(`Asset with ID ${id} not found`);
        return asset;
    }

    async updateAsset(id: string, data: Prisma.AssetUpdateInput) {
        return this.prisma.asset.update({
            where: { id },
            data,
        });
    }

    // --- ASSET CATEGORIES ---
    async createCategory(data: Prisma.AssetCategoryCreateInput) {
        return this.prisma.assetCategory.create({ data });
    }

    async getCategories() {
        return this.prisma.assetCategory.findMany({
            include: { _count: { select: { assets: true, softwares: true } } },
        });
    }

    // --- ASSET ASSIGNMENTS ---
    async assignAsset(data: Prisma.AssetAssignmentUncheckedCreateInput) {
        // 1. Check if asset is available
        const asset = await this.prisma.asset.findUnique({ where: { id: data.assetId } });
        if (!asset) throw new NotFoundException('Asset not found');

        // 2. Create assignment
        const assignment = await this.prisma.assetAssignment.create({ data });

        // 3. Update asset status
        await this.prisma.asset.update({
            where: { id: data.assetId },
            data: { status: 'In use', ownerId: data.assignedToId },
        });

        return assignment;
    }

    async returnAsset(assignmentId: string, returnData: { returnDate: Date; condition: string }) {
        const assignment = await this.prisma.assetAssignment.findUnique({ where: { id: assignmentId } });
        if (!assignment) throw new NotFoundException('Assignment not found');

        const updated = await this.prisma.assetAssignment.update({
            where: { id: assignmentId },
            data: {
                isActive: false,
                returnDate: returnData.returnDate,
                returnCondition: returnData.condition,
                returnStatus: 'Returned',
            },
        });

        // Mark asset as Available
        await this.prisma.asset.update({
            where: { id: assignment.assetId },
            data: { status: 'Available', ownerId: null },
        });

        return updated;
    }

    // --- SOFTWARE ---
    async createSoftware(data: Prisma.SoftwareUncheckedCreateInput) {
        return this.prisma.software.create({ data });
    }

    async getSoftwares() {
        return this.prisma.software.findMany({
            include: { category: true },
        });
    }
}
