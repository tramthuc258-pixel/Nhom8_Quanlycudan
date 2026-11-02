import { Module } from '@nestjs/common';
import { ResidentServicesController } from './resident-services.controller';
import { ResidentServicesService } from './resident-services.service';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [ResidentServicesController],
  providers: [ResidentServicesService],
})
export class ResidentServicesModule {}
