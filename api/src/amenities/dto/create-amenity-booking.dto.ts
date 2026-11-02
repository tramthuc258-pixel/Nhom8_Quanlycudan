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

export class CreateAmenityBookingDto {
  /**
   * UUID tiện ích lấy từ GET /api/amenities.
   * @example "00000000-0000-4000-8000-000000000601"
   */
  @IsUUID() amenityId!: string;

  /**
   * UUID căn hộ thực hiện đặt chỗ.
   * @example "00000000-0000-4000-8000-000000000201"
   */
  @IsUUID() apartmentId!: string;

  /**
   * Thời gian bắt đầu đặt tiện ích theo ISO 8601.
   * @example "2026-10-31T02:00:00.000Z"
   */
  @IsISO8601() startAt!: string;

  /**
   * Tổng số người tham dự.
   * @example 4
   */
  @Type(() => Number) @IsInt() @Min(1) @Max(500) attendeeCount!: number;

  /**
   * Ghi chú cho lượt đặt.
   * @example "Gia đình gồm 2 người lớn và 2 trẻ em."
   */
  @IsOptional() @IsString() @MaxLength(500) note?: string;
}
