import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { PrismaModule } from './database/prisma.module';
import { ApartmentsModule } from './apartments/apartments.module';
import { ResidentsModule } from './residents/residents.module';
import { HousingModule } from './housing/housing.module';
import { AnnouncementsModule } from './announcements/announcements.module';
import { MaintenanceModule } from './maintenance/maintenance.module';
import { ResidentServicesModule } from './resident-services/resident-services.module';
import { InvoicesModule } from './invoices/invoices.module';
import { AmenitiesModule } from './amenities/amenities.module';
import { TemporaryStaysModule } from './temporary-stays/temporary-stays.module';
import { SecurityIncidentsModule } from './security-incidents/security-incidents.module';
import { NotificationsModule } from './notifications/notifications.module';
import { BuildingAccessModule } from './building-access/building-access.module';
import { StaffBuildingAssignmentsModule } from './staff-building-assignments/staff-building-assignments.module';
import { DeviceInstallationsModule } from './device-installations/device-installations.module';
import { AuditLogsModule } from './audit-logs/audit-logs.module';
import { StorageModule } from './storage/storage.module';

@Module({
  imports: [
    ThrottlerModule.forRoot([
      {
        name: 'default',
        ttl: 60_000,
        limit: 120,
      },
    ]),
    PrismaModule,
    BuildingAccessModule,
    AuthModule,
    ApartmentsModule,
    ResidentsModule,
    HousingModule,
    AnnouncementsModule,
    MaintenanceModule,
    ResidentServicesModule,
    InvoicesModule,
    AmenitiesModule,
    TemporaryStaysModule,
    SecurityIncidentsModule,
    NotificationsModule,
    StaffBuildingAssignmentsModule,
    DeviceInstallationsModule,
    AuditLogsModule,
    StorageModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
