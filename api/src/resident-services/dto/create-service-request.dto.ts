import { Type } from 'class-transformer';
import {
  IsISO8601,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateServiceRequestDto {
  /**
   * UUID dịch vụ lấy từ GET /api/resident-services/catalog.
   * @example "00000000-0000-4000-8000-000000000501"
   */
  @IsUUID()
  serviceId!: string;

  /**
   * UUID căn hộ sử dụng dịch vụ.
   * @example "00000000-0000-4000-8000-000000000201"
   */
  @IsUUID()
  apartmentId!: string;

  /**
   * Số lượng đơn vị dịch vụ.
   * @example 1
   */
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(99)
  quantity!: number;

  /**
   * Thời gian muốn thực hiện dịch vụ theo ISO 8601.
   * @example "2026-10-28T02:00:00.000Z"
   */
  @IsISO8601()
  scheduledAt!: string;

  /**
   * Yêu cầu bổ sung dành cho đơn vị phục vụ.
   * @example "Vui lòng liên hệ trước khi lên căn hộ."
   */
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
