import { Transform } from 'class-transformer';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export enum MaintenanceResidentDecision {
  CONFIRM = 'CONFIRM',
  REOPEN = 'REOPEN',
}

export class RespondMaintenanceResultDto {
  /**
   * CONFIRM nếu sự cố đã được khắc phục; REOPEN nếu vẫn còn sự cố.
   * @example "CONFIRM"
   */
  @IsEnum(MaintenanceResidentDecision)
  decision!: MaintenanceResidentDecision;

  /**
   * Phản hồi của cư dân. Bắt buộc tối thiểu 5 ký tự khi chọn REOPEN.
   * @example "Vòi nước vẫn còn rò nhẹ khi sử dụng."
   */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MaxLength(2000)
  note?: string;
}
