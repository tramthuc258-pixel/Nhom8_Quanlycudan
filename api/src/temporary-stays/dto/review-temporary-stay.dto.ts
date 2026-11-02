import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

export class ReviewTemporaryStayDto {
  /**
   * true để duyệt, false để từ chối đăng ký.
   * @example true
   */
  @IsBoolean() approved!: boolean;

  /**
   * Ghi chú của người duyệt.
   * @example "Thông tin khách và thời gian lưu trú hợp lệ."
   */
  @IsOptional() @IsString() @MaxLength(1000) note?: string;
}
