import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { HousingController } from './housing.controller';
import { HousingService } from './housing.service';
import { PublicHousingController } from './public-housing.controller';

@Module({
  imports: [NotificationsModule],
  controllers: [HousingController, PublicHousingController],
  providers: [HousingService],
})
export class HousingModule {}
