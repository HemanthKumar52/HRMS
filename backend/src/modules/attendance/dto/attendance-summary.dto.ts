import { IsOptional, IsIn } from 'class-validator';

export class AttendanceSummaryDto {
  @IsOptional()
  @IsIn(['week', 'month'])
  period?: 'week' | 'month' = 'week';
}
