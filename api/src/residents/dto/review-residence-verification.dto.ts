import { Transform } from 'class-transformer';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class ReviewResidenceVerificationDto {
  /** Căn cứ ban quản lý đã dùng để xác minh hồ sơ khi duyệt. @example "Hồ sơ bàn giao căn hộ" */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsOptional()
  @IsString()
  @MaxLength(100)
  verificationBasis?: string;

  /** Ghi chú của ban quản lý; bắt buộc khi từ chối. @example "Thông tin hợp đồng chưa khớp với hồ sơ căn hộ." */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  reviewNote?: string;
}
