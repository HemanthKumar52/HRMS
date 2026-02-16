import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Role } from '@prisma/client';
import { LeaveService } from './leave.service';
import { ApplyLeaveDto } from './dto/apply-leave.dto';
import { LeaveHistoryDto } from './dto/leave-history.dto';
import { RejectLeaveDto } from './dto/reject-leave.dto';
import { CurrentUser, CurrentUserPayload, Roles } from '../../common/decorators';
import { RolesGuard } from '../../common/guards';

@Controller('leave')
@UseGuards(AuthGuard('jwt'))
export class LeaveController {
  constructor(private leaveService: LeaveService) {}

  @Post('apply')
  async applyLeave(
    @CurrentUser('userId') userId: string,
    @Body() dto: ApplyLeaveDto,
  ) {
    return this.leaveService.applyLeave(userId, dto);
  }

  @Get('balance')
  async getBalance(@CurrentUser('userId') userId: string) {
    return this.leaveService.getBalance(userId);
  }

  @Get('history')
  async getHistory(
    @CurrentUser('userId') userId: string,
    @Query() dto: LeaveHistoryDto,
  ) {
    return this.leaveService.getHistory(userId, dto);
  }

  @Get(':id')
  async getLeaveById(
    @CurrentUser('userId') userId: string,
    @Param('id') leaveId: string,
  ) {
    return this.leaveService.getLeaveById(userId, leaveId);
  }

  @Patch(':id/cancel')
  async cancelLeave(
    @CurrentUser('userId') userId: string,
    @Param('id') leaveId: string,
  ) {
    return this.leaveService.cancelLeave(userId, leaveId);
  }

  @Post(':id/approve')
  @UseGuards(RolesGuard)
  @Roles(Role.MANAGER, Role.HR_ADMIN)
  async approveLeave(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') leaveId: string,
  ) {
    return this.leaveService.approveLeave(user.userId, user.role, leaveId);
  }

  @Post(':id/reject')
  @UseGuards(RolesGuard)
  @Roles(Role.MANAGER, Role.HR_ADMIN)
  async rejectLeave(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') leaveId: string,
    @Body() dto: RejectLeaveDto,
  ) {
    return this.leaveService.rejectLeave(
      user.userId,
      user.role,
      leaveId,
      dto.reason,
    );
  }

  @Get('pending-approvals')
  @UseGuards(RolesGuard)
  @Roles(Role.MANAGER, Role.HR_ADMIN)
  async getPendingApprovals(@CurrentUser('userId') userId: string) {
    return this.leaveService.getPendingApprovals(userId);
  }
}
