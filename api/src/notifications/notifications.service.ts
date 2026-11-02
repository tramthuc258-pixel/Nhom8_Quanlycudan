import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import {
  type Notification,
  NotificationType,
  RoleCode,
  UserStatus,
} from '../generated/prisma/client';
import { PushNotificationsService } from '../push-notifications/push-notifications.service';

export interface SendNotificationInput {
  title: string;
  message: string;
  type: NotificationType;
  referenceType?: string;
  referenceId?: string;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly pushNotifications: PushNotificationsService,
  ) {}

  async notifyUser(
    userId: string,
    input: SendNotificationInput,
  ): Promise<void> {
    try {
      const notification = await this.prisma.notification.create({
        data: {
          userId,
          title: input.title,
          message: input.message,
          type: input.type,
          referenceType: input.referenceType,
          referenceId: input.referenceId,
        },
      });
      await this.pushNotifications.sendToUsers([userId], {
        ...input,
        type: input.type.toLowerCase(),
        notificationId: notification.id,
      });
    } catch {
      this.logger.warn(`Không thể tạo thông báo cho người dùng ${userId}.`);
    }
  }

  async notifyRoles(
    roles: RoleCode[],
    input: SendNotificationInput,
    excludeUserIds: string[] = [],
  ): Promise<void> {
    try {
      const users = await this.prisma.user.findMany({
        where: {
          status: UserStatus.ACTIVE,
          id: excludeUserIds.length ? { notIn: excludeUserIds } : undefined,
          userRoles: { some: { role: { code: { in: roles } } } },
        },
        select: { id: true },
      });
      if (!users.length) return;
      await this.prisma.notification.createMany({
        data: users.map((user) => ({
          userId: user.id,
          title: input.title,
          message: input.message,
          type: input.type,
          referenceType: input.referenceType,
          referenceId: input.referenceId,
        })),
      });
      await this.pushNotifications.sendToUsers(
        users.map((user) => user.id),
        { ...input, type: input.type.toLowerCase() },
      );
    } catch {
      this.logger.warn('Không thể tạo thông báo theo vai trò.');
    }
  }

  async notifyRolesInBuilding(
    roles: RoleCode[],
    buildingId: string,
    input: SendNotificationInput,
    excludeUserIds: string[] = [],
  ): Promise<void> {
    try {
      const now = new Date();
      const users = await this.prisma.user.findMany({
        where: {
          status: UserStatus.ACTIVE,
          id: excludeUserIds.length ? { notIn: excludeUserIds } : undefined,
          userRoles: { some: { role: { code: { in: roles } } } },
          OR: [
            ...(roles.includes(RoleCode.ADMIN)
              ? [
                  {
                    userRoles: {
                      some: { role: { code: RoleCode.ADMIN } },
                    },
                  },
                ]
              : []),
            {
              staffBuildingAssignments: {
                some: {
                  buildingId,
                  isActive: true,
                  startDate: { lte: now },
                  OR: [{ endDate: null }, { endDate: { gte: now } }],
                },
              },
            },
          ],
        },
        select: { id: true },
      });
      if (!users.length) return;
      await this.prisma.notification.createMany({
        data: users.map((user) => ({
          userId: user.id,
          title: input.title,
          message: input.message,
          type: input.type,
          referenceType: input.referenceType,
          referenceId: input.referenceId,
        })),
      });
      await this.pushNotifications.sendToUsers(
        users.map((user) => user.id),
        { ...input, type: input.type.toLowerCase() },
      );
    } catch {
      this.logger.warn(
        `Không thể tạo thông báo theo vai trò cho tòa ${buildingId}.`,
      );
    }
  }

  async notifyUsers(
    userIds: string[],
    input: SendNotificationInput,
  ): Promise<void> {
    const uniqueUserIds = [...new Set(userIds)];
    if (!uniqueUserIds.length) return;
    try {
      await this.prisma.notification.createMany({
        data: uniqueUserIds.map((userId) => ({
          userId,
          title: input.title,
          message: input.message,
          type: input.type,
          referenceType: input.referenceType,
          referenceId: input.referenceId,
        })),
      });
      await this.pushNotifications.sendToUsers(uniqueUserIds, {
        ...input,
        type: input.type.toLowerCase(),
      });
    } catch {
      this.logger.warn('Không thể tạo thông báo cho danh sách người dùng.');
    }
  }

  async findAll(userId: string): Promise<object> {
    const items = await this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    return {
      items: items.map((item) => this.response(item)),
      unreadCount: items.filter((item) => item.readAt === null).length,
    };
  }

  async markAsRead(id: string, userId: string): Promise<object> {
    const current = await this.prisma.notification.findFirst({
      where: { id, userId },
    });
    if (!current) {
      throw new NotFoundException('Không tìm thấy thông báo.');
    }
    const item = current.readAt
      ? current
      : await this.prisma.notification.update({
          where: { id },
          data: { readAt: new Date() },
        });
    return this.response(item);
  }

  async markAllAsRead(userId: string): Promise<object> {
    const result = await this.prisma.notification.updateMany({
      where: { userId, readAt: null },
      data: { readAt: new Date() },
    });
    return { success: true, updated: result.count };
  }

  private response(item: Notification): object {
    return {
      id: item.id,
      userId: item.userId,
      title: item.title,
      message: item.message,
      type: item.type.toLowerCase(),
      referenceType: item.referenceType,
      referenceId: item.referenceId,
      isRead: item.readAt !== null,
      readAt: item.readAt,
      createdAt: item.createdAt,
    };
  }
}
