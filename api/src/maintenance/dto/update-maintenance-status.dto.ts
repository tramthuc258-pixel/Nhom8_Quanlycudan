import { Transform } from 'class-transformer';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { MaintenanceStatus } from '../../generated/prisma/client';

export class UpdateMaintenanceStatusDto {
  /**
   * Trạng thái mới: SUBMITTED, RECEIVED, IN_PROGRESS, WAITING_RESIDENT, COMPLETED hoặc CANCELLED.
   * @example "IN_PROGRESS"
   */
  @IsEnum(MaintenanceStatus)
  status!: MaintenanceStatus;

  /**
   * Ghi chú tiến độ hoặc kết quả xử lý.
   * @example "Kỹ thuật viên đang thay gioăng và kiểm tra đường ống."
   */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MaxLength(2000)
  note?: string;
}
