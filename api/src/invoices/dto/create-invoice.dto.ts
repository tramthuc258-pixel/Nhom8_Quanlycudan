import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsNumber,
  IsString,
  IsUUID,
  IsOptional,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export class CreateInvoiceItemDto {
  /** UUID loại phí trong danh mục. Bỏ trống chỉ khi nhập khoản thu đặc biệt. */
  @IsOptional()
  @IsUUID()
  feeTypeId?: string;

  /**
   * Tên khoản phí trong hóa đơn.
   * @example "Phí quản lý tháng 10/2026"
   */
  @IsString()
  @MaxLength(150)
  name!: string;

  /**
   * Số lượng tính phí.
   * @example 72.5
   */
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  @Max(999999999)
  quantity!: number;

  /**
   * Đơn giá, đơn vị đồng.
   * @example 12000
   */
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  @Max(999999999999)
  unitPrice!: number;
}

export class CreateInvoiceDto {
  /**
   * UUID căn hộ nhận hóa đơn.
   * @example "00000000-0000-4000-8000-000000000201"
   */
  @IsUUID()
  apartmentId!: string;

  /**
   * UUID cư dân chịu trách nhiệm thanh toán: người thuê đang hiệu lực,
   * hoặc chủ sở hữu nếu căn hộ chưa có người thuê.
   * @example "00000000-0000-4000-8000-000000000101"
   */
  @IsUUID()
  payerResidentId!: string;

  /**
   * Kỳ hóa đơn, dùng ngày đầu tháng theo ISO.
   * @example "2026-10-01"
   */
  @IsDateString()
  billingMonth!: string;

  /**
   * Hạn thanh toán hóa đơn.
   * @example "2026-10-31"
   */
  @IsDateString()
  dueDate!: string;

  /**
   * Phát hành ngay sau khi tạo hay giữ ở trạng thái nháp.
   * @example true
   */
  @IsBoolean()
  publish!: boolean;

  /**
   * Danh sách các khoản phí; hóa đơn phải có ít nhất một khoản.
   * @example [{"name":"Phí quản lý tháng 10/2026","quantity":72.5,"unitPrice":12000},{"name":"Phí gửi xe","quantity":1,"unitPrice":150000}]
   */
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateInvoiceItemDto)
  items!: CreateInvoiceItemDto[];

  /** Mã đơn dịch vụ đã hoàn thành do cư dân xác nhận, tính vào hóa đơn này. */
  @IsOptional()
  @IsArray()
  @IsUUID('all', { each: true })
  serviceRequestIds?: string[];
}
