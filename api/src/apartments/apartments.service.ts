import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  ApartmentStatus,
  MembershipStatus,
  Prisma,
  RoleCode,
} from '../generated/prisma/client';
import type { AuthenticatedUser } from '../auth/auth.types';
import { BuildingAccessService } from '../building-access/building-access.service';
import { PrismaService } from '../database/prisma.service';
import type { SaveApartmentDto } from './dto/save-apartment.dto';

const apartmentInclude = { building: true } satisfies Prisma.ApartmentInclude;
type ApartmentWithBuilding = Prisma.ApartmentGetPayload<{
  include: typeof apartmentInclude;
}>;

@Injectable()
export class ApartmentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly buildingAccess: BuildingAccessService,
  ) {}

  async findBuildings(): Promise<object> {
    const items = await this.prisma.building.findMany({
      orderBy: { name: 'asc' },
      select: { id: true, code: true, name: true, address: true, floors: true },
    });
    return { items };
  }

  async findAll(user: AuthenticatedUser): Promise<object> {
    const isResidentOnly =
      user.roles.length === 0 ||
      user.roles.every((role) => role === RoleCode.RESIDENT);
    const buildingIds = isResidentOnly
      ? []
      : await this.buildingAccess.accessibleStaffBuildingIds(user);
    const apartments = await this.prisma.apartment.findMany({
      where: isResidentOnly
        ? {
            memberships: {
              some: {
                userId: user.id,
                status: MembershipStatus.ACTIVE,
              },
            },
          }
        : buildingIds === null
          ? undefined
          : { buildingId: { in: buildingIds } },
      include: apartmentInclude,
      orderBy: [{ building: { name: 'asc' } }, { code: 'asc' }],
    });
    return { items: apartments.map((item) => this.toResponse(item)) };
  }

  async create(
    dto: SaveApartmentDto,
    user: AuthenticatedUser,
  ): Promise<object> {
    const building = await this.findBuilding(dto.buildingName);
    await this.buildingAccess.assertBuildingAccess(user, building.id);
    try {
      const apartment = await this.prisma.apartment.create({
        data: {
          buildingId: building.id,
          code: dto.code,
          floor: dto.floor,
          area: dto.area,
          bedrooms: dto.bedrooms,
          status: dto.status,
        },
        include: apartmentInclude,
      });
      return this.toResponse(apartment);
    } catch (error: unknown) {
      this.rethrowKnownError(error, dto.code);
    }
  }

  async update(
    id: string,
    dto: SaveApartmentDto,
    user: AuthenticatedUser,
  ): Promise<object> {
    await this.ensureExists(id);
    await this.buildingAccess.assertApartmentAccess(user, id);
    const building = await this.findBuilding(dto.buildingName);
    await this.buildingAccess.assertBuildingAccess(user, building.id);
    try {
      const apartment = await this.prisma.apartment.update({
        where: { id },
        data: {
          buildingId: building.id,
          code: dto.code,
          floor: dto.floor,
          area: dto.area,
          bedrooms: dto.bedrooms,
          status: dto.status,
        },
        include: apartmentInclude,
      });
      return this.toResponse(apartment);
    } catch (error: unknown) {
      this.rethrowKnownError(error, dto.code);
    }
  }

  async updateStatus(
    id: string,
    status: ApartmentStatus,
    user: AuthenticatedUser,
  ): Promise<object> {
    await this.ensureExists(id);
    await this.buildingAccess.assertApartmentAccess(user, id);
    if (status !== ApartmentStatus.OCCUPIED) {
      const activeMembership = await this.prisma.apartmentMembership.findFirst({
        where: { apartmentId: id, status: 'ACTIVE' },
        select: { id: true },
      });
      if (activeMembership) {
        throw new ConflictException(
          'Căn hộ còn cư dân đang hiệu lực nên phải giữ trạng thái đang có người ở.',
        );
      }
    }

    const apartment = await this.prisma.apartment.update({
      where: { id },
      data: { status },
      include: apartmentInclude,
    });
    return this.toResponse(apartment);
  }

  async remove(id: string, user: AuthenticatedUser): Promise<void> {
    await this.buildingAccess.assertApartmentAccess(user, id);
    const apartment = await this.prisma.apartment.findUnique({
      where: { id },
      select: {
        _count: {
          select: {
            memberships: true,
            housingListings: true,
            housingContracts: true,
            temporaryStays: true,
            securityIncidents: true,
            invoices: true,
            maintenanceRequests: true,
            serviceRequests: true,
            amenityBookings: true,
          },
        },
      },
    });
    if (!apartment) throw new NotFoundException('Không tìm thấy căn hộ.');
    if (Object.values(apartment._count).some((count) => count > 0)) {
      throw new ConflictException(
        'Không thể xóa căn hộ đã có dữ liệu hoặc lịch sử liên quan.',
      );
    }
    await this.prisma.apartment.delete({ where: { id } });
  }

  private async findBuilding(nameOrCode: string) {
    const building = await this.prisma.building.findFirst({
      where: {
        OR: [
          { name: { equals: nameOrCode, mode: 'insensitive' } },
          { code: { equals: nameOrCode, mode: 'insensitive' } },
        ],
      },
      select: { id: true },
    });
    if (!building) {
      throw new NotFoundException(
        `Không tìm thấy tòa nhà “${nameOrCode}”. Hãy dùng tòa nhà đã có trong hệ thống.`,
      );
    }
    return building;
  }

  private async ensureExists(id: string): Promise<void> {
    const apartment = await this.prisma.apartment.findUnique({
      where: { id },
      select: { id: true },
    });
    if (!apartment) throw new NotFoundException('Không tìm thấy căn hộ.');
  }

  private toResponse(apartment: ApartmentWithBuilding): object {
    return {
      id: apartment.id,
      code: apartment.code,
      buildingName: apartment.building.name,
      floor: apartment.floor,
      area: Number(apartment.area),
      bedrooms: apartment.bedrooms,
      status: this.statusToApi(apartment.status),
    };
  }

  private statusToApi(status: ApartmentStatus): string {
    return status === ApartmentStatus.UNDER_MAINTENANCE
      ? 'underMaintenance'
      : status.toLowerCase();
  }

  private rethrowKnownError(error: unknown, code: string): never {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      throw new ConflictException(
        `Mã căn hộ ${code} đã tồn tại trong tòa nhà.`,
      );
    }
    throw error;
  }
}
