import {
  IsOptional,
  IsEnum,
  IsNumber,
  IsString,
  IsBoolean,
  IsDateString,
} from 'class-validator';
import { PunchType, WorkMode } from '@prisma/client';

export class PunchDto {
  @IsOptional()
  @IsEnum(PunchType)
  punchType?: PunchType;

  @IsOptional()
  @IsEnum(WorkMode)
  workMode?: WorkMode;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsString()
  deviceId?: string;

  @IsOptional()
  @IsBoolean()
  isOffline?: boolean;

  @IsOptional()
  @IsDateString()
  timestamp?: string;
}
