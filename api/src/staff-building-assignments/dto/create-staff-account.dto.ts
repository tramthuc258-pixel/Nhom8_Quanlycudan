import { Transform } from 'class-transformer';
import {
  ArrayUnique,
  IsArray,
  IsEmail,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { RoleCode } from '../../generated/prisma/client';

export const STAFF_ROLE_CODES = [
  RoleCode.MANAGEMENT,
  RoleCode.ACCOUNTANT,
  RoleCode.RECEPTIONIST,
  RoleCode.SECURITY,
  RoleCode.TECHNICIAN,
] as const;

export class CreateStaffAccountDto {
  @ApiProperty({ example: 'Trần Minh Kỹ Thuật' })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  fullName!: string;

  @ApiProperty({ example: 'minh.technician@homie.com' })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail()
  @MaxLength(255)
  email!: string;

  @ApiProperty({ enum: STAFF_ROLE_CODES, example: RoleCode.TECHNICIAN })
  @IsEnum(RoleCode)
  role!: RoleCode;

  @ApiPropertyOptional({
    type: [String],
    description: 'Các tòa nhân viên được phân công ngay khi tạo tài khoản.',
  })
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsUUID('4', { each: true })
  buildingIds?: string[];
}
