import { Transform } from 'class-transformer';
import {
  IsDateString,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateHouseholdMemberDto {
  /** UUID căn hộ mà thành viên đang sinh sống. */
  @IsUUID()
  apartmentId!: string;

  /** Họ và tên thành viên; người này không cần tài khoản đăng nhập. */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  fullName!: string;

  /** Ngày sinh, có thể bổ sung sau. @example "2015-08-20" */
  @IsOptional()
  @IsDateString({}, { message: 'Ngày sinh không hợp lệ.' })
  dateOfBirth?: string;

  /** Số điện thoại, không bắt buộc với trẻ em. @example "0901234567" */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @Matches(/^[0-9+\s.-]{8,20}$/, { message: 'Số điện thoại không hợp lệ.' })
  phone?: string;

  /** Quan hệ với chủ nhà/người thuê đại diện. @example "Con" */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  relationship!: string;

  /** Ngày bắt đầu sinh sống tại căn hộ. @example "2026-10-27" */
  @IsDateString({}, { message: 'Ngày bắt đầu cư trú không hợp lệ.' })
  startDate!: string;
}
