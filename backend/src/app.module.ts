import { Module, NestModule, MiddlewareConsumer, Logger } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ServeStaticModule } from '@nestjs/serve-static';
import { ScheduleModule } from '@nestjs/schedule';
import { join } from 'path';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { LeaveModule } from './modules/leave/leave.module';
import { AttendanceModule } from './modules/attendance/attendance.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { AssetsModule } from './modules/assets/assets.module';
import { TicketsModule } from './modules/tickets/tickets.module';
import { ClaimsModule } from './modules/claims/claims.module';
import { TimesheetModule } from './modules/timesheet/timesheet.module';
import { ShiftRequestModule } from './modules/shift-request/shift-request.module';
import { Request, Response, NextFunction } from 'express';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', 'uploads'),
      serveRoot: '/uploads',
    }),
    ScheduleModule.forRoot(),
    PrismaModule,
    AuthModule,
    UsersModule,
    LeaveModule,
    AttendanceModule,
    NotificationsModule,
    AssetsModule,
    TicketsModule,
    ClaimsModule,
    TimesheetModule,
    ShiftRequestModule,
  ],
})
export class AppModule implements NestModule {
  private readonly logger = new Logger('HTTP');

  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply((req: Request, res: Response, next: NextFunction) => {
        const start = Date.now();
        res.on('finish', () => {
          const duration = Date.now() - start;
          const log = `[${req.method}] ${req.originalUrl} - ${res.statusCode} (${duration}ms)`;
          if (res.statusCode >= 400) {
            this.logger.warn(log);
          } else {
            this.logger.log(log);
          }
        });
        next();
      })
      .forRoutes('*');
  }
}
