import { Transform } from 'class-transformer';
import {
  IsDateString,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
} from 'class-validator';

export class CreateApplicationDto {
  /**
   * UUID bài đăng lấy từ GET /api/housing/listings.
   * @example "00000000-0000-4000-8000-000000000401"
   */
  @IsUUID()
  listingId!: string;

  /**
   * Số điện thoại để ban quản lý liên hệ.
   * @example "0901234567"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @Matches(/^[0-9+\s.-]{8,20}$/, { message: 'Số điện thoại không hợp lệ.' })
  phone!: string;

  /**
   * Ngày muốn bắt đầu thuê hoặc nhận chuyển nhượng.
   * @example "2026-11-15"
   */
  @IsDateString({}, { message: 'Ngày bắt đầu không hợp lệ.' })
  preferredStartDate!: string;

  /**
   * Ngày kết thúc dự kiến, chỉ cần thiết cho giao dịch thuê.
   * @example "2027-11-14"
   */
  @IsOptional()
  @IsDateString({}, { message: 'Ngày kết thúc không hợp lệ.' })
  preferredEndDate?: string;

  /**
   * Lời nhắn cho chủ căn hộ hoặc ban quản lý.
   * @example "Tôi muốn xem căn hộ vào cuối tuần này."
   */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MaxLength(1000)
  note?: string;
}
