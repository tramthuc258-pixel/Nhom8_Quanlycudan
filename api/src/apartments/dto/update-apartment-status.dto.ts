import { IsEnum } from 'class-validator';
import { ApartmentStatus } from '../../generated/prisma/client';

export class UpdateApartmentStatusDto {
  /**
   * Trạng thái mới: OCCUPIED, VACANT hoặc UNDER_MAINTENANCE.
   * @example "UNDER_MAINTENANCE"
   */
  @IsEnum(ApartmentStatus)
  status!: ApartmentStatus;
}
