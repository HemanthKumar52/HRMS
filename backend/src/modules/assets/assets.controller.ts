import {
    Controller,
    Get,
    Post,
    Body,
    Patch,
    Param,
    UseGuards,
    Request,
} from '@nestjs/common';
import { AssetsService } from './assets.service';
import { AuthGuard } from '@nestjs/passport';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('assets')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class AssetsController {
    constructor(private readonly assetsService: AssetsService) { }

    // --- ASSETS ---
    @Post()
    @Roles(Role.HR_ADMIN, Role.MANAGER)
    createAsset(@Body() data: any) { // Use any
        return this.assetsService.createAsset(data);
    }

    @Get()
    findAll(@Request() req: any) {
        const user = req.user;
        if (user.role === Role.EMPLOYEE) {
            // Employees only see assets assigned to them
            return this.assetsService.getAssets({
                assignments: { some: { assignedToId: user.userId, isActive: true } },
            });
        }
        // Admins see all
        return this.assetsService.getAssets();
    }

    @Get(':id')
    findOne(@Param('id') id: string) {
        return this.assetsService.getAssetById(id);
    }

    @Patch(':id')
    @Roles(Role.HR_ADMIN, Role.MANAGER)
    update(
        @Param('id') id: string,
        @Body() data: any, // Use any
    ) {
        return this.assetsService.updateAsset(id, data);
    }

    // --- CATEGORIES ---
    @Post('categories')
    @Roles(Role.HR_ADMIN)
    createCategory(@Body() data: any) { // Use any
        return this.assetsService.createCategory(data);
    }

    @Get('categories')
    getCategories() {
        return this.assetsService.getCategories();
    }

    // --- ASSIGNMENTS ---
    @Post('assignments')
    @Roles(Role.HR_ADMIN, Role.MANAGER)
    assignAsset(
        @Body() data: any, // Use any
        @Request() req: any
    ) {
        // Automatically set assignedBy to current user if not provided
        data.assignedById = req.user.userId;
        return this.assetsService.assignAsset(data);
    }

    @Patch('assignments/:id/return')
    @Roles(Role.HR_ADMIN, Role.MANAGER)
    returnAsset(
        @Param('id') id: string,
        @Body() returnData: { returnDate: Date; condition: string },
    ) {
        return this.assetsService.returnAsset(id, returnData);
    }

    // --- SOFTWARE ---
    @Post('software')
    @Roles(Role.HR_ADMIN, Role.MANAGER)
    createSoftware(@Body() data: any) { // Use any
        return this.assetsService.createSoftware(data);
    }

    @Get('software')
    getSoftware() {
        return this.assetsService.getSoftwares();
    }
}
