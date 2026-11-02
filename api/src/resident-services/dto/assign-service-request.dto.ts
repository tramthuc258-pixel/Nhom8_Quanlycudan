import { IsUUID } from 'class-validator';

export class AssignServiceRequestDto {
  /**
   * ID tài khoản nhân viên được giao thực hiện dịch vụ.
   * @example "8b8af7ef-6c75-4d15-a640-19d90990362b"
   */
  @IsUUID()
  assigneeId!: string;
}
