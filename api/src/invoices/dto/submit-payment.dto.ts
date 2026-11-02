import { IsUrl, MaxLength } from 'class-validator';

export class SubmitPaymentDto {
  /** Đường dẫn ảnh/PDF biên lai do cư dân tải lên Homie Storage. */
  @IsUrl({ require_tld: false })
  @MaxLength(2000)
  proofUrl!: string;
}
