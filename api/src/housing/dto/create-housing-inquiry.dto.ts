import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateHousingInquiryDto {
  /**
   * UUID bài đăng công khai mà khách đang quan tâm.
   * @example "00000000-0000-4000-8000-000000000401"
   */
  @IsUUID()
  listingId!: string;

  /**
   * Họ tên khách để ban quản lý xưng hô khi liên hệ.
   * @example "Nguyễn Văn An"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  fullName!: string;

  /**
   * Số điện thoại liên hệ bắt buộc.
   * @example "0901234567"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @Matches(/^[0-9+\s.-]{8,20}$/, { message: 'Số điện thoại không hợp lệ.' })
  phone!: string;

  /**
   * Email nhận phản hồi, không bắt buộc.
   * @example "an.nguyen@example.com"
   */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => {
    if (typeof value !== 'string') return value;
    const normalized = value.trim().toLowerCase();
    return normalized.length === 0 ? undefined : normalized;
  })
  @IsEmail({}, { message: 'Email không hợp lệ.' })
  @MaxLength(255)
  email?: string;

  /**
   * Nội dung khách muốn trao đổi với ban quản lý.
   * @example "Tôi muốn xem căn hộ vào chiều thứ Bảy."
   */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MaxLength(1000)
  message?: string;
}
