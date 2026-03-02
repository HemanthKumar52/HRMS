import { IsNotEmpty, IsString } from 'class-validator';

export class UpdateFaceDto {
  @IsString()
  @IsNotEmpty()
  firstName: string;

  @IsString()
  @IsNotEmpty()
  lastName: string;

  @IsString()
  @IsNotEmpty()
  facePhoto: string;
}
