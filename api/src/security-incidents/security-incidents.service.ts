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
  NotificationType,
  Prisma,
  RoleCode,
  SecurityIncidentStatus,
} from '../generated/prisma/client';
import type { CreateSecurityIncidentDto } from './dto/create-security-incident.dto';
import type { UpdateSecurityIncidentDto } from './dto/update-security-incident.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { BuildingAccessService } from '../building-access/building-access.service';

const include = {
  building: true,
  apartment: true,
  reportedBy: true,
  resolvedBy: true,
  assignedTo: true,
  assignedBy: true,
  updates: { include: { actor: true }, orderBy: { createdAt: 'asc' as const } },
} satisfies Prisma.SecurityIncidentInclude;
type Incident = Prisma.SecurityIncidentGetPayload<{ include: typeof include }>;

@Injectable()
export class SecurityIncidentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly buildingAccess: BuildingAccessService,
  ) {}
  async findAll(user: AuthenticatedUser): Promise<object> {
    const items = await this.prisma.securityIncident.findMany({
      where: await this.incidentWhere(user),
      include,
      orderBy: { occurredAt: 'desc' },
    });
    return { items: items.map((item) => this.response(item)) };
  }
  async create(
    user: AuthenticatedUser,
    dto: CreateSecurityIncidentDto,
  ): Promise<object> {
    const apartment = await this.prisma.apartment.findUnique({
      where: { id: dto.apartmentId },
      select: { id: true, buildingId: true },
    });
    if (!apartment) throw new NotFoundException('Không tìm thấy căn hộ.');
    if (user.roles.includes(RoleCode.RESIDENT)) {
      const membership = await this.prisma.apartmentMembership.findFirst({
        where: {
          apartmentId: dto.apartmentId,
          userId: user.id,
          status: MembershipStatus.ACTIVE,
        },
        select: { id: true },
      });
      if (!membership)
        throw new ForbiddenException(
          'Bạn không có quan hệ cư trú đang hiệu lực với căn hộ này.',
        );
    } else {
      if (!this.canProcess(user)) {
        throw new ForbiddenException(
          'Vai trò của bạn không được phép tạo sự cố an ninh.',
        );
      }
      await this.buildingAccess.assertBuildingAccess(
        user,
        apartment.buildingId,
      );
    }
    const occurredAt = new Date(dto.occurredAt);
    if (occurredAt > new Date(Date.now() + 5 * 60 * 1000))
      throw new BadRequestException('Thời điểm xảy ra không được ở tương lai.');
    const now = new Date();
    const incidentId = await this.prisma.$transaction(async (transaction) => {
      const incident = await transaction.securityIncident.create({
        data: {
          code: `AN-${now.getUTCFullYear()}-${randomUUID().slice(0, 8).toUpperCase()}`,
          buildingId: apartment.buildingId,
          apartmentId: apartment.id,
          reportedById: user.id,
          type: dto.type,
          title: dto.title,
          description: dto.description,
          location: dto.location?.trim() || null,
          occurredAt,
        },
        select: { id: true },
      });
      await transaction.securityIncidentUpdate.create({
        data: {
          securityIncidentId: incident.id,
          actorId: user.id,
          status: SecurityIncidentStatus.REPORTED,
          note: 'Sự cố đã được ghi nhận.',
        },
      });
      return incident.id;
    });
    const created = await this.findOne(incidentId);
    await this.notifications.notifyRolesInBuilding(
      [RoleCode.ADMIN, RoleCode.MANAGEMENT, RoleCode.SECURITY],
      apartment.buildingId,
      {
        title: 'Có sự cố an ninh mới',
        message: `${created.code}: ${created.title}.`,
        type: NotificationType.SYSTEM,
        referenceType: 'security_incident',
        referenceId: created.id,
      },
      [user.id],
    );
    return this.response(created);
  }
  async update(
    id: string,
    user: AuthenticatedUser,
    dto: UpdateSecurityIncidentDto,
  ): Promise<object> {
    const current = await this.findOne(id);
    await this.buildingAccess.assertBuildingAccess(user, current.buildingId);
    const isAdmin = user.roles.includes(RoleCode.ADMIN);
    const isManager = user.roles.includes(RoleCode.MANAGEMENT);
    const isSecurity = user.roles.includes(RoleCode.SECURITY);
    if (isSecurity && current.assignedToId !== user.id) {
      throw new ForbiddenException(
        'Bảo vệ chỉ được xử lý sự cố được phân công cho mình.',
      );
    }
    if (isManager && dto.status !== SecurityIncidentStatus.CANCELLED) {
      throw new ForbiddenException(
        'Ban quản lý chỉ phân công, giám sát hoặc hủy sự cố.',
      );
    }
    if (!isAdmin && !isManager && !isSecurity) {
      throw new ForbiddenException('Vai trò hiện tại không được xử lý sự cố.');
    }
    if (current.status === dto.status)
      throw new ConflictException('Sự cố đang ở trạng thái này.');
    if (!this.canTransition(current.status, dto.status))
      throw new ConflictException(
        `Không thể chuyển trạng thái từ ${current.status} sang ${dto.status}.`,
      );
    const note = dto.resolutionNote?.trim() ?? '';
    if (dto.status === SecurityIncidentStatus.RESOLVED && note.length < 5)
      throw new BadRequestException(
        'Vui lòng nhập kết quả xử lý ít nhất 5 ký tự.',
      );
    await this.prisma.$transaction([
      this.prisma.securityIncident.update({
        where: { id },
        data: {
          status: dto.status,
          resolutionNote: note || null,
          resolvedById:
            dto.status === SecurityIncidentStatus.RESOLVED
              ? user.id
              : undefined,
          resolvedAt:
            dto.status === SecurityIncidentStatus.RESOLVED ? new Date() : null,
        },
      }),
      this.prisma.securityIncidentUpdate.create({
        data: {
          securityIncidentId: id,
          actorId: user.id,
          status: dto.status,
          note: note || 'Trạng thái sự cố đã được cập nhật.',
        },
      }),
    ]);
    const updated = await this.findOne(id);
    if (user.id !== updated.reportedById) {
      await this.notifications.notifyUser(updated.reportedById, {
        title: 'Sự cố an ninh được cập nhật',
        message: `${updated.code}: ${note || 'Trạng thái đã được cập nhật.'}`,
        type: NotificationType.SYSTEM,
        referenceType: 'security_incident',
        referenceId: updated.id,
      });
    }
    return this.response(updated);
  }

  async findAssignees(
    id: string,
    actor: AuthenticatedUser,
  ): Promise<object> {
    const incident = await this.findOne(id);
    await this.buildingAccess.assertBuildingAccess(actor, incident.buildingId);
    const now = new Date();
    const users = await this.prisma.user.findMany({
      where: {
        status: 'ACTIVE',
        userRoles: { some: { role: { code: RoleCode.SECURITY } } },
        staffBuildingAssignments: {
          some: {
            buildingId: incident.buildingId,
            isActive: true,
            startDate: { lte: now },
            OR: [{ endDate: null }, { endDate: { gte: now } }],
          },
        },
      },
      select: { id: true, fullName: true, email: true },
      orderBy: { fullName: 'asc' },
    });
    return {
      items: users.map((user) => ({ ...user, roles: [RoleCode.SECURITY] })),
    };
  }

  async assign(
    id: string,
    actor: AuthenticatedUser,
    assigneeId: string,
  ): Promise<object> {
    const current = await this.findOne(id);
    await this.buildingAccess.assertBuildingAccess(actor, current.buildingId);
    if (
      current.status === SecurityIncidentStatus.RESOLVED ||
      current.status === SecurityIncidentStatus.CANCELLED
    ) {
      throw new ConflictException('Không thể phân công sự cố đã kết thúc.');
    }
    const now = new Date();
    const assignee = await this.prisma.user.findFirst({
      where: {
        id: assigneeId,
        status: 'ACTIVE',
        userRoles: { some: { role: { code: RoleCode.SECURITY } } },
        staffBuildingAssignments: {
          some: {
            buildingId: current.buildingId,
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
        'Bảo vệ không hoạt động hoặc không phụ trách tòa nhà này.',
      );
    }
    const note = `Đã phân công cho ${assignee.fullName}.`;
    await this.prisma.$transaction([
      this.prisma.securityIncident.update({
        where: { id },
        data: {
          assignedToId: assignee.id,
          assignedById: actor.id,
          assignedAt: now,
          status: SecurityIncidentStatus.REVIEWING,
        },
      }),
      this.prisma.securityIncidentUpdate.create({
        data: {
          securityIncidentId: id,
          actorId: actor.id,
          status: SecurityIncidentStatus.REVIEWING,
          note,
        },
      }),
    ]);
    await this.notifications.notifyUser(assignee.id, {
      title: 'Bạn có sự cố an ninh mới',
      message: `${current.code}: ${current.title}.`,
      type: NotificationType.SYSTEM,
      referenceType: 'security_incident',
      referenceId: current.id,
    });
    return this.response(await this.findOne(id));
  }
  private async findOne(id: string): Promise<Incident> {
    const item = await this.prisma.securityIncident.findUnique({
      where: { id },
      include,
    });
    if (!item) throw new NotFoundException('Không tìm thấy sự cố an ninh.');
    return item;
  }
  private canProcess(user: AuthenticatedUser): boolean {
    return user.roles.some((role) =>
      [RoleCode.ADMIN, RoleCode.MANAGEMENT, RoleCode.SECURITY].some(
        (allowed) => allowed === role,
      ),
    );
  }

  private async incidentWhere(
    user: AuthenticatedUser,
  ): Promise<Prisma.SecurityIncidentWhereInput> {
    if (user.roles.includes(RoleCode.RESIDENT)) {
      return { reportedById: user.id };
    }
    if (user.roles.includes(RoleCode.ADMIN)) return {};
    if (!this.canProcess(user)) return { reportedById: user.id };
    const buildingIds =
      (await this.buildingAccess.accessibleStaffBuildingIds(user)) ?? [];
    if (
      user.roles.includes(RoleCode.SECURITY) &&
      !user.roles.includes(RoleCode.MANAGEMENT)
    ) {
      return { buildingId: { in: buildingIds }, assignedToId: user.id };
    }
    return { buildingId: { in: buildingIds } };
  }
  private canTransition(
    from: SecurityIncidentStatus,
    to: SecurityIncidentStatus,
  ): boolean {
    if (from === SecurityIncidentStatus.REPORTED)
      return (
        to === SecurityIncidentStatus.REVIEWING ||
        to === SecurityIncidentStatus.CANCELLED
      );
    if (from === SecurityIncidentStatus.REVIEWING)
      return (
        to === SecurityIncidentStatus.RESOLVED ||
        to === SecurityIncidentStatus.CANCELLED
      );
    return false;
  }
  private response(item: Incident): object {
    return {
      id: item.id,
      code: item.code,
      buildingId: item.buildingId,
      buildingName: item.building.name,
      apartmentId: item.apartmentId,
      apartmentCode: item.apartment?.code ?? null,
      reportedById: item.reportedById,
      reportedByName: item.reportedBy.fullName,
      type: this.toCamel(item.type),
      title: item.title,
      description: item.description,
      location: item.location,
      occurredAt: item.occurredAt,
      status: item.status.toLowerCase(),
      resolutionNote: item.resolutionNote,
      resolvedByName: item.resolvedBy?.fullName ?? null,
      assignedToId: item.assignedToId,
      assignedToName: item.assignedTo?.fullName ?? null,
      assignedByName: item.assignedBy?.fullName ?? null,
      assignedAt: item.assignedAt,
      history: item.updates.map((update) => ({
        id: update.id,
        status: update.status.toLowerCase(),
        note: update.note ?? '',
        actorName: update.actor.fullName,
        createdAt: update.createdAt,
      })),
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    } as const;
  }
  private toCamel(value: string): string {
    return value
      .toLowerCase()
      .replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase());
  }
}
