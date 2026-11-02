import { Transform } from 'class-transformer';
import { IsEmail, IsString, Matches } from 'class-validator';

export class VerifyRegistrationDto {
  /** Email vừa yêu cầu gửi mã xác minh. @example "cudan@example.com" */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail({}, { message: 'Email không hợp lệ.' })
  email!: string;

  /** Mã OTP gồm 6 chữ số được gửi tới email. @example "123456" */
  @IsString()
  @Matches(/^\d{6}$/, { message: 'Mã OTP phải gồm đúng 6 chữ số.' })
  code!: string;
}
