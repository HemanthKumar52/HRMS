import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { UsersService } from './users.service';
import { ListUsersDto } from './dto/list-users.dto';
import { CreateUserDto } from './dto/create-user.dto';
import { CurrentUser, CurrentUserPayload } from '../../common/decorators';

@Controller('users')
@UseGuards(AuthGuard('jwt'))
export class UsersController {
  constructor(private usersService: UsersService) { }

  @Post()
  async create(
    @CurrentUser() user: CurrentUserPayload,
    @Body() createUserDto: CreateUserDto,
  ) {
    createUserDto.organizationId = user.organizationId;
    createUserDto.managerId = user.userId;
    return this.usersService.create(createUserDto);
  }

  @Get()
  async findAll(
    @CurrentUser() user: CurrentUserPayload,
    @Query() query: ListUsersDto,
  ) {
    return this.usersService.findAll(user.organizationId, query);
  }

  @Get('me/face-photo')
  async getFacePhoto(@CurrentUser() user: CurrentUserPayload) {
    return this.usersService.getFacePhoto(user.userId);
  }

  @Get('face-photos')
  async getAllFacePhotos(@CurrentUser() user: CurrentUserPayload) {
    return this.usersService.getAllFacePhotos(user.organizationId);
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

  @Patch('me/avatar')
  @UseInterceptors(
    FileInterceptor('avatar', {
      storage: diskStorage({
        destination: './uploads/avatars',
        filename: (_req, file, cb) => {
          const uniqueSuffix =
            Date.now() + '-' + Math.round(Math.random() * 1e9);
          cb(null, `avatar-${uniqueSuffix}${extname(file.originalname)}`);
        },
      }),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async updateAvatar(
    @CurrentUser() user: CurrentUserPayload,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.usersService.updateAvatar(user.userId, file.filename);
  }
}
