import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { AuthenticatedUser } from '../auth/auth.types';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { RoleCode } from '../generated/prisma/client';
import { CreateInvoiceDto } from './dto/create-invoice.dto';
import { SubmitPaymentDto } from './dto/submit-payment.dto';
import { RejectPaymentDto } from './dto/reject-payment.dto';
import { InvoicesService } from './invoices.service';
import { VnpayService } from './vnpay.service';

type AuthenticatedRequest = Request & { user: AuthenticatedUser };

@ApiTags('Hóa đơn và thanh toán')
@ApiBearerAuth('access-token')
@Controller('invoices')
@UseGuards(JwtAuthGuard, RolesGuard)
export class InvoicesController {
  constructor(
    private readonly invoicesService: InvoicesService,
    private readonly vnpayService: VnpayService,
  ) {}

  @Get()
  findAll(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.invoicesService.findAll(request.user);
  }

  @Get('fee-types')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT, RoleCode.ACCOUNTANT)
  findFeeTypes(): Promise<object> {
    return this.invoicesService.findFeeTypes();
  }

  @Get('unbilled-services')
  @Roles(RoleCode.ADMIN, RoleCode.ACCOUNTANT)
  findUnbilledServices(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.invoicesService.findUnbilledServices(request.user);
  }

  @Get('payment-options')
  paymentOptions(): object {
    return this.invoicesService.paymentOptions();
  }

  @Post()
  @Roles(RoleCode.ADMIN, RoleCode.ACCOUNTANT)
  create(
    @Req() request: AuthenticatedRequest,
    @Body() dto: CreateInvoiceDto,
  ): Promise<object> {
    return this.invoicesService.create(request.user, dto);
  }

  @Patch(':id/publish')
  @Roles(RoleCode.ADMIN, RoleCode.ACCOUNTANT)
  publish(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.invoicesService.publish(id, request.user);
  }

  @Post(':id/payment-submission')
  @Roles(RoleCode.RESIDENT)
  submitPayment(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SubmitPaymentDto,
  ): Promise<object> {
    return this.invoicesService.submitPayment(id, request.user, dto);
  }

  @Post(':id/vnpay/create')
  @Roles(RoleCode.RESIDENT)
  createVnpayPayment(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.vnpayService.createPaymentUrl(
      id,
      request.user,
      request.ip ?? '127.0.0.1',
    );
  }

  @Patch(':id/payment-confirm')
  @Roles(RoleCode.ADMIN, RoleCode.ACCOUNTANT)
  confirmPayment(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.invoicesService.confirmPayment(id, request.user);
  }

  @Patch(':id/payment-reject')
  @Roles(RoleCode.ADMIN, RoleCode.ACCOUNTANT)
  rejectPayment(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RejectPaymentDto,
  ): Promise<object> {
    return this.invoicesService.rejectPayment(id, request.user, dto);
  }

  @Patch(':id/cancel')
  @Roles(RoleCode.ADMIN, RoleCode.ACCOUNTANT)
  cancel(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.invoicesService.cancel(id, request.user);
  }
}
