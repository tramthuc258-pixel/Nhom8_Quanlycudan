import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

export class ReviewAmenityBookingDto {
  /**
   * true để duyệt, false để từ chối lượt đặt.
   * @example true
   */
  @IsBoolean() approved!: boolean;

  /**
   * Ghi chú của ban quản lý.
   * @example "Lượt đặt hợp lệ và đã được giữ chỗ."
   */
  @IsOptional() @IsString() @MaxLength(2000) note?: string;
}
