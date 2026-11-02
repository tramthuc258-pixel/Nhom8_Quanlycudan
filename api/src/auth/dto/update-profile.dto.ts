import { Transform } from 'class-transformer';
import {
  IsDateString,
  IsOptional,
  IsString,
  IsUrl,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

export class UpdateProfileDto {
  /**
   * Họ và tên hiển thị của người dùng.
   * @example "Nguyễn Văn An"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(2, { message: 'Họ tên phải có ít nhất 2 ký tự.' })
  @MaxLength(150)
  fullName!: string;

  /**
   * Số điện thoại liên hệ.
   * @example "0901234567"
   */
  @IsOptional()
  @IsString()
  @Matches(/^[0-9+\s.-]{8,20}$/, { message: 'Số điện thoại không hợp lệ.' })
  phoneNumber?: string;

  /**
   * Ngày sinh theo định dạng ISO YYYY-MM-DD.
   * @example "1998-08-22"
   */
  @IsOptional()
  @IsDateString({}, { message: 'Ngày sinh không hợp lệ.' })
  dateOfBirth?: string | null;

  /**
   * Địa chỉ dùng để liên hệ, không phải quan hệ căn hộ.
   * @example "12 Nguyễn Huệ, Quận 1, TP.HCM"
   */
  @IsOptional()
  @IsString()
  @MaxLength(500)
  contactAddress?: string;

  /**
   * Đường dẫn avatar đã được tải lên Supabase Storage của Homie.
   * @example "https://project.supabase.co/storage/v1/object/sign/homie-files/avatars/user-id/avatar.jpg?token=..."
   */
  @IsOptional()
  @IsUrl(
    { require_protocol: true, protocols: ['https'] },
    { message: 'Đường dẫn ảnh đại diện không hợp lệ.' },
  )
  @MaxLength(2048)
  avatarUrl?: string;
}
