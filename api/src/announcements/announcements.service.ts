import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AnnouncementAudience,
  MembershipStatus,
  NotificationType,
  Prisma,
  RoleCode,
  UserStatus,
} from '../generated/prisma/client';
import type { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import { BuildingAccessService } from '../building-access/building-access.service';
import type { CreateAnnouncementDto } from './dto/create-announcement.dto';
import { NotificationsService } from '../notifications/notifications.service';

const announcementInclude = {
  author: true,
  building: true,
} satisfies Prisma.AnnouncementInclude;

type AnnouncementWithAuthor = Prisma.AnnouncementGetPayload<{
  include: typeof announcementInclude;
}>;

@Injectable()
export class AnnouncementsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly buildingAccess: BuildingAccessService,
    private readonly notifications: NotificationsService,
  ) {}

  async findAll(user: AuthenticatedUser): Promise<object> {
    const now = new Date();
    const canManage = this.canManage(user);
    const buildingIds = await this.accessibleBuildingIds(user);
    const buildingWhere =
      buildingIds === null
        ? {}
        : { OR: [{ buildingId: null }, { buildingId: { in: buildingIds } }] };
    const announcements = await this.prisma.announcement.findMany({
      where: canManage
        ? buildingWhere
        : {
            ...buildingWhere,
            isPublished: true,
            publishedAt: { lte: now },
            AND: [
              { OR: [{ expiresAt: null }, { expiresAt: { gt: now } }] },
              { audience: { in: this.audiencesFor(user) } },
            ],
          },
      include: announcementInclude,
      orderBy: [{ isPinned: 'desc' }, { publishedAt: 'desc' }],
    });

    const ids = announcements.map((item) => item.id);
    const readNotifications = ids.length
      ? await this.prisma.notification.findMany({
          where: {
            userId: user.id,
            referenceType: 'announcement',
            referenceId: { in: ids },
            readAt: { not: null },
          },
          select: { referenceId: true },
        })
      : [];
    const readIds = new Set(
      readNotifications
        .map((item) => item.referenceId)
        .filter((id): id is string => id !== null),
    );

    return {
      userId: user.id,
      items: announcements.map((item) =>
        this.response(item, readIds.has(item.id)),
      ),
    };
  }

  async create(
    author: AuthenticatedUser,
    dto: CreateAnnouncementDto,
  ): Promise<object> {
    const publishedAt = new Date(dto.publishedAt);
    const expiresAt = dto.expiresAt ? new Date(dto.expiresAt) : null;
    if (expiresAt && expiresAt <= publishedAt) {
      throw new BadRequestException('Ngày hết hạn phải sau ngày phát hành.');
    }
    if (!dto.buildingId && !author.roles.includes(RoleCode.ADMIN)) {
      throw new BadRequestException(
        'Ban quản lý phải chọn tòa nhà nhận thông báo.',
      );
    }
    if (dto.buildingId) {
      await this.buildingAccess.assertBuildingAccess(author, dto.buildingId);
    }

    const announcement = await this.prisma.announcement.create({
      data: {
        authorId: author.id,
        buildingId: dto.buildingId,
        title: dto.title,
        content: dto.content,
        category: dto.category,
        priority: dto.priority,
        audience: dto.audience,
        publishedAt,
        expiresAt,
        isPinned: dto.isPinned,
        isPublished: dto.isPublished,
      },
      include: announcementInclude,
    });
    if (announcement.isPublished) {
      await this.notifyAudience(announcement);
    }
    return this.response(announcement, false);
  }

  async togglePublished(id: string, user: AuthenticatedUser): Promise<object> {
    const current = await this.findById(id);
    await this.assertCanManageAnnouncement(current, user);
    const announcement = await this.prisma.announcement.update({
      where: { id },
      data: { isPublished: !current.isPublished },
      include: announcementInclude,
    });
    if (announcement.isPublished) {
      await this.notifyAudience(announcement);
    } else {
      await this.prisma.notification.deleteMany({
        where: {
          referenceType: 'announcement',
          referenceId: announcement.id,
        },
      });
    }
    return this.response(announcement, false);
  }

  async remove(id: string, user: AuthenticatedUser): Promise<void> {
    const current = await this.findById(id);
    await this.assertCanManageAnnouncement(current, user);
    await this.prisma.$transaction([
      this.prisma.notification.deleteMany({
        where: { referenceType: 'announcement', referenceId: id },
      }),
      this.prisma.announcement.delete({ where: { id } }),
    ]);
  }

  async markAsRead(id: string, user: AuthenticatedUser): Promise<object> {
    const announcement = await this.prisma.announcement.findUnique({
      where: { id },
      include: announcementInclude,
    });
    if (!announcement) {
      throw new NotFoundException('Không tìm thấy thông báo.');
    }
    const buildingIds = await this.accessibleBuildingIds(user);
    if (!this.canView(announcement, user, buildingIds)) {
      throw new ForbiddenException('Bạn không thể xem thông báo này.');
    }

    await this.upsertReadNotification(announcement, user.id);
    return { success: true };
  }

  async markAllAsRead(
    announcementIds: string[],
    user: AuthenticatedUser,
  ): Promise<object> {
    const uniqueIds = [...new Set(announcementIds)];
    if (!uniqueIds.length) return { success: true, updated: 0 };

    const announcements = await this.prisma.announcement.findMany({
      where: { id: { in: uniqueIds } },
      include: announcementInclude,
    });
    const buildingIds = await this.accessibleBuildingIds(user);
    const visible = announcements.filter((item) =>
      this.canView(item, user, buildingIds),
    );
    await this.prisma.$transaction(async (transaction) => {
      for (const announcement of visible) {
        await this.upsertReadNotification(announcement, user.id, transaction);
      }
    });
    return { success: true, updated: visible.length };
  }

  private async upsertReadNotification(
    announcement: AnnouncementWithAuthor,
    userId: string,
    client: Prisma.TransactionClient | PrismaService = this.prisma,
  ): Promise<void> {
    const existing = await client.notification.findFirst({
      where: {
        userId,
        referenceType: 'announcement',
        referenceId: announcement.id,
      },
      select: { id: true },
    });
    if (existing) {
      await client.notification.update({
        where: { id: existing.id },
        data: { readAt: new Date() },
      });
      return;
    }
    await client.notification.create({
      data: {
        userId,
        title: announcement.title,
        message: announcement.content,
        type: NotificationType.SYSTEM,
        referenceType: 'announcement',
        referenceId: announcement.id,
        readAt: new Date(),
      },
    });
  }

  private async notifyAudience(
    announcement: AnnouncementWithAuthor,
  ): Promise<void> {
    const now = new Date();
    const filters: Prisma.UserWhereInput[] = [];
    if (announcement.audience === AnnouncementAudience.RESIDENTS) {
      filters.push({
        userRoles: { some: { role: { code: RoleCode.RESIDENT } } },
      });
    } else if (announcement.audience === AnnouncementAudience.MANAGERS) {
      filters.push({
        userRoles: { some: { role: { code: { not: RoleCode.RESIDENT } } } },
      });
    }

    if (announcement.buildingId) {
      filters.push({
        OR: [
          {
            apartmentMemberships: {
              some: {
                status: MembershipStatus.ACTIVE,
                apartment: { buildingId: announcement.buildingId },
              },
            },
          },
          {
            staffBuildingAssignments: {
              some: {
                buildingId: announcement.buildingId,
                isActive: true,
                startDate: { lte: now },
                OR: [{ endDate: null }, { endDate: { gte: now } }],
              },
            },
          },
        ],
      });
    }

    const recipients = await this.prisma.user.findMany({
      where: {
        id: { not: announcement.authorId },
        status: UserStatus.ACTIVE,
        AND: filters,
      },
      select: { id: true },
    });
    if (!recipients.length) return;

    const existing = await this.prisma.notification.findMany({
      where: {
        userId: { in: recipients.map((item) => item.id) },
        referenceType: 'announcement',
        referenceId: announcement.id,
      },
      select: { userId: true },
    });
    const existingUserIds = new Set(existing.map((item) => item.userId));
    const newRecipients = recipients.filter(
      (item) => !existingUserIds.has(item.id),
    );
    if (!newRecipients.length) return;

    await this.notifications.notifyUsers(
      newRecipients.map((recipient) => recipient.id),
      {
        title: announcement.title,
        message: announcement.content,
        type: NotificationType.SYSTEM,
        referenceType: 'announcement',
        referenceId: announcement.id,
      },
    );
  }

  private async findById(id: string) {
    const announcement = await this.prisma.announcement.findUnique({
      where: { id },
      select: { id: true, isPublished: true, buildingId: true },
    });
    if (!announcement) {
      throw new NotFoundException('Không tìm thấy thông báo.');
    }
    return announcement;
  }

  private canView(
    announcement: AnnouncementWithAuthor,
    user: AuthenticatedUser,
    buildingIds: string[] | null,
  ): boolean {
    const inBuildingScope =
      announcement.buildingId === null ||
      buildingIds === null ||
      buildingIds.includes(announcement.buildingId);
    if (!inBuildingScope) return false;
    if (this.canManage(user)) return true;
    const now = new Date();
    return (
      announcement.isPublished &&
      announcement.publishedAt !== null &&
      announcement.publishedAt <= now &&
      (announcement.expiresAt === null || announcement.expiresAt > now) &&
      this.audiencesFor(user).includes(announcement.audience)
    );
  }

  private async accessibleBuildingIds(
    user: AuthenticatedUser,
  ): Promise<string[] | null> {
    if (user.roles.includes(RoleCode.ADMIN)) return null;
    if (user.roles.includes(RoleCode.RESIDENT)) {
      const memberships = await this.prisma.apartmentMembership.findMany({
        where: { userId: user.id, status: MembershipStatus.ACTIVE },
        select: { apartment: { select: { buildingId: true } } },
      });
      return [...new Set(memberships.map((item) => item.apartment.buildingId))];
    }
    return (await this.buildingAccess.accessibleStaffBuildingIds(user)) ?? [];
  }

  private async assertCanManageAnnouncement(
    announcement: { buildingId: string | null },
    user: AuthenticatedUser,
  ): Promise<void> {
    if (announcement.buildingId === null) {
      if (!user.roles.includes(RoleCode.ADMIN)) {
        throw new ForbiddenException(
          'Chỉ quản trị viên được quản lý thông báo toàn hệ thống.',
        );
      }
      return;
    }
    await this.buildingAccess.assertBuildingAccess(
      user,
      announcement.buildingId,
    );
  }

  private canManage(user: AuthenticatedUser): boolean {
    return user.roles.some(
      (role) => role === RoleCode.ADMIN || role === RoleCode.MANAGEMENT,
    );
  }

  private audiencesFor(user: AuthenticatedUser): AnnouncementAudience[] {
    const audiences: AnnouncementAudience[] = [AnnouncementAudience.ALL];
    if (user.roles.includes(RoleCode.RESIDENT)) {
      audiences.push(AnnouncementAudience.RESIDENTS);
    }
    if (user.roles.some((role) => role !== RoleCode.RESIDENT)) {
      audiences.push(AnnouncementAudience.MANAGERS);
    }
    return audiences;
  }

  private response(
    announcement: AnnouncementWithAuthor,
    isRead: boolean,
  ): object {
    return {
      id: announcement.id,
      title: announcement.title,
      content: announcement.content,
      category: announcement.category.toLowerCase(),
      priority: announcement.priority.toLowerCase(),
      audience: announcement.audience.toLowerCase(),
      publishedAt: announcement.publishedAt ?? announcement.createdAt,
      expiresAt: announcement.expiresAt,
      isPinned: announcement.isPinned,
      isPublished: announcement.isPublished,
      authorName: announcement.author.fullName,
      buildingId: announcement.buildingId,
      buildingName: announcement.building?.name ?? 'Toàn hệ thống',
      isRead,
    };
  }
}
