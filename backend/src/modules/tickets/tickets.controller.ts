import { Controller, Get, Post, Body, UseGuards, Request } from '@nestjs/common';
import { TicketsService } from './tickets.service';
import { AuthGuard } from '@nestjs/passport';

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
}
