import { Module } from '@nestjs/common';
import { ShiftRequestController } from './shift-request.controller';
import { ShiftRequestService } from './shift-request.service';

@Module({
  controllers: [ShiftRequestController],
  providers: [ShiftRequestService],
  exports: [ShiftRequestService],
})
export class ShiftRequestModule {}
