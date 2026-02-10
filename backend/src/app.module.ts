import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { LeaveModule } from './modules/leave/leave.module';
import { AttendanceModule } from './modules/attendance/attendance.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { AssetsModule } from './modules/assets/assets.module';
import { TicketsModule } from './modules/tickets/tickets.module';
import { ClaimsModule } from './modules/claims/claims.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    LeaveModule,
    AttendanceModule,
    NotificationsModule,
    AssetsModule,
    TicketsModule,
    ClaimsModule,
  ],
})
export class AppModule { }
