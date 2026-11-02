import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

export class ResetPasswordDto {
  /**
   * Email đã yêu cầu đặt lại mật khẩu.
   * @example "an.owner@homie.com"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail({}, { message: 'Email không hợp lệ.' })
  @MaxLength(255)
  email!: string;

  /**
   * Mã xác nhận gồm 6 chữ số nhận được qua email hoặc developmentCode khi chạy cục bộ chưa có SMTP.
   * @example "123456"
   */
  @IsString()
  @Matches(/^\d{6}$/, { message: 'Mã xác nhận phải gồm 6 chữ số.' })
  code!: string;

  /**
   * Mật khẩu mới có ít nhất 8 ký tự.
   * @example "Homie@456"
   */
  @IsString()
  @MinLength(8, { message: 'Mật khẩu mới phải có ít nhất 8 ký tự.' })
  @MaxLength(72)
  newPassword!: string;
}
