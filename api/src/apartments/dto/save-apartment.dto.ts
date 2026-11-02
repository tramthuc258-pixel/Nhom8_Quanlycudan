import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsNumber,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { ApartmentStatus } from '../../generated/prisma/client';

export class SaveApartmentDto {
  /**
   * Mã căn hộ, tự động chuẩn hóa thành chữ hoa.
   * @example "A-0501"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  @IsString()
  @MaxLength(30)
  code!: string;

  /**
   * Tên hoặc mã tòa nhà đã tồn tại trong hệ thống.
   * @example "HOMIE-A"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MaxLength(150)
  buildingName!: string;

  /**
   * Số tầng của căn hộ.
   * @example 5
   */
  @IsInt()
  @Min(1)
  @Max(300)
  floor!: number;

  /**
   * Diện tích căn hộ theo mét vuông.
   * @example 72.5
   */
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1)
  area!: number;

  /**
   * Số phòng ngủ.
   * @example 2
   */
  @IsInt()
  @Min(1)
  @Max(20)
  bedrooms!: number;

  /**
   * Trạng thái căn hộ: OCCUPIED, VACANT hoặc UNDER_MAINTENANCE.
   * @example "VACANT"
   */
  @IsEnum(ApartmentStatus)
  status!: ApartmentStatus;
}
