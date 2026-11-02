import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { SecurityIncidentStatus } from '../../generated/prisma/client';

export class UpdateSecurityIncidentDto {
  /**
   * Trạng thái mới: REPORTED, REVIEWING, RESOLVED hoặc CANCELLED.
   * @example "REVIEWING"
   */
  @IsEnum(SecurityIncidentStatus) status!: SecurityIncidentStatus;

  /**
   * Ghi chú tiếp nhận hoặc kết quả xử lý.
   * @example "Bảo vệ đã kiểm tra khu vực và nhắc nhở cư dân liên quan."
   */
  @IsOptional() @IsString() @MaxLength(2000) resolutionNote?: string;
}
