import { Transform } from 'class-transformer';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { ServiceRequestStatus } from '../../generated/prisma/client';

export class UpdateServiceRequestStatusDto {
  /**
   * Trạng thái mới: PENDING, CONFIRMED, IN_PROGRESS, WAITING_RESIDENT,
   * COMPLETED hoặc CANCELLED.
   * @example "CONFIRMED"
   */
  @IsEnum(ServiceRequestStatus)
  status!: ServiceRequestStatus;

  /**
   * Ghi chú xác nhận hoặc kết quả dịch vụ.
   * @example "Đã xác nhận lịch, nhân viên sẽ đến đúng giờ."
   */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MaxLength(2000)
  note?: string;
}
