import { IsUUID } from 'class-validator';

export class AssignSecurityIncidentDto {
  /** UUID bảo vệ được phân công xử lý sự cố. */
  @IsUUID()
  assigneeId!: string;
}
