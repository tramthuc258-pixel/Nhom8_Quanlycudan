import { createHmac } from 'node:crypto';
import type { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import {
  InvoiceStatus,
  PaymentMethod,
  PaymentStatus,
  Prisma,
  RoleCode,
  UserStatus,
} from '../generated/prisma/client';
import { NotificationsService } from '../notifications/notifications.service';
import { VnpayService } from './vnpay.service';

describe('VnpayService', () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    process.env.VNPAY_TMN_CODE = 'HOMIETEST';
    process.env.VNPAY_HASH_SECRET = 'test-secret-for-vnpay';
    process.env.VNPAY_RETURN_URL =
      'http://localhost:3000/api/payments/vnpay/return';
    process.env.VNPAY_PAYMENT_URL =
      'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
    process.env.VNPAY_SANDBOX_RETURN_CONFIRMATION = 'false';
  });

  afterEach(() => {
    process.env = { ...originalEnv };
    jest.restoreAllMocks();
  });

  it('tạo URL sandbox có số tiền, mã merchant và checksum', async () => {
    const paymentCreate = jest.fn().mockResolvedValue({});
    const prisma = {
      invoice: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'invoice-1',
          code: 'HD-2026-001',
          payerId: 'resident-1',
          status: InvoiceStatus.UNPAID,
          totalAmount: new Prisma.Decimal(180000),
          apartment: { id: 'apartment-1' },
          payments: [],
        }),
      },
      payment: { create: paymentCreate, update: jest.fn() },
    } as unknown as PrismaService;
    const service = new VnpayService(prisma, {} as NotificationsService);

    const result = (await service.createPaymentUrl(
      'invoice-1',
      actor,
      '::1',
    )) as { paymentUrl: string };
    const url = new URL(result.paymentUrl);

    expect(url.origin + url.pathname).toBe(
      'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
    );
    expect(url.searchParams.get('vnp_TmnCode')).toBe('HOMIETEST');
    expect(url.searchParams.get('vnp_Amount')).toBe('18000000');
    expect(url.searchParams.get('vnp_IpAddr')).toBe('127.0.0.1');
    expect(url.searchParams.get('vnp_SecureHash')).toMatch(/^[a-f0-9]{128}$/);
    expect(paymentCreate).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          method: PaymentMethod.VNPAY,
          status: PaymentStatus.PENDING,
          paidAt: null,
        }),
      }),
    );
  });

  it('xác minh callback và đánh dấu hóa đơn đã thanh toán', async () => {
    const paymentUpdate = jest.fn().mockResolvedValue({});
    const invoiceUpdate = jest.fn().mockResolvedValue({});
    const notifyUser = jest.fn().mockResolvedValue(undefined);
    const prisma = {
      payment: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'payment-1',
          invoiceId: 'invoice-1',
          amount: new Prisma.Decimal(180000),
          method: PaymentMethod.VNPAY,
          status: PaymentStatus.PENDING,
          invoice: {
            id: 'invoice-1',
            code: 'HD-2026-001',
            payerId: 'resident-1',
            status: InvoiceStatus.UNPAID,
          },
        }),
        update: paymentUpdate,
      },
      invoice: { update: invoiceUpdate },
      $transaction: jest.fn().mockResolvedValue([]),
    } as unknown as PrismaService;
    const notifications = { notifyUser } as unknown as NotificationsService;
    const service = new VnpayService(prisma, notifications);
    const params: Record<string, string> = {
      vnp_Amount: '18000000',
      vnp_PayDate: '20261031103000',
      vnp_ResponseCode: '00',
      vnp_TmnCode: 'HOMIETEST',
      vnp_TransactionNo: '14582999',
      vnp_TransactionStatus: '00',
      vnp_TxnRef: 'H1761880000abcd',
    };
    const signData = new URLSearchParams(
      Object.entries(params).sort(([left], [right]) =>
        left.localeCompare(right),
      ),
    ).toString();
    params.vnp_SecureHash = createHmac('sha512', 'test-secret-for-vnpay')
      .update(signData)
      .digest('hex');

    await expect(service.processCallback(params)).resolves.toMatchObject({
      RspCode: '00',
      successful: true,
      invoiceCode: 'HD-2026-001',
    });
    expect(paymentUpdate).toHaveBeenCalled();
    expect(invoiceUpdate).toHaveBeenCalled();
    expect(notifyUser).toHaveBeenCalledWith(
      'resident-1',
      expect.objectContaining({ title: 'Thanh toán VNPAY thành công' }),
    );
  });

  it('Return chỉ hiển thị trạng thái chờ IPN và không cập nhật hóa đơn', async () => {
    const paymentUpdate = jest.fn();
    const invoiceUpdate = jest.fn();
    const notifyUser = jest.fn();
    const prisma = {
      payment: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'payment-1',
          invoiceId: 'invoice-1',
          amount: new Prisma.Decimal(180000),
          method: PaymentMethod.VNPAY,
          status: PaymentStatus.PENDING,
          invoice: {
            id: 'invoice-1',
            code: 'HD-2026-001',
            payerId: 'resident-1',
            status: InvoiceStatus.UNPAID,
          },
        }),
        update: paymentUpdate,
      },
      invoice: { update: invoiceUpdate },
    } as unknown as PrismaService;
    const service = new VnpayService(prisma, {
      notifyUser,
    } as unknown as NotificationsService);
    const params: Record<string, string> = {
      vnp_Amount: '18000000',
      vnp_ResponseCode: '00',
      vnp_TmnCode: 'HOMIETEST',
      vnp_TransactionStatus: '00',
      vnp_TxnRef: 'H1761880000abcd',
    };
    const signData = new URLSearchParams(
      Object.entries(params).sort(([left], [right]) =>
        left.localeCompare(right),
      ),
    ).toString();
    params.vnp_SecureHash = createHmac('sha512', 'test-secret-for-vnpay')
      .update(signData)
      .digest('hex');

    const result = await service.processReturn(params);

    expect(result).toMatchObject({
      successful: false,
      awaitingConfirmation: true,
      invoiceCode: 'HD-2026-001',
    });
    expect(service.renderReturnPage(result)).toContain(
      'Đang xác nhận thanh toán',
    );
    expect(paymentUpdate).not.toHaveBeenCalled();
    expect(invoiceUpdate).not.toHaveBeenCalled();
    expect(notifyUser).not.toHaveBeenCalled();
  });

  it('chỉ bật xác nhận qua Return trong Sandbox khi cấu hình rõ', async () => {
    process.env.VNPAY_SANDBOX_RETURN_CONFIRMATION = 'true';
    const service = new VnpayService(
      {} as PrismaService,
      {} as NotificationsService,
    );
    const result = {
      RspCode: '00',
      Message: 'Confirm success',
      successful: true,
    };
    const confirm = jest
      .spyOn(service, 'processCallback')
      .mockResolvedValue(result);

    await expect(service.processReturn({})).resolves.toBe(result);
    expect(confirm).toHaveBeenCalledTimes(1);

    process.env.VNPAY_PAYMENT_URL = 'https://pay.example.com/payment';
    const productionService = new VnpayService(
      {} as PrismaService,
      {} as NotificationsService,
    );
    const inspect = jest
      .spyOn(productionService, 'inspectReturn')
      .mockResolvedValue(result);
    await expect(productionService.processReturn({})).resolves.toBe(result);
    expect(inspect).toHaveBeenCalledTimes(1);
  });
});

const actor: AuthenticatedUser = {
  id: 'resident-1',
  email: 'resident@homie.com',
  fullName: 'Nguyễn Văn An',
  phone: null,
  dateOfBirth: null,
  contactAddress: null,
  avatarUrl: null,
  apartmentCode: 'A-0101',
  status: UserStatus.ACTIVE,
  mustChangePassword: false,
  roles: [RoleCode.RESIDENT],
};
