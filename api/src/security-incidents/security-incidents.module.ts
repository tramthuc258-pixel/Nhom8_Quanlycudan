import { Module } from '@nestjs/common';
import { SecurityIncidentsController } from './security-incidents.controller';
import { SecurityIncidentsService } from './security-incidents.service';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [SecurityIncidentsController],
  providers: [SecurityIncidentsService],
})
export class SecurityIncidentsModule {}
