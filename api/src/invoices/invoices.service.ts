import { randomUUID } from 'node:crypto';
import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import {
  FeeCalculationType,
  InvoiceStatus,
  MembershipStatus,
  NotificationType,
  PaymentMethod,
  PaymentStatus,
  Prisma,
  RoleCode,
  ServiceRequestStatus,
} from '../generated/prisma/client';
import { NotificationsService } from '../notifications/notifications.service';
import type { CreateInvoiceDto } from './dto/create-invoice.dto';
import type { SubmitPaymentDto } from './dto/submit-payment.dto';
import type { RejectPaymentDto } from './dto/reject-payment.dto';
import { BuildingAccessService } from '../building-access/building-access.service';

const invoiceInclude = {
  apartment: { include: { building: true } },
  createdBy: true,
  publishedBy: true,
  items: { include: { feeType: true, serviceRequest: { select: { id: true, code: true } } } },
  payments: {
    include: { recordedBy: true, confirmedBy: true },
    orderBy: { createdAt: 'desc' as const },
  },
} satisfies Prisma.InvoiceInclude;

type InvoiceWithDetails = Prisma.InvoiceGetPayload<{
  include: typeof invoiceInclude;
}>;

@Injectable()
export class InvoicesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly buildingAccess: BuildingAccessService,
  ) {}

  paymentOptions(): object {
    const bankName = process.env.BANK_TRANSFER_BANK_NAME?.trim() ?? '';
    const bankId = process.env.BANK_TRANSFER_BANK_ID?.trim() ?? '';
    const accountNumber =
      process.env.BANK_TRANSFER_ACCOUNT_NUMBER?.trim() ?? '';
    const accountName = process.env.BANK_TRANSFER_ACCOUNT_NAME?.trim() ?? '';
    const branch = process.env.BANK_TRANSFER_BRANCH?.trim() || null;
    const qrImageUrl = process.env.BANK_TRANSFER_QR_URL?.trim() || null;
    const transferContentPrefix =
      process.env.BANK_TRANSFER_CONTENT_PREFIX?.trim() || 'HOMIE';
    return {
      bankTransfer: {
        enabled: Boolean(bankName && accountNumber && accountName),
        bankName,
        bankId,
        accountNumber,
        accountName,
        branch,
        qrImageUrl,
        transferContentPrefix,
      },
      vnpay: {
        enabled: Boolean(
          process.env.VNPAY_TMN_CODE?.trim() &&
          process.env.VNPAY_HASH_SECRET?.trim(),
        ),
      },
    };
  }

  async findAll(user: AuthenticatedUser): Promise<object> {
    const invoices = await this.prisma.invoice.findMany({
      where: await this.invoiceWhere(user),
      include: invoiceInclude,
      orderBy: [{ billingMonth: 'desc' }, { issuedAt: 'desc' }],
    });
    return { items: invoices.map((invoice) => this.response(invoice)) };
  }

  async findFeeTypes(): Promise<object> {
    const items = await this.prisma.feeType.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });
    return {
      items: items.map((item) => ({
        id: item.id,
        code: item.code,
        name: item.name,
        description: item.description,
        calculationType: item.calculationType.toLowerCase(),
        defaultUnitPrice: item.defaultUnitPrice.toNumber(),
      })),
    };
  }

  async findUnbilledServices(user: AuthenticatedUser): Promise<object> {
    const buildingIds = await this.buildingAccess.accessibleStaffBuildingIds(user);
    const requests = await this.prisma.serviceRequest.findMany({
      where: {
        status: ServiceRequestStatus.COMPLETED,
        billedInvoiceItemId: null,
        unitPrice: { gt: 0 },
        ...(buildingIds === null
          ? {}
          : { apartment: { buildingId: { in: buildingIds } } }),
      },
      include: { service: { select: { name: true } } },
      orderBy: { completedAt: 'asc' },
    });
    return {
      items: requests.map((request) => ({
        id: request.id,
        code: request.code,
        apartmentId: request.apartmentId,
        requestedById: request.requestedById,
        serviceName: request.service.name,
        quantity: request.quantity.toNumber(),
        unitPrice: request.unitPrice.toNumber(),
        completedAt: request.completedAt,
      })),
    };
  }

  async create(
    user: AuthenticatedUser,
    dto: CreateInvoiceDto,
  ): Promise<object> {
    await this.buildingAccess.assertApartmentAccess(user, dto.apartmentId);
    const apartment = await this.prisma.apartment.findUnique({
      where: { id: dto.apartmentId },
      select: { area: true },
    });
    if (!apartment) throw new NotFoundException('Không tìm thấy căn hộ.');
    const activeTenant = await this.prisma.apartmentMembership.findFirst({
      where: {
        apartmentId: dto.apartmentId,
        status: MembershipStatus.ACTIVE,
        type: 'TENANT',
      },
      select: { userId: true },
      orderBy: [{ isPrimary: 'desc' }, { startDate: 'desc' }],
    });
    const payerMembership =
      activeTenant ??
      (await this.prisma.apartmentMembership.findFirst({
        where: {
          apartmentId: dto.apartmentId,
          status: MembershipStatus.ACTIVE,
          type: 'OWNER',
        },
        select: { userId: true },
        orderBy: [{ isPrimary: 'desc' }, { startDate: 'desc' }],
      }));
    if (!payerMembership) {
      throw new ConflictException(
        'Căn hộ chưa có chủ sở hữu hoặc người thuê đang hiệu lực để nhận hóa đơn.',
      );
    }
    const payerResidentId = payerMembership.userId;
    if (dto.payerResidentId !== payerResidentId) {
      throw new ConflictException(
        'Người thanh toán phải là người thuê đang hiệu lực; nếu không có người thuê thì là chủ sở hữu.',
      );
    }

    const billingDate = new Date(dto.billingMonth);
    const billingMonth = new Date(
      Date.UTC(billingDate.getUTCFullYear(), billingDate.getUTCMonth(), 1),
    );
    const feeTypeIds = dto.items
      .map((item) => item.feeTypeId)
      .filter((id): id is string => Boolean(id));
    const feeTypes = feeTypeIds.length
      ? await this.prisma.feeType.findMany({
          where: { id: { in: feeTypeIds }, isActive: true },
        })
      : [];
    if (new Set(feeTypeIds).size !== feeTypes.length) {
      throw new ConflictException(
        'Một hoặc nhiều loại phí không tồn tại hoặc đã ngừng sử dụng.',
      );
    }
    const feeTypeById = new Map(feeTypes.map((item) => [item.id, item]));
    const normalizedItems = dto.items.map((item) => {
      const feeType = item.feeTypeId
        ? feeTypeById.get(item.feeTypeId)
        : undefined;
      const quantity =
        feeType?.calculationType === FeeCalculationType.FIXED
          ? 1
          : feeType?.calculationType === FeeCalculationType.BY_AREA
            ? apartment.area.toNumber()
            : item.quantity;
      const unitPrice = feeType?.defaultUnitPrice.toNumber() ?? item.unitPrice;
      return {
        feeTypeId: feeType?.id,
        name: feeType?.name ?? item.name.trim(),
        quantity,
        unitPrice,
        amount: quantity * unitPrice,
      };
    });
    const serviceRequestIds = dto.serviceRequestIds ?? [];
    if (new Set(serviceRequestIds).size !== serviceRequestIds.length) {
      throw new ConflictException('Một đơn dịch vụ chỉ được chọn một lần.');
    }
    const nextBillingMonth = new Date(Date.UTC(
      billingMonth.getUTCFullYear(), billingMonth.getUTCMonth() + 1, 1, -7,
    ));
    const serviceRequests = serviceRequestIds.length
      ? await this.prisma.serviceRequest.findMany({
          where: {
            id: { in: serviceRequestIds },
            apartmentId: dto.apartmentId,
            requestedById: payerResidentId,
            status: ServiceRequestStatus.COMPLETED,
            billedInvoiceItemId: null,
            unitPrice: { gt: 0 },
            completedAt: { lt: nextBillingMonth },
          },
          include: { service: { select: { name: true } } },
        })
      : [];
    if (serviceRequests.length !== serviceRequestIds.length) {
      throw new ConflictException(
        'Đơn dịch vụ phải hoàn thành, chưa được tính phí, thuộc đúng căn hộ và người thanh toán trong kỳ.',
      );
    }
    const serviceItems = serviceRequests.map((request) => ({
      id: randomUUID(),
      name: `${request.service.name} · ${request.code}`,
      quantity: request.quantity.toNumber(),
      unitPrice: request.unitPrice.toNumber(),
      amount: request.quantity.toNumber() * request.unitPrice.toNumber(),
      requestId: request.id,
    }));
    const totalAmount = normalizedItems.reduce(
      (total, item) => total + item.amount,
      0,
    ) + serviceItems.reduce((total, item) => total + item.amount, 0);
    const now = new Date();
    const code = `HD-${billingMonth.getUTCFullYear()}${String(
      billingMonth.getUTCMonth() + 1,
    ).padStart(2, '0')}-${randomUUID().slice(0, 6).toUpperCase()}`;

    try {
      const invoice = await this.prisma.$transaction(async (tx) => {
        const created = await tx.invoice.create({
        data: {
          code,
          apartmentId: dto.apartmentId,
          payerId: payerResidentId,
          createdById: user.id,
          publishedById: dto.publish ? user.id : null,
          billingMonth,
          issuedAt: now,
          publishedAt: dto.publish ? now : null,
          dueDate: new Date(dto.dueDate),
          status: dto.publish ? InvoiceStatus.UNPAID : InvoiceStatus.DRAFT,
          totalAmount,
          items: {
            create: [
              ...normalizedItems,
              ...serviceItems.map(({ requestId, ...item }) => item),
            ],
          },
        },
        include: invoiceInclude,
      });
        for (const item of serviceItems) {
          const claimed = await tx.serviceRequest.updateMany({
            where: {
              id: item.requestId,
              apartmentId: dto.apartmentId,
              requestedById: payerResidentId,
              status: ServiceRequestStatus.COMPLETED,
              billedInvoiceItemId: null,
              unitPrice: { gt: 0 },
              completedAt: { lt: nextBillingMonth },
            },
            data: { billedInvoiceItemId: item.id },
          });
          if (claimed.count !== 1) {
            throw new ConflictException('Đơn dịch vụ vừa được tính vào hóa đơn khác. Hãy tải lại danh sách.');
          }
        }
        return created;
      });
      if (dto.publish) {
        await this.notifications.notifyUser(payerResidentId, {
          title: 'Hóa đơn mới đã được phát hành',
          message: `Hóa đơn ${invoice.code} có tổng tiền ${totalAmount.toLocaleString('vi-VN')} đồng.`,
          type: NotificationType.INVOICE,
          referenceType: 'invoice',
          referenceId: invoice.id,
        });
      }
      return this.response(serviceItems.length ? await this.findInvoice(invoice.id) : invoice);
    } catch (error: unknown) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException(
          'Căn hộ đã có hóa đơn trong kỳ này. Hãy hủy hoặc cập nhật hóa đơn hiện có.',
        );
      }
      throw error;
    }
  }

  async publish(id: string, user: AuthenticatedUser): Promise<object> {
    const current = await this.findInvoice(id);
    await this.buildingAccess.assertApartmentAccess(user, current.apartmentId);
    if (current.status !== InvoiceStatus.DRAFT) {
      throw new ConflictException(
        'Chỉ có thể phát hành hóa đơn đang ở trạng thái bản nháp.',
      );
    }
    const updated = await this.prisma.invoice.update({
      where: { id },
      data: {
        status: InvoiceStatus.UNPAID,
        issuedAt: new Date(),
        publishedAt: new Date(),
        publishedById: user.id,
      },
      include: invoiceInclude,
    });
    await this.notifications.notifyUser(updated.payerId, {
      title: 'Hóa đơn mới đã được phát hành',
      message: `Hóa đơn ${updated.code} đã được phát hành và đang chờ thanh toán.`,
      type: NotificationType.INVOICE,
      referenceType: 'invoice',
      referenceId: updated.id,
    });
    return this.response(updated);
  }

  async submitPayment(
    id: string,
    actor: AuthenticatedUser,
    dto: SubmitPaymentDto,
  ): Promise<object> {
    const current = await this.findInvoice(id);
    if (current.payerId !== actor.id) {
      throw new ForbiddenException(
        'Chỉ người chịu trách nhiệm thanh toán mới có thể gửi xác nhận.',
      );
    }
    if (current.status === InvoiceStatus.DRAFT) {
      throw new ConflictException(
        'Hóa đơn phải được phát hành trước khi thanh toán.',
      );
    }
    if (current.status === InvoiceStatus.PAID) {
      throw new ConflictException('Hóa đơn đã được thanh toán trước đó.');
    }
    if (current.status === InvoiceStatus.CANCELLED) {
      throw new ConflictException('Không thể thanh toán hóa đơn đã hủy.');
    }
    if (
      current.payments.some((item) => item.status === PaymentStatus.PENDING)
    ) {
      throw new ConflictException(
        'Biên lai đã được gửi và đang chờ kế toán xác nhận.',
      );
    }

    const storageBaseUrl = process.env.SUPABASE_URL?.replace(/\/$/, '');
    if (
      !storageBaseUrl ||
      !dto.proofUrl.startsWith(`${storageBaseUrl}/storage/v1/`)
    ) {
      throw new ConflictException(
        'Biên lai phải được tải lên Supabase Storage của Homie.',
      );
    }

    const submissionCode =
      `CK-${current.code}-${randomUUID().slice(0, 8)}`.toUpperCase();
    try {
      await this.prisma.payment.create({
        data: {
          invoiceId: id,
          recordedById: actor.id,
          amount: current.totalAmount,
          method: PaymentMethod.BANK_TRANSFER,
          status: PaymentStatus.PENDING,
          transactionCode: submissionCode,
          proofUrl: dto.proofUrl,
          note: 'Cư dân đã tải biên lai, chờ kế toán đối chiếu.',
          paidAt: null,
        },
      });
    } catch (error: unknown) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException('Mã hồ sơ thanh toán đã được sử dụng.');
      }
      throw error;
    }
    await this.notifications.notifyRolesInBuilding(
      [RoleCode.ADMIN, RoleCode.ACCOUNTANT],
      current.apartment.buildingId,
      {
        title: 'Có giao dịch hóa đơn chờ xác nhận',
        message: `${current.code} · căn ${current.apartment.code} đã gửi biên lai chuyển khoản.`,
        type: NotificationType.INVOICE,
        referenceType: 'invoice',
        referenceId: current.id,
      },
      [actor.id],
    );
    return this.response(await this.findInvoice(id));
  }

  async confirmPayment(id: string, actor: AuthenticatedUser): Promise<object> {
    const current = await this.findInvoice(id);
    await this.buildingAccess.assertApartmentAccess(actor, current.apartmentId);
    const payment = current.payments.find(
      (item) =>
        item.status === PaymentStatus.PENDING &&
        item.method === PaymentMethod.BANK_TRANSFER &&
        Boolean(item.proofUrl),
    );
    if (!payment) {
      throw new ConflictException(
        'Không có biên lai chuyển khoản chờ đối soát.',
      );
    }
    if (current.status === InvoiceStatus.PAID) {
      throw new ConflictException('Hóa đơn đã được thanh toán trước đó.');
    }
    const now = new Date();
    await this.prisma.$transaction([
      this.prisma.payment.update({
        where: { id: payment.id },
        data: {
          status: PaymentStatus.CONFIRMED,
          paidAt: now,
          confirmedAt: now,
          confirmedById: actor.id,
        },
      }),
      this.prisma.invoice.update({
        where: { id },
        data: { status: InvoiceStatus.PAID, paidAt: now },
      }),
    ]);
    await this.notifications.notifyUser(current.payerId, {
      title: 'Thanh toán hóa đơn đã được xác nhận',
      message: `Kế toán đã xác nhận giao dịch cho hóa đơn ${current.code}.`,
      type: NotificationType.INVOICE,
      referenceType: 'invoice',
      referenceId: current.id,
    });
    return this.response(await this.findInvoice(id));
  }

  async rejectPayment(
    id: string,
    actor: AuthenticatedUser,
    dto: RejectPaymentDto,
  ): Promise<object> {
    const current = await this.findInvoice(id);
    await this.buildingAccess.assertApartmentAccess(actor, current.apartmentId);
    const payment = current.payments.find(
      (item) =>
        item.status === PaymentStatus.PENDING &&
        item.method === PaymentMethod.BANK_TRANSFER &&
        Boolean(item.proofUrl),
    );
    if (!payment) {
      throw new ConflictException(
        'Không có biên lai chuyển khoản chờ đối soát.',
      );
    }
    await this.prisma.payment.update({
      where: { id: payment.id },
      data: {
        status: PaymentStatus.CANCELLED,
        confirmedAt: new Date(),
        confirmedById: actor.id,
        note: dto.note,
      },
    });
    await this.notifications.notifyUser(current.payerId, {
      title: 'Giao dịch cần được kiểm tra lại',
      message: `Hóa đơn ${current.code}: ${dto.note}`,
      type: NotificationType.INVOICE,
      referenceType: 'invoice',
      referenceId: current.id,
    });
    return this.response(await this.findInvoice(id));
  }

  async cancel(id: string, user: AuthenticatedUser): Promise<object> {
    const current = await this.findInvoice(id);
    await this.buildingAccess.assertApartmentAccess(user, current.apartmentId);
    if (current.status === InvoiceStatus.PAID) {
      throw new ConflictException('Không thể hủy hóa đơn đã thanh toán.');
    }
    if (current.status === InvoiceStatus.CANCELLED) {
      throw new ConflictException('Hóa đơn đã được hủy trước đó.');
    }
    if (current.payments.some((payment) =>
      payment.method === PaymentMethod.VNPAY &&
      payment.status === PaymentStatus.PENDING
    )) {
      throw new ConflictException('Hãy đợi VNPAY trả kết quả trước khi hủy hóa đơn.');
    }
    const updated = await this.prisma.$transaction(async (tx) => {
      const cancelled = await tx.invoice.update({
        where: { id },
        data: { status: InvoiceStatus.CANCELLED, paidAt: null },
        include: invoiceInclude,
      });
      await tx.payment.updateMany({
        where: { invoiceId: id, status: PaymentStatus.PENDING },
        data: { status: PaymentStatus.CANCELLED },
      });
      await tx.serviceRequest.updateMany({
        where: { billedInvoiceItemId: { in: current.items.map((item) => item.id) } },
        data: { billedInvoiceItemId: null },
      });
      return cancelled;
    });
    await this.notifications.notifyUser(updated.payerId, {
      title: 'Hóa đơn đã được hủy',
      message: `Hóa đơn ${updated.code} đã được bộ phận kế toán hủy.`,
      type: NotificationType.INVOICE,
      referenceType: 'invoice',
      referenceId: updated.id,
    });
    return this.response(updated);
  }

  private async findInvoice(id: string): Promise<InvoiceWithDetails> {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id },
      include: invoiceInclude,
    });
    if (!invoice) throw new NotFoundException('Không tìm thấy hóa đơn.');
    return invoice;
  }

  private isFinanceStaff(user: AuthenticatedUser): boolean {
    return user.roles.some((role) =>
      [RoleCode.ADMIN, RoleCode.MANAGEMENT, RoleCode.ACCOUNTANT].some(
        (allowed) => allowed === role,
      ),
    );
  }

  private async invoiceWhere(
    user: AuthenticatedUser,
  ): Promise<Prisma.InvoiceWhereInput> {
    if (!this.isFinanceStaff(user)) return {
      payerId: user.id,
      status: { not: InvoiceStatus.DRAFT },
    };
    if (user.roles.includes(RoleCode.ADMIN)) return {};
    const buildingIds =
      (await this.buildingAccess.accessibleStaffBuildingIds(user)) ?? [];
    return { apartment: { buildingId: { in: buildingIds } } };
  }

  private response(invoice: InvoiceWithDetails): object {
    const latestPayment = invoice.payments[0];
    const confirmedPayment = invoice.payments.find(
      (item) => item.status === PaymentStatus.CONFIRMED,
    );
    return {
      id: invoice.id,
      code: invoice.code,
      apartmentId: invoice.apartmentId,
      payerResidentId: invoice.payerId,
      billingMonth: invoice.billingMonth,
      issuedAt: invoice.issuedAt,
      dueDate: invoice.dueDate,
      status: invoice.status.toLowerCase(),
      createdById: invoice.createdById,
      createdByName: invoice.createdBy?.fullName ?? 'Dữ liệu khởi tạo',
      publishedById: invoice.publishedById,
      publishedByName: invoice.publishedBy?.fullName ?? null,
      publishedAt: invoice.publishedAt,
      items: invoice.items.map((item) => ({
        id: item.id,
        serviceRequestId: item.serviceRequest?.id ?? null,
        serviceRequestCode: item.serviceRequest?.code ?? null,
        feeTypeId: item.feeTypeId,
        feeTypeCode: item.feeType?.code ?? null,
        feeTypeDescription: item.feeType?.description ?? null,
        source: item.serviceRequest ? 'service' : item.feeType ? 'catalog' : 'manual',
        calculationType: item.serviceRequest
          ? 'service'
          : item.feeType?.calculationType.toLowerCase() ?? 'manual',
        calculationDescription: item.serviceRequest
          ? `Dịch vụ ${item.serviceRequest.code}: ${item.quantity.toNumber()} × ${item.unitPrice.toNumber().toLocaleString('vi-VN')} đồng`
          : item.feeType
          ? this.calculationDescription(
              item.feeType.calculationType,
              item.quantity.toNumber(),
              item.unitPrice.toNumber(),
            )
          : `Nhập trực tiếp: ${item.quantity.toNumber()} × ${item.unitPrice.toNumber().toLocaleString('vi-VN')} đồng`,
        name: item.name,
        quantity: item.quantity.toNumber(),
        unitPrice: item.unitPrice.toNumber(),
      })),
      paidAt: invoice.paidAt,
      paymentStatus: latestPayment?.status.toLowerCase() ?? null,
      paymentMethod: latestPayment?.method.toLowerCase() ?? null,
      paymentNote: latestPayment?.note ?? null,
      paymentProofUrl: latestPayment?.proofUrl ?? null,
      paymentSubmittedAt: latestPayment?.createdAt ?? null,
      paymentConfirmedByName: confirmedPayment?.confirmedBy?.fullName ?? null,
      transactionCode:
        latestPayment?.transactionCode ??
        confirmedPayment?.transactionCode ??
        null,
    };
  }

  private calculationDescription(
    type: FeeCalculationType,
    quantity: number,
    unitPrice: number,
  ): string {
    const price = unitPrice.toLocaleString('vi-VN');
    switch (type) {
      case FeeCalculationType.FIXED:
        return `Mức cố định: ${price} đồng/kỳ`;
      case FeeCalculationType.BY_AREA:
        return `Theo diện tích: ${quantity} m² × ${price} đồng/m²`;
      case FeeCalculationType.BY_QUANTITY:
        return `Theo số lượng: ${quantity} × ${price} đồng`;
    }
  }
}
