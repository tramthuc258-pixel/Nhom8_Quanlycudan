import { Transform } from 'class-transformer';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class ReviewDto {
  /**
   * Lý do từ chối bài đăng hoặc hồ sơ.
   * @example "Thông tin giao dịch chưa đầy đủ, vui lòng bổ sung mô tả và giá."
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(5)
  @MaxLength(1000)
  reason!: string;
}
