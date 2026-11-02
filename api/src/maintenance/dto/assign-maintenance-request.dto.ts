import { IsUUID } from 'class-validator';

export class AssignMaintenanceRequestDto {
  /**
   * ID tài khoản kỹ thuật viên được phân công.
   * @example "8b8af7ef-6c75-4d15-a640-19d90990362b"
   */
  @IsUUID()
  assigneeId!: string;
}
