import { Transform } from 'class-transformer';
import {
  IsDateString,
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { MembershipType } from '../../generated/prisma/client';

export class CreateMembershipDto {
  /**
   * UUID tài khoản cư dân có sẵn; có thể bỏ qua để tìm bằng email.
   * @example "00000000-0000-4000-8000-000000000101"
   */
  @IsOptional()
  @IsUUID()
  residentId?: string;

  /**
   * UUID căn hộ lấy từ GET /api/apartments.
   * @example "00000000-0000-4000-8000-000000000201"
   */
  @IsUUID()
  apartmentId!: string;

  /**
   * Họ tên cư dân cần liên kết.
   * @example "Trần Thị Bình"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  fullName!: string;

  /**
   * Số điện thoại cư dân.
   * @example "0901234567"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @Matches(/^[0-9+\s.-]{8,20}$/, { message: 'Số điện thoại không hợp lệ.' })
  phone!: string;

  /**
   * Email phải trùng với tài khoản đã đăng ký.
   * @example "binh.tenant@homie.com"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail({}, { message: 'Email cư dân không hợp lệ.' })
  @MaxLength(255)
  email!: string;

  /** Loại tài khoản đại diện: OWNER hoặc TENANT. @example "TENANT" */
  @IsIn([MembershipType.OWNER, MembershipType.TENANT], {
    message: 'Loại quan hệ chỉ được là OWNER hoặc TENANT.',
  })
  type!: MembershipType;

  /**
   * Ngày quan hệ bắt đầu có hiệu lực.
   * @example "2026-11-01"
   */
  @IsDateString({}, { message: 'Ngày bắt đầu không hợp lệ.' })
  startDate!: string;

  /**
   * Ngày kết thúc dự kiến, thường dùng cho người thuê.
   * @example "2027-10-31"
   */
  @IsOptional()
  @IsDateString({}, { message: 'Ngày kết thúc không hợp lệ.' })
  endDate?: string;
}
