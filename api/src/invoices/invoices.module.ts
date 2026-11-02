import { Module } from '@nestjs/common';
import { InvoicesController } from './invoices.controller';
import { InvoicesService } from './invoices.service';
import { NotificationsModule } from '../notifications/notifications.module';
import { VnpayController } from './vnpay.controller';
import { VnpayService } from './vnpay.service';

@Module({
  imports: [NotificationsModule],
  controllers: [InvoicesController, VnpayController],
  providers: [InvoicesService, VnpayService],
})
export class InvoicesModule {}
