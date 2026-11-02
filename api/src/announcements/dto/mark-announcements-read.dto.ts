import { ArrayMaxSize, IsArray, IsUUID } from 'class-validator';

export class MarkAnnouncementsReadDto {
  /**
   * Danh sách UUID thông báo cần đánh dấu đã đọc.
   * @example ["00000000-0000-4000-8000-000000000301", "00000000-0000-4000-8000-000000000302"]
   */
  @IsArray()
  @ArrayMaxSize(500)
  @IsUUID('4', { each: true })
  announcementIds!: string[];
}
