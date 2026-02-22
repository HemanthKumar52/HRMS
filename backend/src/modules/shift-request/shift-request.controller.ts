import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ShiftRequestService } from './shift-request.service';
import { CreateShiftRequestDto } from './dto/create-shift-request.dto';
import { CurrentUser } from '../../common/decorators';

@Controller('shift-requests')
@UseGuards(AuthGuard('jwt'))
export class ShiftRequestController {
  constructor(private shiftRequestService: ShiftRequestService) {}

  @Post()
  async create(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateShiftRequestDto,
  ) {
    return this.shiftRequestService.create(userId, dto);
  }

  @Get()
  async getUserRequests(@CurrentUser('userId') userId: string) {
    return this.shiftRequestService.getUserRequests(userId);
  }

  @Get('pending')
  async getPendingRequests() {
    return this.shiftRequestService.getPendingRequests();
  }

  @Patch(':id/approve')
  async approve(
    @Param('id') id: string,
    @CurrentUser('userId') userId: string,
  ) {
    return this.shiftRequestService.approve(id, userId);
  }

  @Patch(':id/reject')
  async reject(
    @Param('id') id: string,
    @CurrentUser('userId') userId: string,
    @Body('reason') reason?: string,
  ) {
    return this.shiftRequestService.reject(id, userId, reason);
  }

  @Patch(':id/cancel')
  async cancel(
    @Param('id') id: string,
    @CurrentUser('userId') userId: string,
  ) {
    return this.shiftRequestService.cancel(id, userId);
  }
}
