import { Module } from '@nestjs/common';
import { TemporaryStaysController } from './temporary-stays.controller';
import { TemporaryStaysService } from './temporary-stays.service';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [TemporaryStaysController],
  providers: [TemporaryStaysService],
})
export class TemporaryStaysModule {}
