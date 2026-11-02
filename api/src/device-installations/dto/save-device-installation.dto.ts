import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DevicePlatform } from '../../generated/prisma/client';

export class SaveDeviceInstallationDto {
  /** Mã đăng ký do Firebase Messaging cấp cho thiết bị. */
  @ApiProperty({
    description: 'Mã đăng ký Firebase Messaging của thiết bị hiện tại.',
    example: 'fcm-registration-token-from-android-device',
  })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(20)
  @MaxLength(4096)
  firebaseToken!: string;

  /** Nền tảng của thiết bị: ANDROID, IOS hoặc WEB. */
  @ApiProperty({ enum: DevicePlatform, example: DevicePlatform.ANDROID })
  @IsEnum(DevicePlatform)
  platform!: DevicePlatform;

  /** Tên thiết bị phục vụ quản lý phiên đăng nhập. */
  @ApiPropertyOptional({ example: 'Samsung Galaxy A55' })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  deviceName?: string;
}
