import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { RoleCode } from '../../generated/prisma/client';
import { STAFF_ROLE_CODES } from './create-staff-account.dto';

export class UpdateStaffAccountDto {
  @ApiPropertyOptional({ example: 'Trần Minh Kỹ Thuật' })
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  fullName?: string;

  @ApiPropertyOptional({ enum: STAFF_ROLE_CODES, example: RoleCode.TECHNICIAN })
  @IsOptional()
  @IsEnum(RoleCode)
  role?: RoleCode;
}
