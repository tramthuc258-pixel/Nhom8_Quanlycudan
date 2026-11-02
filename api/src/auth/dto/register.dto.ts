import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

export class RegisterDto {
  /**
   * Email dùng để đăng nhập, không được trùng tài khoản đã có.
   * @example "khachhang@example.com"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail({}, { message: 'Email không hợp lệ.' })
  @MaxLength(255)
  email!: string;

  /**
   * Mật khẩu từ 8 đến 72 ký tự.
   * @example "Homie@123"
   */
  @IsString()
  @MinLength(8, { message: 'Mật khẩu phải có ít nhất 8 ký tự.' })
  @MaxLength(72, { message: 'Mật khẩu không được vượt quá 72 ký tự.' })
  password!: string;

  /**
   * Họ và tên người đăng ký.
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
   * Số điện thoại liên hệ, có thể bổ sung sau.
   * @example "0901234567"
   */
  @IsOptional()
  @IsString()
  @Matches(/^[0-9+\s.-]{8,20}$/, { message: 'Số điện thoại không hợp lệ.' })
  phone?: string;
}
