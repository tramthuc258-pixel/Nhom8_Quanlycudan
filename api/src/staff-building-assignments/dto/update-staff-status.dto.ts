import { IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { UserStatus } from '../../generated/prisma/client';

export class UpdateStaffStatusDto {
  @ApiProperty({ enum: UserStatus, example: UserStatus.LOCKED })
  @IsEnum(UserStatus)
  status!: UserStatus;
}
