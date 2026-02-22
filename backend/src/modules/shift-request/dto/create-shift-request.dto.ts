import { IsString, IsOptional, IsDateString } from 'class-validator';

export class CreateShiftRequestDto {
  @IsString()
  title: string;

  @IsString()
  fromShift: string;

  @IsString()
  toShift: string;

  @IsDateString()
  requestDate: string;

  @IsOptional()
  @IsString()
  reason?: string;
}
