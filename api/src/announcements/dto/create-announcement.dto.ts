import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  IsUUID,
} from 'class-validator';
import {
  AnnouncementAudience,
  AnnouncementCategory,
  AnnouncementPriority,
} from '../../generated/prisma/client';

export class CreateAnnouncementDto {
  /** Tòa nhà nhận thông báo. Quản trị viên có thể bỏ trống để gửi toàn hệ thống. */
  @IsOptional()
  @IsUUID()
  buildingId?: string;

  /**
   * Tiêu đề thông báo.
   * @example "Bảo trì hệ thống nước tòa Homie A"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(5)
  @MaxLength(120)
  title!: string;

  /**
   * Nội dung chi tiết gửi đến người nhận.
   * @example "Hệ thống nước sẽ tạm ngưng từ 09:00 đến 11:00 ngày 28/10/2026."
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(10)
  @MaxLength(2000)
  content!: string;

  /**
   * Danh mục: GENERAL, MAINTENANCE, BILLING, EVENT hoặc EMERGENCY.
   * @example "MAINTENANCE"
   */
  @IsEnum(AnnouncementCategory)
  category!: AnnouncementCategory;

  /**
   * Mức độ: NORMAL, IMPORTANT hoặc URGENT.
   * @example "IMPORTANT"
   */
  @IsEnum(AnnouncementPriority)
  priority!: AnnouncementPriority;

  /**
   * Đối tượng nhận: ALL, RESIDENTS hoặc MANAGERS.
   * @example "RESIDENTS"
   */
  @IsEnum(AnnouncementAudience)
  audience!: AnnouncementAudience;

  /**
   * Thời điểm phát hành theo ISO 8601.
   * @example "2026-10-27T02:00:00.000Z"
   */
  @IsDateString({}, { message: 'Ngày phát hành không hợp lệ.' })
  publishedAt!: string;

  /**
   * Thời điểm hết hạn; có thể bỏ trống nếu thông báo không hết hạn.
   * @example "2026-10-30T16:59:59.000Z"
   */
  @IsOptional()
  @IsDateString({}, { message: 'Ngày hết hạn không hợp lệ.' })
  expiresAt?: string;

  /**
   * Có ghim thông báo lên đầu danh sách hay không.
   * @example true
   */
  @IsBoolean()
  isPinned!: boolean;

  /**
   * Phát hành ngay khi tạo hay lưu ở trạng thái chưa phát hành.
   * @example true
   */
  @IsBoolean()
  isPublished!: boolean;
}
