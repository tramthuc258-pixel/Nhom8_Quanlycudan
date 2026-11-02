import { Transform } from 'class-transformer';
import {
  IsDateString,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateTemporaryStayDto {
  /**
   * UUID căn hộ tiếp nhận khách lưu trú.
   * @example "00000000-0000-4000-8000-000000000201"
   */
  @IsUUID() apartmentId!: string;

  /**
   * Họ và tên khách lưu trú.
   * @example "Lê Hoàng Minh"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  guestFullName!: string;

  /**
   * Ngày sinh của khách.
   * @example "1995-04-16"
   */
  @IsOptional() @IsDateString() guestDateOfBirth?: string;

  /**
   * Số điện thoại của khách.
   * @example "0912345678"
   */
  @IsOptional() @IsString() @MaxLength(20) guestPhone?: string;

  /**
   * Mối quan hệ với cư dân khai báo.
   * @example "Anh trai"
   */
  @IsOptional() @IsString() @MaxLength(100) relationshipToResident?: string;

  /**
   * Ngày bắt đầu lưu trú.
   * @example "2026-10-28"
   */
  @IsDateString() startDate!: string;

  /**
   * Ngày kết thúc lưu trú.
   * @example "2026-10-31"
   */
  @IsDateString() endDate!: string;

  /**
   * Mục đích lưu trú.
   * @example "Thăm gia đình"
   */
  @IsOptional() @IsString() @MaxLength(500) purpose?: string;
}
