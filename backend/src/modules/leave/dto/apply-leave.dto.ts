import {
  IsNotEmpty,
  IsEnum,
  IsDateString,
  IsOptional,
  IsBoolean,
  IsString,
} from 'class-validator';
import { LeaveType, HalfDayType } from '@prisma/client';

export class ApplyLeaveDto {
  @IsEnum(LeaveType)
  @IsNotEmpty()
  type: LeaveType;

  @IsDateString()
  @IsNotEmpty()
  fromDate: string;

  @IsDateString()
  @IsNotEmpty()
  toDate: string;

  @IsOptional()
  @IsBoolean()
  isHalfDay?: boolean;

  @IsOptional()
  @IsEnum(HalfDayType)
  halfDayType?: HalfDayType;

  @IsNotEmpty({ message: 'Reason is required' })
  @IsString()
  reason: string;
}
