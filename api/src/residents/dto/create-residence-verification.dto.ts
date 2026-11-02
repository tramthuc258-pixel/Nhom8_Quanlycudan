import { Transform } from 'class-transformer';
import {
  IsDateString,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
} from 'class-validator';
import { MembershipType } from '../../generated/prisma/client';

export class CreateResidenceVerificationDto {
  /** UUID căn hộ cư dân muốn xác minh. @example "00000000-0000-4000-8000-000000000201" */
  @IsUUID()
  apartmentId!: string;

  /** Tư cách đại diện tại căn hộ: OWNER (chủ hộ) hoặc TENANT (người thuê). @example "TENANT" */
  @IsIn([MembershipType.OWNER, MembershipType.TENANT])
  type!: MembershipType;

  /** Ngày bắt đầu sở hữu hoặc thuê căn hộ. @example "2026-10-27" */
  @IsDateString({}, { message: 'Ngày bắt đầu không hợp lệ.' })
  startDate!: string;

  /** Số điện thoại liên hệ của người gửi yêu cầu. @example "0901234567" */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @Matches(/^[0-9+\s.-]{8,20}$/, { message: 'Số điện thoại không hợp lệ.' })
  contactPhone!: string;

  /** Ghi chú bổ sung cho ban quản lý. @example "Hợp đồng thuê có hiệu lực từ tháng 11." */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;
}
