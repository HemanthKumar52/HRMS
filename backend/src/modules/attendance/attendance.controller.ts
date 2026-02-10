import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AttendanceService } from './attendance.service';
import { PunchDto } from './dto/punch.dto';
import { AttendanceHistoryDto } from './dto/attendance-history.dto';
import { AttendanceSummaryDto } from './dto/attendance-summary.dto';
import { CurrentUser } from '../../common/decorators';

@Controller('attendance')
@UseGuards(AuthGuard('jwt'))
export class AttendanceController {
  constructor(private attendanceService: AttendanceService) {}

  @Post('punch')
  async punch(@CurrentUser('userId') userId: string, @Body() dto: PunchDto) {
    return this.attendanceService.punch(userId, dto);
  }

  @Get('today')
  async getTodayStatus(@CurrentUser('userId') userId: string) {
    return this.attendanceService.getTodayStatus(userId);
  }

  @Get('summary')
  async getSummary(
    @CurrentUser('userId') userId: string,
    @Query() dto: AttendanceSummaryDto,
  ) {
    return this.attendanceService.getSummary(userId, dto);
  }

  @Get('history')
  async getHistory(
    @CurrentUser('userId') userId: string,
    @Query() dto: AttendanceHistoryDto,
  ) {
    return this.attendanceService.getHistory(userId, dto);
  }

  @Post('sync')
  async syncOfflinePunches(
    @CurrentUser('userId') userId: string,
    @Body('punches') punches: PunchDto[],
  ) {
    return this.attendanceService.syncOfflinePunches(userId, punches);
  }
}
