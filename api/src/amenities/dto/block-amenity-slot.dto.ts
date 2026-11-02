import {
  IsISO8601,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class BlockAmenitySlotDto {
  /**
   * UUID tiện ích cần khóa lịch.
   * @example "00000000-0000-4000-8000-000000000601"
   */
  @IsUUID() amenityId!: string;

  /**
   * Thời điểm bắt đầu khóa theo ISO 8601.
   * @example "2026-11-01T01:00:00.000Z"
   */
  @IsISO8601() startAt!: string;

  /**
   * Thời điểm kết thúc khóa theo ISO 8601.
   * @example "2026-11-01T05:00:00.000Z"
   */
  @IsISO8601() endAt!: string;

  /**
   * Lý do khóa khung giờ.
   * @example "Bảo trì và vệ sinh định kỳ."
   */
  @IsOptional() @IsString() @MaxLength(500) note?: string;
}
