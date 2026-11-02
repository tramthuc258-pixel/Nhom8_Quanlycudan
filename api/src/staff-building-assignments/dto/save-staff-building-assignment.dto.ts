import { Transform } from 'class-transformer';
import { IsDateString, IsOptional, IsUUID } from 'class-validator';

export class SaveStaffBuildingAssignmentDto {
  /** Mã tài khoản nhân viên cần phân công. */
  @IsUUID()
  userId!: string;

  /** Mã tòa nhà nhân viên sẽ phụ trách. */
  @IsUUID()
  buildingId!: string;

  /** Ngày bắt đầu phân công; bỏ trống để dùng thời điểm hiện tại. */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => value || undefined)
  @IsDateString()
  startDate?: string;

  /** Ngày kết thúc dự kiến, nếu có. */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => value || undefined)
  @IsDateString()
  endDate?: string;
}
