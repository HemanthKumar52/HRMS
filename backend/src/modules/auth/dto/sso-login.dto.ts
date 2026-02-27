import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class SsoTokenDto {
  @IsString()
  @IsNotEmpty()
  accessToken: string;

  @IsString()
  @IsOptional()
  provider?: string;
}
