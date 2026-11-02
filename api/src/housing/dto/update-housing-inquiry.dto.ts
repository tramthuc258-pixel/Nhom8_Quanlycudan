import { Transform } from 'class-transformer';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { HousingInquiryStatus } from '../../generated/prisma/client';

export class UpdateHousingInquiryDto {
  /**
   * Trạng thái xử lý liên hệ khách.
   * @example "CONTACTED"
   */
  @IsEnum(HousingInquiryStatus)
  status!: HousingInquiryStatus;

  /**
   * Ghi chú nội bộ sau khi gọi điện hoặc gửi email.
   * @example "Đã gọi khách lúc 10:30, hẹn xem căn hộ vào thứ Bảy."
   */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MaxLength(1000)
  staffNote?: string;
}
