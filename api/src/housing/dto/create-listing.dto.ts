import { Transform } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  IsUrl,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { HousingTransactionType } from '../../generated/prisma/client';

export class CreateListingDto {
  /**
   * UUID căn hộ muốn đăng, lấy từ GET /api/apartments.
   * @example "00000000-0000-4000-8000-000000000201"
   */
  @IsUUID()
  apartmentId!: string;

  /**
   * Tiêu đề bài đăng.
   * @example "Cho thuê căn hộ 2 phòng ngủ đầy đủ nội thất"
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(5)
  @MaxLength(200)
  title!: string;

  /**
   * Mô tả chi tiết căn hộ và điều kiện giao dịch.
   * @example "Căn hộ tầng cao, ban công thoáng, có đầy đủ nội thất và có thể nhận nhà ngay."
   */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(10)
  @MaxLength(5000)
  description!: string;

  /**
   * Hình thức giao dịch: RENT hoặc PURCHASE.
   * @example "RENT"
   */
  @IsEnum(HousingTransactionType)
  transactionType!: HousingTransactionType;

  /**
   * Giá thuê mỗi tháng hoặc giá bán căn hộ, đơn vị đồng.
   * @example 12000000
   */
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1)
  price!: number;

  /**
   * Tiền đặt cọc, đơn vị đồng.
   * @example 24000000
   */
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  deposit!: number;

  /**
   * Ngày căn hộ bắt đầu có thể bàn giao.
   * @example "2026-11-01"
   */
  @IsDateString({}, { message: 'Ngày bắt đầu không hợp lệ.' })
  availableFrom!: string;

  /**
   * Ảnh căn hộ đã tải lên Storage, tối đa 5 ảnh.
   * @example ["https://project.supabase.co/storage/v1/object/sign/homie-files/housing/example.jpg?token=..."]
   */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @IsUrl({}, { each: true })
  imageUrls?: string[];
}
