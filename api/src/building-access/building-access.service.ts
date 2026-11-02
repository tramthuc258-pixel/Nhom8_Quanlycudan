import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import { RoleCode } from '../generated/prisma/client';

@Injectable()
export class BuildingAccessService {
  constructor(private readonly prisma: PrismaService) {}

  isAdmin(user: AuthenticatedUser): boolean {
    return user.roles.includes(RoleCode.ADMIN);
  }

  async accessibleStaffBuildingIds(
    user: AuthenticatedUser,
  ): Promise<string[] | null> {
    if (this.isAdmin(user)) return null;

    const now = new Date();
    const assignments = await this.prisma.staffBuildingAssignment.findMany({
      where: {
        userId: user.id,
        isActive: true,
        startDate: { lte: now },
        OR: [{ endDate: null }, { endDate: { gte: now } }],
      },
      select: { buildingId: true },
    });
    return assignments.map((assignment) => assignment.buildingId);
  }

  async assertBuildingAccess(
    user: AuthenticatedUser,
    buildingId: string,
  ): Promise<void> {
    const buildingIds = await this.accessibleStaffBuildingIds(user);
    if (buildingIds === null || buildingIds.includes(buildingId)) return;
    throw new ForbiddenException(
      'Bạn không được phân công phụ trách tòa nhà của dữ liệu này.',
    );
  }

  async apartmentBuildingId(apartmentId: string): Promise<string> {
    const apartment = await this.prisma.apartment.findUnique({
      where: { id: apartmentId },
      select: { buildingId: true },
    });
    if (!apartment) throw new NotFoundException('Không tìm thấy căn hộ.');
    return apartment.buildingId;
  }

  async assertApartmentAccess(
    user: AuthenticatedUser,
    apartmentId: string,
  ): Promise<string> {
    const buildingId = await this.apartmentBuildingId(apartmentId);
    await this.assertBuildingAccess(user, buildingId);
    return buildingId;
  }
}
