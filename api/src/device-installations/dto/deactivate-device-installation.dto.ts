import { Transform } from 'class-transformer';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class DeactivateDeviceInstallationDto {
  @ApiProperty({
    description: 'Mã Firebase của thiết bị cần ngừng nhận thông báo.',
    example: 'fcm-registration-token-from-android-device',
  })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(20)
  @MaxLength(4096)
  firebaseToken!: string;
}
