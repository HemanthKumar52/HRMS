import { IsString, IsOptional } from 'class-validator';

export class CreateTimesheetTaskDto {
  @IsString()
  project: string;

  @IsString()
  activity: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  workLocation?: string;

  @IsOptional()
  @IsString()
  monHours?: string;

  @IsOptional()
  @IsString()
  tueHours?: string;

  @IsOptional()
  @IsString()
  wedHours?: string;

  @IsOptional()
  @IsString()
  thuHours?: string;

  @IsOptional()
  @IsString()
  friHours?: string;

  @IsOptional()
  @IsString()
  satHours?: string;

  @IsOptional()
  @IsString()
  sunHours?: string;
}
