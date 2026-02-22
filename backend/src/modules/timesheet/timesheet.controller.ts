import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { TimesheetService } from './timesheet.service';
import { TimesheetQueryDto } from './dto/timesheet-query.dto';
import { CreateTimesheetTaskDto } from './dto/create-timesheet-task.dto';
import { CurrentUser } from '../../common/decorators';

@Controller('timesheet')
@UseGuards(AuthGuard('jwt'))
export class TimesheetController {
  constructor(private timesheetService: TimesheetService) {}

  @Get('current')
  async getCurrentWeekTimesheet(@CurrentUser('userId') userId: string) {
    return this.timesheetService.getCurrentWeekTimesheet(userId);
  }

  @Post(':id/submit')
  async submitTimesheet(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
  ) {
    return this.timesheetService.submitTimesheet(userId, id);
  }

  @Get('history')
  async getTimesheetHistory(
    @CurrentUser('userId') userId: string,
    @Query() query: TimesheetQueryDto,
  ) {
    return this.timesheetService.getTimesheetHistory(userId, query.page, query.limit);
  }

  @Get('pending')
  async getSubmittedTimesheets(@Query() query: TimesheetQueryDto) {
    return this.timesheetService.getSubmittedTimesheets(query.page, query.limit);
  }

  @Patch(':id/approve')
  async approveTimesheet(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
  ) {
    return this.timesheetService.approveTimesheet(id, userId);
  }

  // ─── TimesheetTask Endpoints ──────────────────────────────────────────

  @Get(':id/detail')
  async getTimesheetDetail(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
  ) {
    return this.timesheetService.getTimesheetDetail(userId, id);
  }

  @Post(':id/tasks')
  async addTask(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
    @Body() dto: CreateTimesheetTaskDto,
  ) {
    return this.timesheetService.addTask(userId, id, dto);
  }

  @Patch('tasks/:taskId')
  async updateTask(
    @CurrentUser('userId') userId: string,
    @Param('taskId') taskId: string,
    @Body() dto: CreateTimesheetTaskDto,
  ) {
    return this.timesheetService.updateTask(userId, taskId, dto);
  }

  @Delete('tasks/:taskId')
  async deleteTask(
    @CurrentUser('userId') userId: string,
    @Param('taskId') taskId: string,
  ) {
    return this.timesheetService.deleteTask(userId, taskId);
  }
}
