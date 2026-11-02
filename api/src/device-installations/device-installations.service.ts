import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import type { SaveDeviceInstallationDto } from './dto/save-device-installation.dto';

@Injectable()
export class DeviceInstallationsService {
  constructor(private readonly prisma: PrismaService) {}

  async save(userId: string, dto: SaveDeviceInstallationDto): Promise<object> {
    const item = await this.prisma.deviceInstallation.upsert({
      where: { firebaseToken: dto.firebaseToken },
      update: {
        userId,
        platform: dto.platform,
        deviceName: dto.deviceName?.trim() || null,
        isActive: true,
        lastSeenAt: new Date(),
      },
      create: {
        userId,
        firebaseToken: dto.firebaseToken,
        platform: dto.platform,
        deviceName: dto.deviceName?.trim() || null,
      },
    });
    return this.response(item);
  }

  async findMine(userId: string): Promise<object> {
    const items = await this.prisma.deviceInstallation.findMany({
      where: { userId },
      orderBy: [{ isActive: 'desc' }, { lastSeenAt: 'desc' }],
    });
    return { items: items.map((item) => this.response(item)) };
  }

  async deactivate(userId: string, firebaseToken: string): Promise<object> {
    const result = await this.prisma.deviceInstallation.updateMany({
      where: { userId, firebaseToken, isActive: true },
      data: { isActive: false, lastSeenAt: new Date() },
    });
    return { success: true, updated: result.count };
  }

  private response(item: {
    id: string;
    platform: string;
    deviceName: string | null;
    isActive: boolean;
    lastSeenAt: Date;
    createdAt: Date;
  }): object {
    return {
      id: item.id,
      platform: item.platform.toLowerCase(),
      deviceName: item.deviceName,
      isActive: item.isActive,
      lastSeenAt: item.lastSeenAt,
      createdAt: item.createdAt,
    };
  }
}
