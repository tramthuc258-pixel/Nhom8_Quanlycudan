import { randomUUID } from 'node:crypto';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import {
  MembershipStatus,
  MembershipType,
  NotificationType,
  Prisma,
  RoleCode,
  ServiceRequestStatus,
  UserStatus,
} from '../generated/prisma/client';
import type { AssignServiceRequestDto } from './dto/assign-service-request.dto';
import type { CreateServiceRequestDto } from './dto/create-service-request.dto';
import type { UpdateServiceRequestStatusDto } from './dto/update-service-request-status.dto';
import {
  ServiceResidentDecision,
  type RespondServiceResultDto,
} from './dto/respond-service-result.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { BuildingAccessService } from '../building-access/building-access.service';

const requestInclude = {
  service: true,
  apartment: true,
  requestedBy: true,
  assignedTo: true,
  billedInvoiceItem: { select: { invoiceId: true, invoice: { select: { code: true, status: true } } } },
  updates: { include: { actor: true }, orderBy: { createdAt: 'asc' as const } },
} satisfies Prisma.ServiceRequestInclude;

type RequestWithDetails = Prisma.ServiceRequestGetPayload<{
  include: typeof requestInclude;
}>;

@Injectable()
export class ResidentServicesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly buildingAccess: BuildingAccessService,
  ) {}

  async findCatalog(user: AuthenticatedUser): Promise<object> {
    const services = await this.prisma.service.findMany({
      where: this.canManageCatalog(user) ? undefined : { isActive: true },
      orderBy: [{ isActive: 'desc' }, { category: 'asc' }, { name: 'asc' }],
    });
    return { items: services.map((service) => this.serviceResponse(service)) };
  }

  async findRequests(user: AuthenticatedUser): Promise<object> {
    const requests = await this.prisma.serviceRequest.findMany({
      where: await this.requestWhere(user),
      include: requestInclude,
      orderBy: { updatedAt: 'desc' },
    });
    return { items: requests.map((request) => this.requestResponse(request)) };
  }

  async createRequest(
    user: AuthenticatedUser,
    dto: CreateServiceRequestDto,
  ): Promise<object> {
    const membership = await this.prisma.apartmentMembership.findFirst({
      where: {
        apartmentId: dto.apartmentId,
        userId: user.id,
        status: MembershipStatus.ACTIVE,
      },
      select: { id: true, type: true },
    });
    if (!membership) {
      throw new ForbiddenException(
        'Bạn không có quan hệ cư trú đang hiệu lực với căn hộ này.',
      );
    }
    await this.assertCanUseLivingServices(
      user.id,
      dto.apartmentId,
      membership.type,
    );

    const service = await this.prisma.service.findUnique({
      where: { id: dto.serviceId },
    });
    if (!service) {
      throw new NotFoundException('Không tìm thấy dịch vụ đã chọn.');
    }
    if (!service.isActive) {
      throw new ConflictException(
        'Dịch vụ này hiện đang tạm ngừng nhận đăng ký.',
      );
    }

    const scheduledAt = new Date(dto.scheduledAt);
    const now = new Date();
    if (scheduledAt <= now) {
      throw new BadRequestException('Lịch hẹn phải ở trong tương lai.');
    }
    const latestAllowed = new Date(now);
    latestAllowed.setUTCFullYear(latestAllowed.getUTCFullYear() + 1);
    if (scheduledAt > latestAllowed) {
      throw new BadRequestException('Chỉ có thể đặt lịch trong vòng 365 ngày.');
    }

    const code = `DV-${now.getUTCFullYear()}-${randomUUID().slice(0, 8).toUpperCase()}`;
    const requestId = await this.prisma.$transaction(async (transaction) => {
      const request = await transaction.serviceRequest.create({
        data: {
          code,
          serviceId: service.id,
          apartmentId: dto.apartmentId,
          requestedById: user.id,
          createdById: user.id,
          quantity: dto.quantity,
          unitPrice: service.unitPrice,
          scheduledAt,
          note: dto.note?.trim() || null,
        },
        select: { id: true },
      });
      await transaction.serviceRequestUpdate.create({
        data: {
          serviceRequestId: request.id,
          actorId: user.id,
          status: ServiceRequestStatus.PENDING,
          note: 'Yêu cầu dịch vụ đã được gửi đến ban quản lý.',
        },
      });
      return request.id;
    });
    const created = await this.findRequest(requestId);
    await this.notifications.notifyRolesInBuilding(
      [RoleCode.ADMIN, RoleCode.MANAGEMENT, RoleCode.RECEPTIONIST],
      created.apartment.buildingId,
      {
        title: 'Có yêu cầu dịch vụ mới',
        message: `${created.code}: ${created.service.name} tại căn ${created.apartment.code}.`,
        type: NotificationType.SERVICE,
        referenceType: 'service_request',
        referenceId: created.id,
      },
      [user.id],
    );
    return this.requestResponse(created);
  }

  private async assertCanUseLivingServices(
    userId: string,
    apartmentId: string,
    membershipType: MembershipType,
  ): Promise<void> {
    if (membershipType !== MembershipType.OWNER) return;
    const activeTenant = await this.prisma.apartmentMembership.findFirst({
      where: {
        apartmentId,
        userId: { not: userId },
        type: MembershipType.TENANT,
        status: MembershipStatus.ACTIVE,
      },
      select: { id: true },
    });
    if (activeTenant) {
      throw new ForbiddenException(
        'Căn hộ đang có người thuê. Dịch vụ sinh hoạt do tài khoản người thuê thực hiện.',
      );
    }
  }

  async cancelRequest(id: string, user: AuthenticatedUser): Promise<object> {
    const request = await this.findRequest(id);
    if (request.requestedById !== user.id) {
      throw new ForbiddenException(
        'Bạn không thể hủy đăng ký của cư dân khác.',
      );
    }
    if (request.status !== ServiceRequestStatus.PENDING) {
      throw new ConflictException(
        'Chỉ có thể hủy đăng ký khi ban quản lý chưa xác nhận.',
      );
    }
    const note = 'Cư dân đã hủy đăng ký dịch vụ.';
    await this.prisma.$transaction([
      this.prisma.serviceRequest.update({
        where: { id },
        data: { status: ServiceRequestStatus.CANCELLED, managementNote: note },
      }),
      this.prisma.serviceRequestUpdate.create({
        data: {
          serviceRequestId: id,
          actorId: user.id,
          status: ServiceRequestStatus.CANCELLED,
          note,
        },
      }),
    ]);
    return this.requestResponse(await this.findRequest(id));
  }

  async assignRequest(
    id: string,
    actor: AuthenticatedUser,
    dto: AssignServiceRequestDto,
  ): Promise<object> {
    const request = await this.findRequest(id);
    await this.buildingAccess.assertApartmentAccess(actor, request.apartmentId);
    if (this.isTerminal(request.status)) {
      throw new ConflictException('Không thể phân công đăng ký đã kết thúc.');
    }
    const assignee = await this.findEligibleAssignee(
      dto.assigneeId,
      request.apartment.buildingId,
    );
    const nextStatus =
      request.status === ServiceRequestStatus.PENDING
        ? ServiceRequestStatus.CONFIRMED
        : request.status;
    const note = `Đã phân công cho ${assignee.fullName}.`;
    await this.prisma.$transaction([
      this.prisma.serviceRequest.update({
        where: { id },
        data: {
          assignedToId: assignee.id,
          assignedToName: assignee.fullName,
          status: nextStatus,
          managementNote: note,
        },
      }),
      this.prisma.serviceRequestUpdate.create({
        data: {
          serviceRequestId: id,
          actorId: actor.id,
          status: nextStatus,
          note,
        },
      }),
    ]);
    const updated = await this.findRequest(id);
    await this.notifications.notifyUser(updated.requestedById, {
      title: 'Yêu cầu dịch vụ đã được phân công',
      message: `${updated.code} đã được phân công cho ${assignee.fullName}.`,
      type: NotificationType.SERVICE,
      referenceType: 'service_request',
      referenceId: updated.id,
    });
    await this.notifications.notifyUser(assignee.id, {
      title: 'Bạn có công việc dịch vụ mới',
      message: `${updated.code}: ${updated.service.name} tại căn ${updated.apartment.code}.`,
      type: NotificationType.SERVICE,
      referenceType: 'service_request',
      referenceId: updated.id,
    });
    return this.requestResponse(updated);
  }

  async findAssignees(id: string, actor: AuthenticatedUser): Promise<object> {
    const request = await this.findRequest(id);
    await this.buildingAccess.assertApartmentAccess(actor, request.apartmentId);
    const now = new Date();
    const users = await this.prisma.user.findMany({
      where: {
        status: UserStatus.ACTIVE,
        userRoles: {
          some: {
            role: {
              code: RoleCode.TECHNICIAN,
            },
          },
        },
        staffBuildingAssignments: {
          some: {
            buildingId: request.apartment.buildingId,
            isActive: true,
            startDate: { lte: now },
            OR: [{ endDate: null }, { endDate: { gte: now } }],
          },
        },
      },
      select: {
        id: true,
        fullName: true,
        email: true,
        userRoles: { select: { role: { select: { code: true } } } },
      },
      orderBy: { fullName: 'asc' },
    });
    return {
      items: users.map((user) => ({
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        roles: user.userRoles.map((item) => item.role.code),
      })),
    };
  }

  async updateStatus(
    id: string,
    actor: AuthenticatedUser,
    dto: UpdateServiceRequestStatusDto,
  ): Promise<object> {
    const request = await this.findRequest(id);
    await this.buildingAccess.assertApartmentAccess(actor, request.apartmentId);
    if (
      actor.roles.includes(RoleCode.TECHNICIAN) &&
      !actor.roles.some(
        (role) => role === RoleCode.ADMIN || role === RoleCode.MANAGEMENT,
      ) &&
      request.assignedToId !== actor.id
    ) {
      throw new ForbiddenException(
        'Kỹ thuật viên chỉ được cập nhật dịch vụ được phân công cho mình.',
      );
    }
    this.assertRoleTransition(actor, request.status, dto.status);
    if (request.status === dto.status) {
      throw new ConflictException('Đăng ký đang ở trạng thái này.');
    }
    if (!this.canTransition(request.status, dto.status)) {
      throw new ConflictException(
        `Không thể chuyển trạng thái từ ${request.status} sang ${dto.status}.`,
      );
    }
    if (
      (dto.status === ServiceRequestStatus.IN_PROGRESS ||
        dto.status === ServiceRequestStatus.WAITING_RESIDENT) &&
      !request.assignedToId
    ) {
      throw new ConflictException(
        'Phải phân công kỹ thuật viên trước khi bắt đầu xử lý dịch vụ.',
      );
    }

    const note = dto.note?.trim() ?? '';
    if (
      (dto.status === ServiceRequestStatus.WAITING_RESIDENT ||
        dto.status === ServiceRequestStatus.CANCELLED) &&
      note.length < 5
    ) {
      throw new BadRequestException(
        'Vui lòng nhập ghi chú cập nhật ít nhất 5 ký tự.',
      );
    }

    const effectiveNote =
      note || `Trạng thái được cập nhật thành ${this.toCamel(dto.status)}.`;
    await this.prisma.$transaction([
      this.prisma.serviceRequest.update({
        where: { id },
        data: {
          status: dto.status,
          managementNote: effectiveNote,
          completedAt: null,
        },
      }),
      this.prisma.serviceRequestUpdate.create({
        data: {
          serviceRequestId: id,
          actorId: actor.id,
          status: dto.status,
          note: effectiveNote,
        },
      }),
    ]);
    const updated = await this.findRequest(id);
    await this.notifications.notifyUser(updated.requestedById, {
      title:
        dto.status === ServiceRequestStatus.WAITING_RESIDENT
          ? 'Dịch vụ đang chờ bạn xác nhận'
          : 'Yêu cầu dịch vụ được cập nhật',
      message:
        dto.status === ServiceRequestStatus.WAITING_RESIDENT
          ? `${updated.code}: ${effectiveNote} Vui lòng kiểm tra và phản hồi.`
          : `${updated.code}: ${effectiveNote}`,
      type: NotificationType.SERVICE,
      referenceType: 'service_request',
      referenceId: updated.id,
    });
    return this.requestResponse(updated);
  }

  async respondToResult(
    id: string,
    resident: AuthenticatedUser,
    dto: RespondServiceResultDto,
  ): Promise<object> {
    const current = await this.findRequest(id);
    if (current.requestedById !== resident.id) {
      throw new ForbiddenException(
        'Bạn chỉ được phản hồi yêu cầu dịch vụ do chính mình gửi.',
      );
    }
    if (current.status !== ServiceRequestStatus.WAITING_RESIDENT) {
      throw new ConflictException(
        'Dịch vụ chưa ở trạng thái chờ cư dân xác nhận.',
      );
    }

    const note = dto.note?.trim() ?? '';
    const confirmed = dto.decision === ServiceResidentDecision.CONFIRM;
    if (!confirmed && note.length < 5) {
      throw new BadRequestException(
        'Vui lòng mô tả nội dung cần xử lý lại ít nhất 5 ký tự.',
      );
    }
    const nextStatus = confirmed
      ? ServiceRequestStatus.COMPLETED
      : ServiceRequestStatus.IN_PROGRESS;
    const effectiveNote = confirmed
      ? note || 'Cư dân xác nhận dịch vụ đã hoàn tất.'
      : `Cư dân yêu cầu xử lý lại: ${note}`;

    await this.prisma.$transaction([
      this.prisma.serviceRequest.update({
        where: { id },
        data: {
          status: nextStatus,
          managementNote: effectiveNote,
          completedAt: confirmed ? new Date() : null,
        },
      }),
      this.prisma.serviceRequestUpdate.create({
        data: {
          serviceRequestId: id,
          actorId: resident.id,
          status: nextStatus,
          note: effectiveNote,
        },
      }),
    ]);

    const notification = {
      title: confirmed
        ? 'Cư dân đã xác nhận dịch vụ hoàn tất'
        : 'Cư dân yêu cầu xử lý lại dịch vụ',
      message: `${current.code}: ${effectiveNote}`,
      type: NotificationType.SERVICE,
      referenceType: 'service_request',
      referenceId: current.id,
    };
    if (current.assignedToId) {
      await this.notifications.notifyUser(current.assignedToId, notification);
    }
    await this.notifications.notifyRolesInBuilding(
      [RoleCode.ADMIN, RoleCode.MANAGEMENT, RoleCode.RECEPTIONIST],
      current.apartment.buildingId,
      notification,
      [resident.id, ...(current.assignedToId ? [current.assignedToId] : [])],
    );
    return this.requestResponse(await this.findRequest(id));
  }

  async toggleActive(id: string): Promise<object> {
    const service = await this.prisma.service.findUnique({ where: { id } });
    if (!service) {
      throw new NotFoundException('Không tìm thấy dịch vụ cần cập nhật.');
    }
    const updated = await this.prisma.service.update({
      where: { id },
      data: { isActive: !service.isActive },
    });
    return this.serviceResponse(updated);
  }

  private async findRequest(id: string): Promise<RequestWithDetails> {
    const request = await this.prisma.serviceRequest.findUnique({
      where: { id },
      include: requestInclude,
    });
    if (!request) {
      throw new NotFoundException('Không tìm thấy đăng ký dịch vụ.');
    }
    return request;
  }

  private canManageCatalog(user: AuthenticatedUser): boolean {
    return user.roles.some(
      (role) => role === RoleCode.ADMIN || role === RoleCode.MANAGEMENT,
    );
  }

  private async requestWhere(
    user: AuthenticatedUser,
  ): Promise<Prisma.ServiceRequestWhereInput> {
    if (user.roles.includes(RoleCode.RESIDENT)) {
      return { requestedById: user.id };
    }
    if (user.roles.includes(RoleCode.ADMIN)) return {};

    const operational = user.roles.some(
      (role) =>
        role === RoleCode.MANAGEMENT ||
        role === RoleCode.RECEPTIONIST ||
        role === RoleCode.TECHNICIAN,
    );
    if (!operational) return { apartment: { buildingId: { in: [] } } };

    const buildingIds =
      (await this.buildingAccess.accessibleStaffBuildingIds(user)) ?? [];
    const buildingScope = { apartment: { buildingId: { in: buildingIds } } };
    if (
      user.roles.includes(RoleCode.TECHNICIAN) &&
      !user.roles.includes(RoleCode.MANAGEMENT)
    ) {
      return { ...buildingScope, assignedToId: user.id };
    }
    return buildingScope;
  }

  private isTerminal(status: ServiceRequestStatus): boolean {
    return (
      status === ServiceRequestStatus.COMPLETED ||
      status === ServiceRequestStatus.CANCELLED
    );
  }

  private canTransition(
    from: ServiceRequestStatus,
    to: ServiceRequestStatus,
  ): boolean {
    switch (from) {
      case ServiceRequestStatus.PENDING:
        return (
          to === ServiceRequestStatus.CONFIRMED ||
          to === ServiceRequestStatus.CANCELLED
        );
      case ServiceRequestStatus.CONFIRMED:
        return (
          to === ServiceRequestStatus.IN_PROGRESS ||
          to === ServiceRequestStatus.CANCELLED
        );
      case ServiceRequestStatus.IN_PROGRESS:
        return (
          to === ServiceRequestStatus.WAITING_RESIDENT ||
          to === ServiceRequestStatus.CANCELLED
        );
      case ServiceRequestStatus.WAITING_RESIDENT:
        return to === ServiceRequestStatus.CANCELLED;
      case ServiceRequestStatus.COMPLETED:
      case ServiceRequestStatus.CANCELLED:
        return false;
    }
  }

  private serviceResponse(service: {
    id: string;
    name: string;
    description: string | null;
    category: string;
    unitLabel: string;
    unitPrice: Prisma.Decimal;
    estimatedDurationMinutes: number | null;
    providerName: string | null;
    contactPhone: string | null;
    isActive: boolean;
  }): object {
    return {
      id: service.id,
      name: service.name,
      description: service.description ?? '',
      category: service.category.toLowerCase(),
      unitLabel: service.unitLabel,
      unitPrice: service.unitPrice.toNumber(),
      estimatedDurationMinutes: service.estimatedDurationMinutes ?? 0,
      providerName: service.providerName ?? '',
      contactPhone: service.contactPhone ?? '',
      isActive: service.isActive,
    };
  }

  private requestResponse(request: RequestWithDetails): object {
    return {
      id: request.id,
      code: request.code,
      serviceId: request.serviceId,
      serviceName: request.service.name,
      unitPrice: request.unitPrice.toNumber(),
      apartmentId: request.apartmentId,
      residentId: request.requestedById,
      residentName: request.requestedBy.fullName,
      quantity: request.quantity.toNumber(),
      scheduledAt: request.scheduledAt,
      note: request.note ?? '',
      status: this.toCamel(request.status),
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
      assignedTo:
        request.assignedToName ?? request.assignedTo?.fullName ?? null,
      assignedToId: request.assignedToId,
      managementNote: request.managementNote,
      completedAt: request.completedAt,
      invoiceId: ['CANCELLED', 'DRAFT'].includes(request.billedInvoiceItem?.invoice.status ?? '')
        ? null
        : request.billedInvoiceItem?.invoiceId ?? null,
      invoiceCode: ['CANCELLED', 'DRAFT'].includes(request.billedInvoiceItem?.invoice.status ?? '')
        ? null
        : request.billedInvoiceItem?.invoice.code ?? null,
      history: request.updates.map((update) => ({
        id: update.id,
        status: this.toCamel(update.status),
        note: update.note ?? '',
        actorName: update.actor.fullName,
        createdAt: update.createdAt,
      })),
    };
  }

  private toCamel(value: string): string {
    return value
      .toLowerCase()
      .replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase());
  }

  private async findEligibleAssignee(
    userId: string,
    buildingId: string,
  ): Promise<{ id: string; fullName: string }> {
    const now = new Date();
    const assignee = await this.prisma.user.findFirst({
      where: {
        id: userId,
        status: UserStatus.ACTIVE,
        userRoles: {
          some: {
            role: {
              code: RoleCode.TECHNICIAN,
            },
          },
        },
        staffBuildingAssignments: {
          some: {
            buildingId,
            isActive: true,
            startDate: { lte: now },
            OR: [{ endDate: null }, { endDate: { gte: now } }],
          },
        },
      },
      select: { id: true, fullName: true },
    });
    if (!assignee) {
      throw new BadRequestException(
        'Nhân viên không hoạt động hoặc không được phân công phụ trách tòa nhà này.',
      );
    }
    return assignee;
  }

  private assertRoleTransition(
    actor: AuthenticatedUser,
    from: ServiceRequestStatus,
    to: ServiceRequestStatus,
  ): void {
    if (actor.roles.includes(RoleCode.ADMIN)) {
      return;
    }
    if (actor.roles.includes(RoleCode.MANAGEMENT)) {
      if (
        (from === ServiceRequestStatus.PENDING &&
          to === ServiceRequestStatus.CONFIRMED) ||
        to === ServiceRequestStatus.CANCELLED
      ) {
        return;
      }
      throw new ForbiddenException(
        'Ban quản lý chỉ tiếp nhận, phân công, hủy và giám sát dịch vụ.',
      );
    }
    if (actor.roles.includes(RoleCode.RECEPTIONIST)) {
      if (
        from === ServiceRequestStatus.PENDING &&
        [ServiceRequestStatus.CONFIRMED, ServiceRequestStatus.CANCELLED].some(
          (status) => status === to,
        )
      ) {
        return;
      }
      throw new ForbiddenException(
        'Lễ tân chỉ tiếp nhận, xác nhận hoặc từ chối yêu cầu mới.',
      );
    }
    if (actor.roles.includes(RoleCode.TECHNICIAN)) {
      if (
        (from === ServiceRequestStatus.CONFIRMED &&
          to === ServiceRequestStatus.IN_PROGRESS) ||
        (from === ServiceRequestStatus.IN_PROGRESS &&
          to === ServiceRequestStatus.WAITING_RESIDENT)
      ) {
        return;
      }
      throw new ForbiddenException(
        'Kỹ thuật viên chỉ bắt đầu việc được giao và gửi kết quả để cư dân xác nhận.',
      );
    }
    throw new ForbiddenException('Vai trò hiện tại không được xử lý dịch vụ.');
  }
}
