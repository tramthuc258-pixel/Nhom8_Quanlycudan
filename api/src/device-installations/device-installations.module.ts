import { Module } from '@nestjs/common';
import { DeviceInstallationsController } from './device-installations.controller';
import { DeviceInstallationsService } from './device-installations.service';

@Module({
  controllers: [DeviceInstallationsController],
  providers: [DeviceInstallationsService],
})
export class DeviceInstallationsModule {}
