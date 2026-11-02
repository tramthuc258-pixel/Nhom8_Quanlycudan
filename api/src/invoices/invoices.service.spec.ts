import type { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import {
  InvoiceStatus,
  PaymentMethod,
  PaymentStatus,
  RoleCode,
  UserStatus,
} from '../generated/prisma/client';
import { NotificationsService } from '../notifications/notifications.service';
import { InvoicesService } from './invoices.service';
import { BuildingAccessService } from '../building-access/building-access.service';
import type { CreateInvoiceDto } from './dto/create-invoice.dto';

describe('InvoicesService privacy', () => {
  it('cư dân chỉ nhận hóa đơn được giao cho chính mình thanh toán', async () => {
    const findMany = jest.fn().mockResolvedValue([]);
    const prisma = { invoice: { findMany } } as unknown as PrismaService;
    const service = new InvoicesService(
      prisma,
      {} as NotificationsService,
      {} as BuildingAccessService,
    );
    const user: AuthenticatedUser = {
      id: '56a15a1f-77df-46bd-aebb-2145146cf099',
      email: 'anh.resident@homie.com',
      fullName: 'Cư dân Homie',
      phone: null,
      dateOfBirth: null,
      contactAddress: null,
      apartmentCode: null,
      status: UserStatus.ACTIVE,
      mustChangePassword: false,
      roles: [RoleCode.RESIDENT],
    };

    await service.findAll(user);

    expect(findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { payerId: user.id, status: { not: InvoiceStatus.DRAFT } },
      }),
    );
  });

  it('không cho giao hóa đơn cho chủ sở hữu khi căn có người thuê đang hiệu lực', async () => {
    const ownerId = '56a15a1f-77df-46bd-aebb-2145146cf099';
    const tenantId = 'a41b248a-065a-4e74-a959-e1600dc1dc20';
    const apartmentId = '0c2f3c91-2f7a-4236-b259-cdd57dd4924e';
    const findFirst = jest.fn().mockResolvedValue({ userId: tenantId });
    const prisma = {
      apartment: {
        findUnique: jest
          .fn()
          .mockResolvedValue({ area: { toNumber: () => 70 } }),
      },
      apartmentMembership: { findFirst },
    } as unknown as PrismaService;
    const service = new InvoicesService(
      prisma,
      {} as NotificationsService,
      {
        assertApartmentAccess: jest.fn().mockResolvedValue(undefined),
      } as unknown as BuildingAccessService,
    );
    const accountant = {
      id: 'e4a30671-47f6-42e6-b397-0e120f6481f9',
    } as AuthenticatedUser;
    const dto = {
      apartmentId,
      payerResidentId: ownerId,
      billingMonth: '2026-11-01',
      dueDate: '2026-11-10',
      publish: true,
      items: [{ name: 'Phí quản lý', quantity: 1, unitPrice: 100000 }],
    } satisfies CreateInvoiceDto;

    await expect(service.create(accountant, dto)).rejects.toThrow(
      'Người thanh toán phải là người thuê đang hiệu lực',
    );
    expect(findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ type: 'TENANT' }),
      }),
    );
  });

  it('chỉ bật chuyển khoản khi đủ thông tin tài khoản nhận tiền', () => {
    const previous = {
      bank: process.env.BANK_TRANSFER_BANK_NAME,
      number: process.env.BANK_TRANSFER_ACCOUNT_NUMBER,
      name: process.env.BANK_TRANSFER_ACCOUNT_NAME,
    };
    process.env.BANK_TRANSFER_BANK_NAME = 'Ngân hàng kiểm thử';
    process.env.BANK_TRANSFER_ACCOUNT_NUMBER = '0123456789';
    process.env.BANK_TRANSFER_ACCOUNT_NAME = 'BAN QUAN LY HOMIE';
    const service = new InvoicesService(
      {} as PrismaService,
      {} as NotificationsService,
      {} as BuildingAccessService,
    );

    expect(service.paymentOptions()).toMatchObject({
      bankTransfer: {
        enabled: true,
        bankName: 'Ngân hàng kiểm thử',
        accountNumber: '0123456789',
        accountName: 'BAN QUAN LY HOMIE',
        transferContentPrefix: 'HOMIE',
      },
    });

    if (previous.bank === undefined) delete process.env.BANK_TRANSFER_BANK_NAME;
    else process.env.BANK_TRANSFER_BANK_NAME = previous.bank;
    if (previous.number === undefined)
      delete process.env.BANK_TRANSFER_ACCOUNT_NUMBER;
    else process.env.BANK_TRANSFER_ACCOUNT_NUMBER = previous.number;
    if (previous.name === undefined)
      delete process.env.BANK_TRANSFER_ACCOUNT_NAME;
    else process.env.BANK_TRANSFER_ACCOUNT_NAME = previous.name;
  });

  it('kế toán không thể xác nhận thủ công phiên VNPAY đang chờ', async () => {
    const invoice = {
      apartmentId: '0c2f3c91-2f7a-4236-b259-cdd57dd4924e',
      status: InvoiceStatus.UNPAID,
      payments: [
        {
          id: '28b26317-752a-4621-9b29-1843dc8e2eac',
          method: PaymentMethod.VNPAY,
          status: PaymentStatus.PENDING,
          proofUrl: null,
        },
      ],
    };
    const prisma = {
      invoice: { findUnique: jest.fn().mockResolvedValue(invoice) },
      payment: { update: jest.fn() },
    } as unknown as PrismaService;
    const service = new InvoicesService(
      prisma,
      {} as NotificationsService,
      {
        assertApartmentAccess: jest.fn().mockResolvedValue(undefined),
      } as unknown as BuildingAccessService,
    );

    await expect(
      service.confirmPayment('a3547121-1477-42ad-a84a-a15ddfa490c4', {
        id: 'e4a30671-47f6-42e6-b397-0e120f6481f9',
      } as AuthenticatedUser),
    ).rejects.toThrow('Không có biên lai chuyển khoản chờ đối soát.');
    expect(prisma.payment.update).not.toHaveBeenCalled();
  });
});

describe('InvoicesService service billing', () => {
  const apartmentId = '0c2f3c91-2f7a-4236-b259-cdd57dd4924e';
  const payerId = 'a41b248a-065a-4e74-a959-e1600dc1dc20';
  const requestId = '83ad28eb-feb9-4d49-8cf6-6203fd9d2b68';
  const actor = { id: 'e4a30671-47f6-42e6-b397-0e120f6481f9' } as AuthenticatedUser;
  const dto: CreateInvoiceDto = {
    apartmentId,
    payerResidentId: payerId,
    billingMonth: '2026-11-01',
    dueDate: '2026-12-10',
    publish: false,
    items: [{ name: 'Phí quản lý', quantity: 1, unitPrice: 100000 }],
    serviceRequestIds: [requestId],
  };

  function setup(claimedCount: number) {
    const request = {
      id: requestId,
      code: 'DV-TEST',
      apartmentId,
      requestedById: payerId,
      quantity: { toNumber: () => 2 },
      unitPrice: { toNumber: () => 35000 },
      service: { name: 'Vệ sinh' },
    };
    const create = jest.fn().mockResolvedValue({ id: 'invoice-id' });
    const updateMany = jest.fn().mockResolvedValue({ count: claimedCount });
    const prisma = {
      apartment: { findUnique: jest.fn().mockResolvedValue({ area: { toNumber: () => 70 } }) },
      apartmentMembership: { findFirst: jest.fn().mockResolvedValue({ userId: payerId }) },
      serviceRequest: { findMany: jest.fn().mockResolvedValue([request]) },
      invoice: { findUnique: jest.fn().mockResolvedValue({
        id: 'invoice-id', code: 'HD-TEST', apartmentId, payerId,
        billingMonth: new Date('2026-11-01'), issuedAt: new Date(),
        dueDate: new Date('2026-12-10'), status: InvoiceStatus.DRAFT,
        createdBy: null, publishedBy: null, createdById: actor.id,
        publishedById: null, publishedAt: null, paidAt: null,
        payments: [], items: [{
          id: 'item-id', feeTypeId: null, feeType: null,
          serviceRequest: { id: requestId, code: 'DV-TEST' },
          name: 'Vệ sinh · DV-TEST', quantity: { toNumber: () => 2 },
          unitPrice: { toNumber: () => 35000 },
        }],
      }) },
      $transaction: jest.fn(async (callback: (tx: unknown) => Promise<unknown>) =>
        callback({ invoice: { create }, serviceRequest: { updateMany } })),
    } as unknown as PrismaService;
    const service = new InvoicesService(
      prisma,
      {} as NotificationsService,
      { assertApartmentAccess: jest.fn() } as unknown as BuildingAccessService,
    );
    return { service, prisma, create, updateMany };
  }

  it('lấy đơn giá đã đặt và liên kết đúng đơn dịch vụ vào hóa đơn', async () => {
    const { service, create, updateMany } = setup(1);
    const result = await service.create(actor, dto) as { items: Array<{ source: string; serviceRequestId: string }> };
    const input = create.mock.calls[0][0] as { data: { totalAmount: number; items: { create: Array<{ unitPrice: number }> } } };
    expect(input.data.totalAmount).toBe(170000);
    expect(input.data.items.create[1].unitPrice).toBe(35000);
    expect(updateMany).toHaveBeenCalledWith(expect.objectContaining({
      where: expect.objectContaining({ id: requestId, apartmentId, requestedById: payerId, billedInvoiceItemId: null }),
    }));
    expect(result.items[0]).toMatchObject({ source: 'service', serviceRequestId: requestId });
  });

  it('từ chối khi đơn dịch vụ vừa bị hóa đơn khác lấy', async () => {
    const { service } = setup(0);
    await expect(service.create(actor, dto)).rejects.toThrow('vừa được tính vào hóa đơn khác');
  });
});
