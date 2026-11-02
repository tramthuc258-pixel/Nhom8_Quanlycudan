import { Transform } from 'class-transformer';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class RejectPaymentDto {
  /** Lý do từ chối để cư dân bổ sung hoặc kiểm tra lại giao dịch. */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  note!: string;
}
