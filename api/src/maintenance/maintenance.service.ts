import { randomUUID } from 'node:crypto';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  MaintenanceStatus,
  MembershipStatus,
  NotificationType,
  Prisma,
  RoleCode,
  UserStatus,
} from '../generated/prisma/client';
import type { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { BuildingAccessService } from '../building-access/building-access.service';
import type { AssignMaintenanceRequestDto } from './dto/assign-maintenance-request.dto';
import type { CreateMaintenanceRequestDto } from './dto/create-maintenance-request.dto';
import type { UpdateMaintenanceStatusDto } from './dto/update-maintenance-status.dto';
import {
  MaintenanceResidentDecision,
  type RespondMaintenanceResultDto,
} from './dto/respond-maintenance-result.dto';

const requestInclude = {
  apartment: true,
  requestedBy: true,
  assignedTechnician: true,
  updates: { include: { actor: true }, orderBy: { createdAt: 'asc' as const } },
} satisfies Prisma.MaintenanceRequestInclude;

type RequestWithDetails = Prisma.MaintenanceRequestGetPayload<{
  include: typeof requestInclude;
}>;

@Injectable()
export class MaintenanceService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly buildingAccess: BuildingAccessService,
  ) {}

  async findAll(user: AuthenticatedUser): Promise<object> {
    const requests = await this.prisma.maintenanceRequest.findMany({
      where: await this.requestWhere(user),
      include: requestInclude,
      orderBy: { updatedAt: 'desc' },
    });
    return { items: requests.map((item) => this.response(item)) };
  }

  async create(
    user: AuthenticatedUser,
    dto: CreateMaintenanceRequestDto,
  ): Promise<object> {
    if (!user.roles.includes(RoleCode.RESIDENT)) {
      throw new ForbiddenException('Chỉ cư dân mới có thể gửi yêu cầu.');
    }
    const membership = await this.prisma.apartmentMembership.findFirst({
      where: {
        apartmentId: dto.apartmentId,
        userId: user.id,
        status: MembershipStatus.ACTIVE,
      },
      select: { id: true },
    });
    if (!membership) {
      throw new ForbiddenException(
        'Bạn không có quan hệ cư trú đang hiệu lực với căn hộ này.',
      );
    }

    const now = new Date();
    const code = `YC-${now.getUTCFullYear()}-${randomUUID().slice(0, 8).toUpperCase()}`;
    const requestId = await this.prisma.$transaction(async (transaction) => {
      const request = await transaction.maintenanceRequest.create({
        data: {
          code,
          apartmentId: dto.apartmentId,
          requestedById: user.id,
          createdById: user.id,
          title: dto.title,
          description: dto.description,
          location: dto.location,
          category: dto.category,
          priority: dto.priority,
          imageUrls: dto.imageUrls ?? [],
        },
        select: { id: true },
      });
      await transaction.maintenanceUpdate.create({
        data: {
          maintenanceRequestId: request.id,
          actorId: user.id,
          status: MaintenanceStatus.SUBMITTED,
          note: 'Yêu cầu đã được gửi đến ban quản lý.',
        },
      });
      return request.id;
    });
    const created = await this.findRequest(requestId);
    await this.notifications.notifyRolesInBuilding(
      [RoleCode.ADMIN, RoleCode.MANAGEMENT, RoleCode.RECEPTIONIST],
      created.apartment.buildingId,
      {
        title: 'Có yêu cầu sửa chữa mới',
        message: `${created.code}: ${created.title} tại căn ${created.apartment.code}.`,
        type: NotificationType.MAINTENANCE,
        referenceType: 'maintenance_request',
        referenceId: created.id,
      },
      [user.id],
    );
    return this.response(created);
  }

  async assign(
    id: string,
    actor: AuthenticatedUser,
    dto: AssignMaintenanceRequestDto,
  ): Promise<object> {
    const current = await this.findRequest(id);
    await this.buildingAccess.assertApartmentAccess(actor, current.apartmentId);
    if (!this.isOpen(current.status)) {
      throw new ConflictException('Không thể phân công yêu cầu đã kết thúc.');
    }
    const assignee = await this.findEligibleAssignee(
      dto.assigneeId,
      current.apartment.buildingId,
    );
    const nextStatus =
      current.status === MaintenanceStatus.SUBMITTED
        ? MaintenanceStatus.RECEIVED
        : current.status;

    await this.prisma.$transaction([
      this.prisma.maintenanceRequest.update({
        where: { id },
        data: {
          assignedTechnicianId: assignee.id,
          assignedTeamName: assignee.fullName,
          assignedById: actor.id,
          assignedAt: new Date(),
          status: nextStatus,
        },
      }),
      this.prisma.maintenanceUpdate.create({
        data: {
          maintenanceRequestId: id,
          actorId: actor.id,
          status: nextStatus,
          note: `Đã phân công cho ${assignee.fullName}.`,
        },
      }),
    ]);
    const updated = await this.findRequest(id);
    await this.notifications.notifyUser(current.requestedById, {
      title: 'Yêu cầu sửa chữa đã được phân công',
      message: `${current.code} đã được phân công cho ${assignee.fullName}.`,
      type: NotificationType.MAINTENANCE,
      referenceType: 'maintenance_request',
      referenceId: current.id,
    });
    await this.notifications.notifyUser(assignee.id, {
      title: 'Bạn có công việc sửa chữa mới',
      message: `${current.code}: ${current.title} tại căn ${current.apartment.code}.`,
      type: NotificationType.MAINTENANCE,
      referenceType: 'maintenance_request',
      referenceId: current.id,
    });
    return this.response(updated);
  }

  async findAssignees(id: string, actor: AuthenticatedUser): Promise<object> {
    const request = await this.findRequest(id);
    await this.buildingAccess.assertApartmentAccess(actor, request.apartmentId);
    const now = new Date();
    const users = await this.prisma.user.findMany({
      where: {
        status: UserStatus.ACTIVE,
        userRoles: { some: { role: { code: RoleCode.TECHNICIAN } } },
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
    user: AuthenticatedUser,
    dto: UpdateMaintenanceStatusDto,
  ): Promise<object> {
    const current = await this.findRequest(id);
    const isResidentOwner = current.requestedById === user.id;
    if (this.canProcess(user)) {
      await this.buildingAccess.assertApartmentAccess(
        user,
        current.apartmentId,
      );
      if (
        user.roles.includes(RoleCode.TECHNICIAN) &&
        !user.roles.some(
          (role) => role === RoleCode.ADMIN || role === RoleCode.MANAGEMENT,
        ) &&
        current.assignedTechnicianId !== user.id
      ) {
        throw new ForbiddenException(
          'Kỹ thuật viên chỉ được cập nhật công việc được phân công cho mình.',
        );
      }
      this.assertRoleTransition(user, current.status, dto.status);
    }
    if (!this.canProcess(user)) {
      if (
        !isResidentOwner ||
        current.status !== MaintenanceStatus.SUBMITTED ||
        dto.status !== MaintenanceStatus.CANCELLED
      ) {
        throw new ForbiddenException(
          'Cư dân chỉ được hủy yêu cầu của mình trước khi được tiếp nhận.',
        );
      }
    }
    if (current.status === dto.status) {
      throw new ConflictException('Yêu cầu đang ở trạng thái này.');
    }
    if (!this.canTransition(current.status, dto.status)) {
      throw new ConflictException(
        `Không thể chuyển trạng thái từ ${current.status} sang ${dto.status}.`,
      );
    }
    if (
      (dto.status === MaintenanceStatus.IN_PROGRESS ||
        dto.status === MaintenanceStatus.WAITING_RESIDENT) &&
      !current.assignedTechnicianId
    ) {
      throw new ConflictException(
        'Phải phân công kỹ thuật viên trước khi bắt đầu xử lý yêu cầu.',
      );
    }
    const note = dto.note?.trim() ?? '';
    if (
      (dto.status === MaintenanceStatus.COMPLETED ||
        dto.status === MaintenanceStatus.WAITING_RESIDENT) &&
      note.length < 5
    ) {
      throw new BadRequestException(
        'Vui lòng nhập ghi chú cập nhật ít nhất 5 ký tự.',
      );
    }

    const effectiveNote =
      note || `Trạng thái được cập nhật thành ${this.toCamel(dto.status)}.`;
    await this.prisma.$transaction([
      this.prisma.maintenanceRequest.update({
        where: { id },
        data: {
          status: dto.status,
          completedAt:
            dto.status === MaintenanceStatus.COMPLETED ? new Date() : undefined,
        },
      }),
      this.prisma.maintenanceUpdate.create({
        data: {
          maintenanceRequestId: id,
          actorId: user.id,
          status: dto.status,
          note: effectiveNote,
        },
      }),
    ]);
    const updated = await this.findRequest(id);
    if (user.id !== current.requestedById) {
      await this.notifications.notifyUser(current.requestedById, {
        title:
          dto.status === MaintenanceStatus.WAITING_RESIDENT
            ? 'Kết quả sửa chữa đang chờ bạn xác nhận'
            : 'Yêu cầu sửa chữa được cập nhật',
        message:
          dto.status === MaintenanceStatus.WAITING_RESIDENT
            ? `${current.code}: ${effectiveNote} Vui lòng kiểm tra thực tế và phản hồi.`
            : `${current.code}: ${effectiveNote}`,
        type: NotificationType.MAINTENANCE,
        referenceType: 'maintenance_request',
        referenceId: current.id,
      });
    }
    return this.response(updated);
  }

  async respondToResult(
    id: string,
    resident: AuthenticatedUser,
    dto: RespondMaintenanceResultDto,
  ): Promise<object> {
    const current = await this.findRequest(id);
    if (current.requestedById !== resident.id) {
      throw new ForbiddenException(
        'Bạn chỉ được phản hồi yêu cầu do chính mình gửi.',
      );
    }
    if (current.status !== MaintenanceStatus.WAITING_RESIDENT) {
      throw new ConflictException(
        'Yêu cầu chưa ở trạng thái chờ cư dân xác nhận.',
      );
    }

    const note = dto.note?.trim() ?? '';
    const confirmed = dto.decision === MaintenanceResidentDecision.CONFIRM;
    if (!confirmed && note.length < 5) {
      throw new BadRequestException(
        'Vui lòng mô tả vấn đề chưa được khắc phục ít nhất 5 ký tự.',
      );
    }
    const nextStatus = confirmed
      ? MaintenanceStatus.COMPLETED
      : MaintenanceStatus.IN_PROGRESS;
    const effectiveNote = confirmed
      ? note || 'Cư dân xác nhận sự cố đã được khắc phục.'
      : `Cư dân phản hồi chưa khắc phục: ${note}`;

    await this.prisma.$transaction([
      this.prisma.maintenanceRequest.update({
        where: { id },
        data: {
          status: nextStatus,
          completedAt: confirmed ? new Date() : null,
        },
      }),
      this.prisma.maintenanceUpdate.create({
        data: {
          maintenanceRequestId: id,
          actorId: resident.id,
          status: nextStatus,
          note: effectiveNote,
        },
      }),
    ]);

    const notification = {
      title: confirmed
        ? 'Cư dân đã xác nhận hoàn thành'
        : 'Cư dân yêu cầu xử lý lại',
      message: `${current.code}: ${effectiveNote}`,
      type: NotificationType.MAINTENANCE,
      referenceType: 'maintenance_request',
      referenceId: current.id,
    };
    if (current.assignedTechnicianId) {
      await this.notifications.notifyUser(
        current.assignedTechnicianId,
        notification,
      );
    }
    await this.notifications.notifyRolesInBuilding(
      [RoleCode.ADMIN, RoleCode.MANAGEMENT, RoleCode.RECEPTIONIST],
      current.apartment.buildingId,
      notification,
      [
        resident.id,
        ...(current.assignedTechnicianId ? [current.assignedTechnicianId] : []),
      ],
    );
    return this.response(await this.findRequest(id));
  }

  private async findRequest(id: string): Promise<RequestWithDetails> {
    const request = await this.prisma.maintenanceRequest.findUnique({
      where: { id },
      include: requestInclude,
    });
    if (!request) {
      throw new NotFoundException('Không tìm thấy yêu cầu sửa chữa.');
    }
    return request;
  }

  private canProcess(user: AuthenticatedUser): boolean {
    return user.roles.some((role) =>
      [
        RoleCode.ADMIN,
        RoleCode.MANAGEMENT,
        RoleCode.TECHNICIAN,
        RoleCode.RECEPTIONIST,
      ].some((allowed) => allowed === role),
    );
  }

  private async requestWhere(
    user: AuthenticatedUser,
  ): Promise<Prisma.MaintenanceRequestWhereInput> {
    if (user.roles.includes(RoleCode.RESIDENT)) {
      return { requestedById: user.id };
    }
    if (user.roles.includes(RoleCode.ADMIN)) return {};
    if (!this.canProcess(user))
      return { apartment: { buildingId: { in: [] } } };

    const buildingIds =
      (await this.buildingAccess.accessibleStaffBuildingIds(user)) ?? [];
    const buildingScope = { apartment: { buildingId: { in: buildingIds } } };
    if (
      user.roles.includes(RoleCode.TECHNICIAN) &&
      !user.roles.some((role) => role === RoleCode.MANAGEMENT)
    ) {
      return { ...buildingScope, assignedTechnicianId: user.id };
    }
    return buildingScope;
  }

  private isOpen(status: MaintenanceStatus): boolean {
    return ![MaintenanceStatus.COMPLETED, MaintenanceStatus.CANCELLED].some(
      (closed) => closed === status,
    );
  }

  private canTransition(
    from: MaintenanceStatus,
    to: MaintenanceStatus,
  ): boolean {
    switch (from) {
      case MaintenanceStatus.SUBMITTED:
        return [MaintenanceStatus.RECEIVED, MaintenanceStatus.CANCELLED].some(
          (candidate) => candidate === to,
        );
      case MaintenanceStatus.RECEIVED:
        return [
          MaintenanceStatus.IN_PROGRESS,
          MaintenanceStatus.WAITING_RESIDENT,
          MaintenanceStatus.CANCELLED,
        ].some((candidate) => candidate === to);
      case MaintenanceStatus.IN_PROGRESS:
        return [
          MaintenanceStatus.WAITING_RESIDENT,
          MaintenanceStatus.CANCELLED,
        ].some((candidate) => candidate === to);
      case MaintenanceStatus.WAITING_RESIDENT:
        return to === MaintenanceStatus.CANCELLED;
      case MaintenanceStatus.COMPLETED:
      case MaintenanceStatus.CANCELLED:
        return false;
    }
  }

  private response(request: RequestWithDetails): object {
    return {
      id: request.id,
      code: request.code,
      apartmentId: request.apartmentId,
      residentId: request.requestedById,
      title: request.title,
      description: request.description,
      location: request.location ?? '',
      category: this.toCamel(request.category),
      priority: request.priority.toLowerCase(),
      status: this.toCamel(request.status),
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
      assignedTo:
        request.assignedTeamName ??
        request.assignedTechnician?.fullName ??
        null,
      assignedToId: request.assignedTechnicianId,
      imageUrls: Array.isArray(request.imageUrls) ? request.imageUrls : [],
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
        userRoles: { some: { role: { code: RoleCode.TECHNICIAN } } },
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
        'Kỹ thuật viên không hoạt động hoặc không được phân công phụ trách tòa nhà này.',
      );
    }
    return assignee;
  }

  private assertRoleTransition(
    actor: AuthenticatedUser,
    from: MaintenanceStatus,
    to: MaintenanceStatus,
  ): void {
    if (actor.roles.includes(RoleCode.ADMIN)) {
      return;
    }
    if (actor.roles.includes(RoleCode.MANAGEMENT)) {
      if (
        (from === MaintenanceStatus.SUBMITTED &&
          to === MaintenanceStatus.RECEIVED) ||
        to === MaintenanceStatus.CANCELLED
      ) {
        return;
      }
      throw new ForbiddenException(
        'Ban quản lý chỉ tiếp nhận, phân công, hủy và giám sát yêu cầu.',
      );
    }
    if (actor.roles.includes(RoleCode.RECEPTIONIST)) {
      if (
        from === MaintenanceStatus.SUBMITTED &&
        [MaintenanceStatus.RECEIVED, MaintenanceStatus.CANCELLED].some(
          (status) => status === to,
        )
      ) {
        return;
      }
      throw new ForbiddenException(
        'Lễ tân chỉ được tiếp nhận, phân loại hoặc từ chối yêu cầu mới.',
      );
    }
    if (actor.roles.includes(RoleCode.TECHNICIAN)) {
      if (
        (from === MaintenanceStatus.RECEIVED &&
          to === MaintenanceStatus.IN_PROGRESS) ||
        (from === MaintenanceStatus.IN_PROGRESS &&
          to === MaintenanceStatus.WAITING_RESIDENT)
      ) {
        return;
      }
      throw new ForbiddenException(
        'Kỹ thuật viên chỉ bắt đầu việc được giao và gửi kết quả để cư dân xác nhận.',
      );
    }
    throw new ForbiddenException(
      'Vai trò hiện tại không được cập nhật yêu cầu sửa chữa.',
    );
  }
}
