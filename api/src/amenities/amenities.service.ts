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
  AmenityBookingStatus,
  MembershipStatus,
  MembershipType,
  NotificationType,
  Prisma,
  RoleCode,
} from '../generated/prisma/client';
import type { BlockAmenitySlotDto } from './dto/block-amenity-slot.dto';
import type { CreateAmenityBookingDto } from './dto/create-amenity-booking.dto';
import type { ReviewAmenityBookingDto } from './dto/review-amenity-booking.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { BuildingAccessService } from '../building-access/building-access.service';

const include = {
  amenity: true,
  resident: true,
  processedBy: true,
} satisfies Prisma.AmenityBookingInclude;
type Booking = Prisma.AmenityBookingGetPayload<{ include: typeof include }>;

@Injectable()
export class AmenitiesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly buildingAccess: BuildingAccessService,
  ) {}

  async catalog(user: AuthenticatedUser): Promise<object> {
    const items = await this.prisma.amenity.findMany({
      where: await this.catalogWhere(user),
      orderBy: [{ isActive: 'desc' }, { name: 'asc' }],
    });
    return { items: items.map((item) => this.amenityResponse(item)) };
  }

  async bookings(user: AuthenticatedUser): Promise<object> {
    const items = await this.prisma.amenityBooking.findMany({
      where: await this.bookingWhere(user),
      include,
      orderBy: { startAt: 'asc' },
    });
    return { items: items.map((item) => this.bookingResponse(item)) };
  }

  async create(
    user: AuthenticatedUser,
    dto: CreateAmenityBookingDto,
  ): Promise<object> {
    const amenity = await this.findAmenity(dto.amenityId);
    if (!amenity.isActive)
      throw new ConflictException('Tiện ích này hiện đang tạm ngưng.');
    const membership = await this.prisma.apartmentMembership.findFirst({
      where: {
        apartmentId: dto.apartmentId,
        userId: user.id,
        status: MembershipStatus.ACTIVE,
      },
      select: { id: true, type: true },
    });
    if (!membership)
      throw new ForbiddenException(
        'Bạn không có quan hệ cư trú đang hiệu lực với căn hộ này.',
      );
    await this.assertCanUseResidentAmenities(
      user.id,
      dto.apartmentId,
      membership.type,
    );
    if (dto.attendeeCount > amenity.capacity) {
      throw new BadRequestException(
        `Số người tham gia phải từ 1 đến ${amenity.capacity}.`,
      );
    }
    const startAt = new Date(dto.startAt);
    const endAt = new Date(
      startAt.getTime() + amenity.slotDurationMinutes * 60000,
    );
    this.validateTime(amenity, startAt, endAt);
    await this.ensureNoOverlap(amenity.id, startAt, endAt);
    const now = new Date();
    const item = await this.prisma.amenityBooking.create({
      data: {
        code: `TI-${now.getUTCFullYear()}-${randomUUID().slice(0, 8).toUpperCase()}`,
        amenityId: amenity.id,
        apartmentId: dto.apartmentId,
        residentId: user.id,
        startAt,
        endAt,
        attendeeCount: dto.attendeeCount,
        note: dto.note?.trim() || null,
      },
      include,
    });
    await this.notifications.notifyRolesInBuilding(
      [RoleCode.ADMIN, RoleCode.MANAGEMENT, RoleCode.RECEPTIONIST],
      item.amenity.buildingId,
      {
        title: 'Có lượt đặt tiện ích mới',
        message: `${item.code}: ${item.amenity.name} đang chờ duyệt.`,
        type: NotificationType.AMENITY,
        referenceType: 'amenity_booking',
        referenceId: item.id,
      },
      [user.id],
    );
    return this.bookingResponse(item);
  }

  private async assertCanUseResidentAmenities(
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
        'Căn hộ đang có người thuê. Tiện ích sinh hoạt do tài khoản người thuê đăng ký.',
      );
    }
  }

  async cancel(id: string, user: AuthenticatedUser): Promise<object> {
    const current = await this.findBooking(id);
    if (current.residentId !== user.id)
      throw new ForbiddenException(
        'Bạn không thể hủy lượt đặt của cư dân khác.',
      );
    if (current.status !== AmenityBookingStatus.PENDING)
      throw new ConflictException('Chỉ có thể hủy lượt đặt đang chờ duyệt.');
    const item = await this.prisma.amenityBooking.update({
      where: { id },
      data: {
        status: AmenityBookingStatus.CANCELLED,
        managementNote: 'Cư dân đã hủy lượt đặt.',
      },
      include,
    });
    return this.bookingResponse(item);
  }

  async review(
    id: string,
    actor: AuthenticatedUser,
    dto: ReviewAmenityBookingDto,
  ): Promise<object> {
    const current = await this.findBooking(id);
    await this.buildingAccess.assertBuildingAccess(
      actor,
      current.amenity.buildingId,
    );
    if (current.status !== AmenityBookingStatus.PENDING)
      throw new ConflictException('Lượt đặt này đã được xử lý.');
    const note = dto.note?.trim() ?? '';
    if (!dto.approved && note.length < 5)
      throw new BadRequestException(
        'Vui lòng nhập lý do từ chối ít nhất 5 ký tự.',
      );
    const item = await this.prisma.amenityBooking.update({
      where: { id },
      data: {
        status: dto.approved
          ? AmenityBookingStatus.APPROVED
          : AmenityBookingStatus.REJECTED,
        reviewedById: actor.id,
        reviewedAt: new Date(),
        managementNote: note || 'Ban quản lý đã duyệt lượt đặt.',
      },
      include,
    });
    await this.notifications.notifyUser(item.residentId, {
      title: dto.approved
        ? 'Lượt đặt tiện ích đã được duyệt'
        : 'Lượt đặt tiện ích bị từ chối',
      message: `${item.code}: ${item.managementNote ?? item.amenity.name}.`,
      type: NotificationType.AMENITY,
      referenceType: 'amenity_booking',
      referenceId: item.id,
    });
    return this.bookingResponse(item);
  }

  async checkIn(id: string, actor: AuthenticatedUser): Promise<object> {
    const current = await this.findBooking(id);
    await this.buildingAccess.assertBuildingAccess(
      actor,
      current.amenity.buildingId,
    );
    if (current.status !== AmenityBookingStatus.APPROVED) {
      throw new ConflictException('Chỉ check-in lượt đặt đã được duyệt.');
    }
    const now = new Date();
    const earliest = new Date(current.startAt.getTime() - 30 * 60 * 1000);
    if (now < earliest || now > current.endAt) {
      throw new ConflictException(
        'Chỉ check-in từ 30 phút trước giờ đặt đến khi kết thúc khung giờ.',
      );
    }
    const updated = await this.prisma.amenityBooking.update({
      where: { id },
      data: {
        status: AmenityBookingStatus.CHECKED_IN,
        processedById: actor.id,
        checkedInAt: now,
        managementNote: 'Lễ tân đã xác nhận cư dân sử dụng tiện ích.',
      },
      include,
    });
    return this.bookingResponse(updated);
  }

  async complete(id: string, actor: AuthenticatedUser): Promise<object> {
    const current = await this.findBooking(id);
    await this.buildingAccess.assertBuildingAccess(
      actor,
      current.amenity.buildingId,
    );
    if (current.status !== AmenityBookingStatus.CHECKED_IN) {
      throw new ConflictException('Lượt đặt chưa được check-in.');
    }
    const updated = await this.prisma.amenityBooking.update({
      where: { id },
      data: {
        status: AmenityBookingStatus.COMPLETED,
        processedById: actor.id,
        completedAt: new Date(),
        managementNote: 'Đã hoàn tất sử dụng tiện ích.',
      },
      include,
    });
    await this.notifications.notifyUser(updated.residentId, {
      title: 'Lượt sử dụng tiện ích đã hoàn tất',
      message: `${updated.code}: ${updated.amenity.name}.`,
      type: NotificationType.AMENITY,
      referenceType: 'amenity_booking',
      referenceId: updated.id,
    });
    return this.bookingResponse(updated);
  }

  async markNoShow(id: string, actor: AuthenticatedUser): Promise<object> {
    const current = await this.findBooking(id);
    await this.buildingAccess.assertBuildingAccess(
      actor,
      current.amenity.buildingId,
    );
    if (current.status !== AmenityBookingStatus.APPROVED) {
      throw new ConflictException('Chỉ ghi nhận vắng mặt cho lượt đã duyệt.');
    }
    if (new Date() <= current.endAt) {
      throw new ConflictException(
        'Chỉ ghi nhận vắng mặt sau khi khung giờ đã kết thúc.',
      );
    }
    const updated = await this.prisma.amenityBooking.update({
      where: { id },
      data: {
        status: AmenityBookingStatus.NO_SHOW,
        processedById: actor.id,
        completedAt: new Date(),
        managementNote: 'Cư dân không đến sử dụng tiện ích.',
      },
      include,
    });
    await this.notifications.notifyUser(updated.residentId, {
      title: 'Đã ghi nhận không sử dụng tiện ích',
      message: `${updated.code}: bạn không check-in trong khung giờ đã đặt.`,
      type: NotificationType.AMENITY,
      referenceType: 'amenity_booking',
      referenceId: updated.id,
    });
    return this.bookingResponse(updated);
  }

  async block(
    user: AuthenticatedUser,
    dto: BlockAmenitySlotDto,
  ): Promise<object> {
    const amenity = await this.findAmenity(dto.amenityId);
    await this.buildingAccess.assertBuildingAccess(user, amenity.buildingId);
    const startAt = new Date(dto.startAt);
    const endAt = new Date(dto.endAt);
    if (endAt <= startAt)
      throw new BadRequestException('Khung giờ khóa không hợp lệ.');
    this.validateHours(amenity, startAt, endAt);
    await this.ensureNoOverlap(amenity.id, startAt, endAt);
    const now = new Date();
    const item = await this.prisma.amenityBooking.create({
      data: {
        code: `KHOA-${now.getUTCFullYear()}-${randomUUID().slice(0, 8).toUpperCase()}`,
        amenityId: amenity.id,
        apartmentId: null,
        residentId: user.id,
        startAt,
        endAt,
        attendeeCount: 0,
        note: dto.note?.trim() || 'Khóa để bảo trì.',
        status: AmenityBookingStatus.BLOCKED,
        managementNote: 'Khung giờ được ban quản lý khóa.',
      },
      include,
    });
    return this.bookingResponse(item);
  }

  async toggle(id: string, user: AuthenticatedUser): Promise<object> {
    const amenity = await this.findAmenity(id);
    await this.buildingAccess.assertBuildingAccess(user, amenity.buildingId);
    return this.amenityResponse(
      await this.prisma.amenity.update({
        where: { id },
        data: { isActive: !amenity.isActive },
      }),
    );
  }

  private async findAmenity(id: string) {
    const item = await this.prisma.amenity.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('Không tìm thấy tiện ích.');
    return item;
  }
  private async findBooking(id: string): Promise<Booking> {
    const item = await this.prisma.amenityBooking.findUnique({
      where: { id },
      include,
    });
    if (!item) throw new NotFoundException('Không tìm thấy lượt đặt tiện ích.');
    return item;
  }
  private async ensureNoOverlap(
    amenityId: string,
    startAt: Date,
    endAt: Date,
  ): Promise<void> {
    const overlap = await this.prisma.amenityBooking.findFirst({
      where: {
        amenityId,
        status: {
          in: [
            AmenityBookingStatus.PENDING,
            AmenityBookingStatus.APPROVED,
            AmenityBookingStatus.BLOCKED,
          ],
        },
        startAt: { lt: endAt },
        endAt: { gt: startAt },
      },
      select: { id: true },
    });
    if (overlap)
      throw new ConflictException(
        'Khung giờ này đã có lượt đặt hoặc đang bị khóa.',
      );
  }
  private validateTime(
    amenity: { openingHour: number; closingHour: number },
    start: Date,
    end: Date,
  ): void {
    if (start <= new Date())
      throw new BadRequestException(
        'Chỉ có thể đặt khung giờ trong tương lai.',
      );
    this.validateHours(amenity, start, end);
  }
  private validateHours(
    amenity: { openingHour: number; closingHour: number },
    start: Date,
    end: Date,
  ): void {
    const offset = 7 * 60 * 60 * 1000;
    const localStart = new Date(start.getTime() + offset);
    const localEnd = new Date(end.getTime() + offset);
    const sameDay =
      localStart.toISOString().slice(0, 10) ===
      localEnd.toISOString().slice(0, 10);
    const startMinutes =
      localStart.getUTCHours() * 60 + localStart.getUTCMinutes();
    const endMinutes = localEnd.getUTCHours() * 60 + localEnd.getUTCMinutes();
    if (
      !sameDay ||
      startMinutes < amenity.openingHour * 60 ||
      endMinutes > amenity.closingHour * 60
    ) {
      throw new BadRequestException(
        `Khung giờ phải nằm trong ${amenity.openingHour}:00–${amenity.closingHour}:00.`,
      );
    }
  }
  private async catalogWhere(
    user: AuthenticatedUser,
  ): Promise<Prisma.AmenityWhereInput> {
    if (user.roles.includes(RoleCode.ADMIN)) return {};
    if (user.roles.includes(RoleCode.RESIDENT)) {
      return {
        isActive: true,
        building: {
          apartments: {
            some: {
              memberships: {
                some: {
                  userId: user.id,
                  status: MembershipStatus.ACTIVE,
                },
              },
            },
          },
        },
      };
    }
    const canManage = user.roles.some(
      (role) => role === RoleCode.MANAGEMENT || role === RoleCode.RECEPTIONIST,
    );
    if (!canManage) return { buildingId: { in: [] } };
    const buildingIds =
      (await this.buildingAccess.accessibleStaffBuildingIds(user)) ?? [];
    return { buildingId: { in: buildingIds } };
  }

  private async bookingWhere(
    user: AuthenticatedUser,
  ): Promise<Prisma.AmenityBookingWhereInput> {
    if (user.roles.includes(RoleCode.RESIDENT)) {
      return {
        OR: [
          { residentId: user.id },
          {
            status: AmenityBookingStatus.BLOCKED,
            amenity: {
              building: {
                apartments: {
                  some: {
                    memberships: {
                      some: {
                        userId: user.id,
                        status: MembershipStatus.ACTIVE,
                      },
                    },
                  },
                },
              },
            },
          },
        ],
      };
    }
    if (user.roles.includes(RoleCode.ADMIN)) return {};
    const canManage = user.roles.some(
      (role) => role === RoleCode.MANAGEMENT || role === RoleCode.RECEPTIONIST,
    );
    if (!canManage) return { amenity: { buildingId: { in: [] } } };
    const buildingIds =
      (await this.buildingAccess.accessibleStaffBuildingIds(user)) ?? [];
    return { amenity: { buildingId: { in: buildingIds } } };
  }
  private amenityResponse(item: {
    id: string;
    name: string;
    description: string | null;
    category: string;
    capacity: number;
    slotDurationMinutes: number;
    openingHour: number;
    closingHour: number;
    fee: Prisma.Decimal;
    isActive: boolean;
  }): object {
    return {
      id: item.id,
      name: item.name,
      description: item.description ?? '',
      category: this.toCamel(item.category),
      capacity: item.capacity,
      slotDurationMinutes: item.slotDurationMinutes,
      openingHour: item.openingHour,
      closingHour: item.closingHour,
      fee: item.fee.toNumber(),
      isActive: item.isActive,
    };
  }
  private bookingResponse(item: Booking): object {
    return {
      id: item.id,
      code: item.code,
      amenityId: item.amenityId,
      amenityName: item.amenity.name,
      apartmentId: item.apartmentId ?? '',
      residentId: item.residentId,
      residentName:
        item.status === AmenityBookingStatus.BLOCKED
          ? 'Ban quản lý'
          : item.resident.fullName,
      startAt: item.startAt,
      endAt: item.endAt,
      attendeeCount: item.attendeeCount,
      note: item.note ?? '',
      status: this.toCamel(item.status),
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      managementNote: item.managementNote,
      processedByName: item.processedBy?.fullName ?? null,
      checkedInAt: item.checkedInAt,
      completedAt: item.completedAt,
    };
  }
  private toCamel(value: string): string {
    return value
      .toLowerCase()
      .replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase());
  }
}
