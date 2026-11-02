import { Transform } from 'class-transformer';
import {
  IsDateString,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CompleteApplicationDto {
  /**
   * Số hợp đồng giao dịch đã ký bên ngoài hệ thống.
   * @example "HD-2026-0015"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  @IsString()
  @MinLength(4)
  @MaxLength(50)
  contractNumber!: string;

  /**
   * Ngày hai bên ký hợp đồng.
   * @example "2026-10-28"
   */
  @IsDateString({}, { message: 'Ngày ký hợp đồng không hợp lệ.' })
  contractSignedAt!: string;

  /**
   * Ngày hợp đồng bắt đầu có hiệu lực.
   * @example "2026-11-01"
   */
  @IsDateString({}, { message: 'Ngày hiệu lực không hợp lệ.' })
  effectiveDate!: string;

  /**
   * Ghi chú khi ban quản lý hoàn tất hồ sơ.
   * @example "Đã đối chiếu hợp đồng và xác nhận giao dịch bên ngoài."
   */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MaxLength(2000)
  note?: string;
}
