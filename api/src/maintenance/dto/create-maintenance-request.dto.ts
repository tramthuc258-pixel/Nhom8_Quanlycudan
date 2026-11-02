import { Transform } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';
import {
  MaintenanceCategory,
  MaintenancePriority,
} from '../../generated/prisma/client';

export class CreateMaintenanceRequestDto {
  /**
   * UUID căn hộ cần hỗ trợ.
   * @example "00000000-0000-4000-8000-000000000201"
   */
  @IsUUID()
  apartmentId!: string;

  /**
   * Tiêu đề ngắn của yêu cầu.
   * @example "Vòi nước bếp bị rò rỉ"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(5)
  @MaxLength(200)
  title!: string;

  /**
   * Mô tả hiện tượng và mức độ ảnh hưởng.
   * @example "Vòi nước dưới bồn rửa bị rò liên tục và làm ướt tủ bếp."
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(15)
  @MaxLength(5000)
  description!: string;

  /**
   * Vị trí cụ thể cần sửa chữa.
   * @example "Khu vực bếp, dưới bồn rửa"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(3)
  @MaxLength(255)
  location!: string;

  /**
   * Nhóm sự cố: ELECTRICAL, PLUMBING, ELEVATOR, COMMON_AREA, SECURITY hoặc OTHER.
   * @example "PLUMBING"
   */
  @IsEnum(MaintenanceCategory)
  category!: MaintenanceCategory;

  /**
   * Mức ưu tiên: LOW, NORMAL, HIGH hoặc URGENT.
   * @example "NORMAL"
   */
  @IsEnum(MaintenancePriority)
  priority!: MaintenancePriority;

  /**
   * Ảnh hoặc PDF hiện trường đã tải lên Supabase Storage.
   * @example ["https://project.supabase.co/storage/v1/object/public/homie-files/maintenance/example.jpg"]
   */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @IsUrl({}, { each: true })
  imageUrls?: string[];
}
