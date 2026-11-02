import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsISO8601,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';
import { SecurityIncidentType } from '../../generated/prisma/client';

export class CreateSecurityIncidentDto {
  /**
   * UUID căn hộ của người báo sự cố.
   * @example "00000000-0000-4000-8000-000000000201"
   */
  @IsUUID() apartmentId!: string;

  /**
   * Loại sự cố: NOISE, DISORDER, SUSPICIOUS_PERSON, PROPERTY_DAMAGE, FIRE_SAFETY, DISPUTE, LOST_AND_FOUND hoặc OTHER.
   * @example "NOISE"
   */
  @IsEnum(SecurityIncidentType) type!: SecurityIncidentType;

  /**
   * Tiêu đề ngắn của phản ánh.
   * @example "Tiếng ồn lớn sau 23 giờ"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(5)
  @MaxLength(200)
  title!: string;

  /**
   * Mô tả chi tiết sự việc.
   * @example "Có tiếng nhạc lớn kéo dài tại hành lang và ảnh hưởng các căn hộ lân cận."
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(10)
  @MaxLength(5000)
  description!: string;

  /**
   * Vị trí xảy ra sự cố.
   * @example "Hành lang tầng 3 tòa Homie A"
   */
  @IsOptional() @IsString() @MaxLength(255) location?: string;

  /**
   * Thời điểm xảy ra sự cố theo ISO 8601.
   * @example "2026-10-26T16:30:00.000Z"
   */
  @IsISO8601() occurredAt!: string;
}
