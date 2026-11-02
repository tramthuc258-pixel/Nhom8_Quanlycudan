import { IsString, MaxLength, MinLength } from 'class-validator';

export class ChangePasswordDto {
  /**
   * Mật khẩu hiện đang sử dụng.
   * @example "12121212"
   */
  @IsString()
  @MinLength(8, { message: 'Mật khẩu hiện tại không hợp lệ.' })
  @MaxLength(72)
  currentPassword!: string;

  /**
   * Mật khẩu mới có ít nhất 8 ký tự.
   * @example "Homie@456"
   */
  @IsString()
  @MinLength(8, { message: 'Mật khẩu mới phải có ít nhất 8 ký tự.' })
  @MaxLength(72)
  newPassword!: string;
}
