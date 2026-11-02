import { Transform } from 'class-transformer';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export enum ServiceResidentDecision {
  CONFIRM = 'CONFIRM',
  REOPEN = 'REOPEN',
}

export class RespondServiceResultDto {
  /** CONFIRM nếu dịch vụ đã hoàn tất; REOPEN nếu cần xử lý lại. */
  @IsEnum(ServiceResidentDecision)
  decision!: ServiceResidentDecision;

  /** Phản hồi của cư dân; bắt buộc tối thiểu 5 ký tự khi chọn REOPEN. */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MaxLength(2000)
  note?: string;
}
