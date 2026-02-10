import { Controller, Get, Post, Body, UseGuards, Request } from '@nestjs/common';
import { ClaimsService } from './claims.service';
import { AuthGuard } from '@nestjs/passport';

@Controller('claims')
@UseGuards(AuthGuard('jwt'))
export class ClaimsController {
    constructor(private readonly claimsService: ClaimsService) { }

    @Post()
    create(@Request() req: any, @Body() data: any) {
        return this.claimsService.create(req.user.id, data);
    }

    @Get()
    findAll(@Request() req: any) {
        return this.claimsService.findAll(req.user.id);
    }
}
