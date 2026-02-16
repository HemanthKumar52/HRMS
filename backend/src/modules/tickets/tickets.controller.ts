import { Controller, Get, Post, Patch, Body, Param, UseGuards, Request } from '@nestjs/common';
import { TicketsService } from './tickets.service';
import { AuthGuard } from '@nestjs/passport';
import { TicketStatus } from '@prisma/client';

@Controller('tickets')
@UseGuards(AuthGuard('jwt'))
export class TicketsController {
    constructor(private readonly ticketsService: TicketsService) { }

    @Post()
    create(@Request() req: any, @Body() data: any) {
        return this.ticketsService.create(req.user.id, data);
    }

    @Get()
    findAll(@Request() req: any) {
        return this.ticketsService.findAll(req.user.id);
    }

    // Get tickets assigned to the current user (as manager)
    @Get('assigned')
    findAssigned(@Request() req: any) {
        return this.ticketsService.findAssignedToManager(req.user.id);
    }

    // Update ticket status (for managers)
    @Patch(':id/status')
    updateStatus(
        @Param('id') id: string,
        @Body() data: { status: TicketStatus; resolution?: string },
    ) {
        return this.ticketsService.updateStatus(id, data.status, data.resolution);
    }
}
