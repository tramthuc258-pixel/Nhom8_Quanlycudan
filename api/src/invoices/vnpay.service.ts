import {
  BadRequestException,
  ConflictException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { createHmac, randomBytes, timingSafeEqual } from 'node:crypto';
import 'dotenv/config';
import type { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import {
  InvoiceStatus,
  NotificationType,
  PaymentMethod,
  PaymentStatus,
  Prisma,
} from '../generated/prisma/client';
import { NotificationsService } from '../notifications/notifications.service';
import { renderVnpayReturnPage } from './vnpay-return-page';

type VnpayQuery = Record<string, string | string[] | undefined>;

export interface VnpayCallbackResult {
  RspCode: string;
  Message: string;
  successful: boolean;
  invoiceId?: string;
  invoiceCode?: string;
  amount?: number;
  awaitingConfirmation?: boolean;
}

type VerifiedCallback = {
  params: Record<string, string>;
  payment: Prisma.PaymentGetPayload<{ include: { invoice: true } }>;
};

@Injectable()
export class VnpayService {
  private readonly paymentUrl =
    process.env.VNPAY_PAYMENT_URL ??
    'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  private readonly returnUrl =
    process.env.VNPAY_RETURN_URL ??
    'http://localhost:3000/api/payments/vnpay/return';
  private readonly tmnCode = process.env.VNPAY_TMN_CODE?.trim();
  private readonly hashSecret = process.env.VNPAY_HASH_SECRET?.trim();
  // Chỉ dùng callback Return làm phương án xác nhận khi chạy merchant Sandbox.
  private readonly sandboxReturnConfirmation =
    process.env.VNPAY_SANDBOX_RETURN_CONFIRMATION === 'true' &&
    this.paymentUrl.startsWith('https://sandbox.vnpayment.vn/');

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  async createPaymentUrl(
    invoiceId: string,
    actor: AuthenticatedUser,
    ipAddress: string,
  ): Promise<object> {
    this.assertConfigured();
    const invoice = await this.prisma.invoice.findUnique({
      where: { id: invoiceId },
      include: {
        apartment: true,
        payments: {
          where: { status: PaymentStatus.PENDING },
          orderBy: { createdAt: 'desc' },
        },
      },
    });
    if (!invoice || invoice.payerId !== actor.id) {
      throw new BadRequestException(
        'Không tìm thấy hóa đơn được giao cho tài khoản này.',
      );
    }
    if (
      invoice.status !== InvoiceStatus.UNPAID &&
      invoice.status !== InvoiceStatus.OVERDUE
    ) {
      throw new ConflictException('Hóa đơn không thể thanh toán lúc này.');
    }

    const amount = invoice.totalAmount.toNumber();
    if (!Number.isSafeInteger(amount) || amount < 5000) {
      throw new BadRequestException(
        'VNPAY chỉ nhận số tiền VND nguyên và tối thiểu 5.000 đồng.',
      );
    }

    const pending = invoice.payments[0];
    if (pending && pending.method !== PaymentMethod.VNPAY) {
      throw new ConflictException(
        'Hóa đơn đang có giao dịch chuyển khoản chờ kế toán xác nhận.',
      );
    }
    if (pending) {
      await this.prisma.payment.update({
        where: { id: pending.id },
        data: {
          status: PaymentStatus.CANCELLED,
          note: 'Đã thay bằng một phiên thanh toán VNPAY mới.',
        },
      });
    }

    const transactionReference = `H${Date.now()}${randomBytes(4).toString('hex')}`;
    await this.prisma.payment.create({
      data: {
        invoiceId: invoice.id,
        recordedById: actor.id,
        amount: invoice.totalAmount,
        method: PaymentMethod.VNPAY,
        status: PaymentStatus.PENDING,
        transactionCode: transactionReference,
        paidAt: null,
        note: 'Đã khởi tạo phiên thanh toán VNPAY.',
      },
    });

    const createdAt = new Date();
    const expiresAt = new Date(createdAt.getTime() + 15 * 60 * 1000);
    const params: Record<string, string> = {
      vnp_Version: '2.1.0',
      vnp_Command: 'pay',
      vnp_TmnCode: this.tmnCode!,
      vnp_Amount: String(amount * 100),
      vnp_CurrCode: 'VND',
      vnp_TxnRef: transactionReference,
      vnp_OrderInfo: `Thanh toan hoa don ${invoice.code}`,
      vnp_OrderType: 'other',
      vnp_Locale: 'vn',
      vnp_ReturnUrl: this.returnUrl,
      vnp_IpAddr: this.normalizeIp(ipAddress),
      vnp_CreateDate: this.vietnamDate(createdAt),
      vnp_ExpireDate: this.vietnamDate(expiresAt),
    };
    const signData = this.queryString(params);
    const secureHash = this.sign(signData);
    return {
      paymentUrl: `${this.paymentUrl}?${signData}&vnp_SecureHash=${secureHash}`,
      transactionReference,
      expiresAt,
      provider: 'VNPAY',
    };
  }

  async processCallback(query: VnpayQuery): Promise<VnpayCallbackResult> {
    const verified = await this.verifyCallback(query);
    if (!('params' in verified)) return verified;
    const { params, payment } = verified;

    if (
      payment.status === PaymentStatus.CONFIRMED ||
      payment.invoice.status === InvoiceStatus.PAID
    ) {
      return {
        RspCode: '02',
        Message: 'Order already confirmed',
        successful: true,
        invoiceId: payment.invoice.id,
        invoiceCode: payment.invoice.code,
        amount: payment.amount.toNumber(),
      };
    }
    if (payment.invoice.status === InvoiceStatus.CANCELLED ||
        payment.status === PaymentStatus.CANCELLED) {
      return {
        RspCode: '02',
        Message: 'Order cancelled',
        successful: false,
        invoiceId: payment.invoice.id,
        invoiceCode: payment.invoice.code,
        amount: payment.amount.toNumber(),
      };
    }

    const successful =
      params.vnp_ResponseCode === '00' && params.vnp_TransactionStatus === '00';
    const gatewayTransaction = params.vnp_TransactionNo ?? 'không có';
    if (!successful) {
      await this.prisma.payment.update({
        where: { id: payment.id },
        data: {
          status: PaymentStatus.CANCELLED,
          note: `VNPAY từ chối hoặc hủy giao dịch (mã ${params.vnp_ResponseCode ?? 'không rõ'}).`,
        },
      });
      await this.notifications.notifyUser(payment.invoice.payerId, {
        title: 'Thanh toán VNPAY chưa thành công',
        message: `Hóa đơn ${payment.invoice.code} chưa được thanh toán. Bạn có thể thử lại.`,
        type: NotificationType.INVOICE,
        referenceType: 'invoice',
        referenceId: payment.invoice.id,
      });
      return {
        RspCode: '00',
        Message: 'Confirm success',
        successful: false,
        invoiceId: payment.invoice.id,
        invoiceCode: payment.invoice.code,
        amount: payment.amount.toNumber(),
      };
    }

    const paidAt = this.parseVnpayDate(params.vnp_PayDate) ?? new Date();
    await this.prisma.$transaction([
      this.prisma.payment.update({
        where: { id: payment.id },
        data: {
          status: PaymentStatus.CONFIRMED,
          paidAt,
          confirmedAt: new Date(),
          note: `VNPAY đã xác nhận. Mã giao dịch cổng: ${gatewayTransaction}.`,
        },
      }),
      this.prisma.invoice.update({
        where: { id: payment.invoiceId },
        data: { status: InvoiceStatus.PAID, paidAt },
      }),
    ]);
    await this.notifications.notifyUser(payment.invoice.payerId, {
      title: 'Thanh toán VNPAY thành công',
      message: `Hóa đơn ${payment.invoice.code} đã được thanh toán thành công.`,
      type: NotificationType.INVOICE,
      referenceType: 'invoice',
      referenceId: payment.invoice.id,
    });
    return {
      RspCode: '00',
      Message: 'Confirm success',
      successful: true,
      invoiceId: payment.invoice.id,
      invoiceCode: payment.invoice.code,
      amount: payment.amount.toNumber(),
    };
  }

  async inspectReturn(query: VnpayQuery): Promise<VnpayCallbackResult> {
    const verified = await this.verifyCallback(query);
    if (!('params' in verified)) return verified;
    const { params, payment } = verified;
    const providerSucceeded =
      params.vnp_ResponseCode === '00' && params.vnp_TransactionStatus === '00';
    const confirmed =
      payment.status === PaymentStatus.CONFIRMED &&
      payment.invoice.status === InvoiceStatus.PAID;
    return {
      RspCode: '00',
      Message: confirmed
        ? 'Payment confirmed'
        : providerSucceeded
          ? 'Waiting for IPN confirmation'
          : 'Payment failed',
      successful: confirmed,
      awaitingConfirmation: providerSucceeded && !confirmed,
      invoiceId: payment.invoice.id,
      invoiceCode: payment.invoice.code,
      amount: payment.amount.toNumber(),
    };
  }

  processReturn(query: VnpayQuery): Promise<VnpayCallbackResult> {
    return this.sandboxReturnConfirmation
      ? this.processCallback(query)
      : this.inspectReturn(query);
  }

  private async verifyCallback(
    query: VnpayQuery,
  ): Promise<VerifiedCallback | VnpayCallbackResult> {
    if (!this.tmnCode || !this.hashSecret) {
      return {
        RspCode: '99',
        Message: 'Merchant is not configured',
        successful: false,
      };
    }
    const params = this.normalizeQuery(query);
    const receivedHash = params.vnp_SecureHash;
    delete params.vnp_SecureHash;
    delete params.vnp_SecureHashType;

    if (
      !receivedHash ||
      !this.validHash(this.queryString(params), receivedHash)
    ) {
      return {
        RspCode: '97',
        Message: 'Invalid checksum',
        successful: false,
      };
    }
    if (params.vnp_TmnCode !== this.tmnCode) {
      return {
        RspCode: '97',
        Message: 'Invalid merchant',
        successful: false,
      };
    }

    const reference = params.vnp_TxnRef;
    const payment = reference
      ? await this.prisma.payment.findUnique({
          where: { transactionCode: reference },
          include: { invoice: true },
        })
      : null;
    if (!payment || payment.method !== PaymentMethod.VNPAY) {
      return {
        RspCode: '01',
        Message: 'Order not found',
        successful: false,
      };
    }

    const expectedAmount = String(payment.amount.toNumber() * 100);
    if (params.vnp_Amount !== expectedAmount) {
      return {
        RspCode: '04',
        Message: 'Invalid amount',
        successful: false,
        invoiceId: payment.invoice.id,
        invoiceCode: payment.invoice.code,
      };
    }
    return { params, payment };
  }

  renderReturnPage(result: VnpayCallbackResult): string {
    return renderVnpayReturnPage(result);
  }

  private assertConfigured(): void {
    if (!this.tmnCode || !this.hashSecret) {
      throw new ServiceUnavailableException(
        'VNPAY chưa được cấu hình trên máy chủ.',
      );
    }
  }

  private normalizeQuery(query: VnpayQuery): Record<string, string> {
    return Object.fromEntries(
      Object.entries(query)
        .filter(([key, value]) => key.startsWith('vnp_') && value != null)
        .map(([key, value]) => [
          key,
          Array.isArray(value) ? (value[0] ?? '') : value!,
        ]),
    );
  }

  private queryString(params: Record<string, string>): string {
    const sorted = Object.entries(params).sort(([left], [right]) =>
      left.localeCompare(right),
    );
    return new URLSearchParams(sorted).toString();
  }

  private sign(data: string): string {
    return createHmac('sha512', this.hashSecret!).update(data).digest('hex');
  }

  private validHash(data: string, receivedHash: string): boolean {
    const expected = Buffer.from(this.sign(data).toLowerCase(), 'utf8');
    const received = Buffer.from(receivedHash.toLowerCase(), 'utf8');
    return (
      expected.length === received.length && timingSafeEqual(expected, received)
    );
  }

  private normalizeIp(value: string): string {
    if (!value || value === '::1') return '127.0.0.1';
    return value.replace(/^::ffff:/, '');
  }

  private vietnamDate(value: Date): string {
    const parts = new Intl.DateTimeFormat('en-GB', {
      timeZone: 'Asia/Ho_Chi_Minh',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hourCycle: 'h23',
    })
      .formatToParts(value)
      .reduce<Record<string, string>>((result, part) => {
        result[part.type] = part.value;
        return result;
      }, {});
    return `${parts.year}${parts.month}${parts.day}${parts.hour}${parts.minute}${parts.second}`;
  }

  private parseVnpayDate(value?: string): Date | null {
    if (!value || !/^\d{14}$/.test(value)) return null;
    const year = Number(value.slice(0, 4));
    const month = Number(value.slice(4, 6));
    const day = Number(value.slice(6, 8));
    const hour = Number(value.slice(8, 10));
    const minute = Number(value.slice(10, 12));
    const second = Number(value.slice(12, 14));
    return new Date(Date.UTC(year, month - 1, day, hour - 7, minute, second));
  }
}
