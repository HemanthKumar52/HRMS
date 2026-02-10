import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { UsersService } from './users.service';
import { ListUsersDto } from './dto/list-users.dto';
import { CurrentUser, CurrentUserPayload } from '../../common/decorators';

@Controller('users')
@UseGuards(AuthGuard('jwt'))
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get()
  async findAll(
    @CurrentUser() user: CurrentUserPayload,
    @Query() query: ListUsersDto,
  ) {
    return this.usersService.findAll(user.organizationId, query);
  }

  @Get(':id')
  async findById(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') id: string,
  ) {
    return this.usersService.findById(id, user.organizationId);
  }

  @Get(':id/team')
  async getTeam(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') id: string,
  ) {
    return this.usersService.getTeam(id, user.organizationId);
  }
}
