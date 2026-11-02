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
  TemporaryStayStatus,
} from '../generated/prisma/client';
import type { CreateTemporaryStayDto } from './dto/create-temporary-stay.dto';
import type { ReviewTemporaryStayDto } from './dto/review-temporary-stay.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { BuildingAccessService } from '../building-access/building-access.service';

const include = {
  apartment: true,
  declaredBy: true,
  reviewedBy: true,
  checkedInBy: true,
  checkedOutBy: true,
} satisfies Prisma.TemporaryStayInclude;
type Stay = Prisma.TemporaryStayGetPayload<{ include: typeof include }>;

@Injectable()
export class TemporaryStaysService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly buildingAccess: BuildingAccessService,
  ) {}

  async findAll(user: AuthenticatedUser): Promise<object> {
    await this.prisma.temporaryStay.updateMany({
      where: {
        status: TemporaryStayStatus.APPROVED,
        endDate: { lt: new Date() },
      },
      data: { status: TemporaryStayStatus.EXPIRED },
    });
    const items = await this.prisma.temporaryStay.findMany({
      where: await this.stayWhere(user),
      include,
      orderBy: { createdAt: 'desc' },
    });
    return { items: items.map((item) => this.response(item)) };
  }

  async create(
    user: AuthenticatedUser,
    dto: CreateTemporaryStayDto,
  ): Promise<object> {
    const membership = await this.prisma.apartmentMembership.findFirst({
      where: {
        apartmentId: dto.apartmentId,
        userId: user.id,
        status: MembershipStatus.ACTIVE,
        type: { in: [MembershipType.OWNER, MembershipType.TENANT] },
      },
      select: { id: true, type: true },
    });
    if (!membership)
      throw new ForbiddenException(
        'Bạn không có quan hệ cư trú đang hiệu lực với căn hộ này.',
      );
    await this.assertCanDeclareGuests(
      user.id,
      dto.apartmentId,
      membership.type,
    );
    const startDate = new Date(dto.startDate);
    const endDate = new Date(dto.endDate);
    if (endDate < startDate)
      throw new BadRequestException(
        'Ngày kết thúc phải bằng hoặc sau ngày bắt đầu.',
      );
    const maximumEnd = new Date(startDate);
    maximumEnd.setUTCDate(maximumEnd.getUTCDate() + 30);
    if (endDate > maximumEnd)
      throw new BadRequestException(
        'Một lượt khách lưu trú không được vượt quá 30 ngày.',
      );
    const item = await this.prisma.temporaryStay.create({
      data: {
        apartmentId: dto.apartmentId,
        declaredById: user.id,
        guestFullName: dto.guestFullName,
        guestDateOfBirth: dto.guestDateOfBirth
          ? new Date(dto.guestDateOfBirth)
          : null,
        guestPhone: dto.guestPhone?.trim() || null,
        relationshipToResident: dto.relationshipToResident?.trim() || null,
        startDate,
        endDate,
        purpose: dto.purpose?.trim() || null,
      },
      include,
    });
    await this.notifications.notifyRolesInBuilding(
      [RoleCode.ADMIN, RoleCode.MANAGEMENT, RoleCode.RECEPTIONIST],
      item.apartment.buildingId,
      {
        title: 'Có đăng ký khách lưu trú mới',
        message: `${item.guestFullName} được đăng ký ở căn ${item.apartment.code}.`,
        type: NotificationType.SYSTEM,
        referenceType: 'temporary_stay',
        referenceId: item.id,
      },
      [user.id],
    );
    return this.response(item);
  }

  private async assertCanDeclareGuests(
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
        'Căn hộ đang có người thuê. Khách lưu trú do tài khoản người thuê khai báo.',
      );
    }
  }

  async cancel(id: string, user: AuthenticatedUser): Promise<object> {
    const current = await this.findOne(id);
    if (current.declaredById !== user.id)
      throw new ForbiddenException('Bạn không thể hủy đăng ký của người khác.');
    if (
      ![TemporaryStayStatus.PENDING, TemporaryStayStatus.APPROVED].some(
        (status) => status === current.status,
      )
    ) {
      throw new ConflictException('Đăng ký này không thể hủy.');
    }
    return this.response(
      await this.prisma.temporaryStay.update({
        where: { id },
        data: { status: TemporaryStayStatus.CANCELLED },
        include,
      }),
    );
  }

  async review(
    id: string,
    reviewer: AuthenticatedUser,
    dto: ReviewTemporaryStayDto,
  ): Promise<object> {
    const current = await this.findOne(id);
    await this.buildingAccess.assertApartmentAccess(
      reviewer,
      current.apartmentId,
    );
    if (current.status !== TemporaryStayStatus.PENDING)
      throw new ConflictException('Đăng ký này đã được xử lý.');
    const note = dto.note?.trim() ?? '';
    if (!dto.approved && note.length < 5)
      throw new BadRequestException(
        'Vui lòng nhập lý do từ chối ít nhất 5 ký tự.',
      );
    const updated = await this.prisma.temporaryStay.update({
      where: { id },
      data: {
        status: dto.approved
          ? TemporaryStayStatus.APPROVED
          : TemporaryStayStatus.REJECTED,
        reviewedById: reviewer.id,
        reviewedAt: new Date(),
        reviewNote: note || 'Đăng ký khách lưu trú đã được duyệt.',
      },
      include,
    });
    await this.notifications.notifyUser(updated.declaredById, {
      title: dto.approved
        ? 'Đăng ký khách lưu trú đã được duyệt'
        : 'Đăng ký khách lưu trú bị từ chối',
      message: `${updated.guestFullName}: ${updated.reviewNote ?? 'Đã được xử lý.'}`,
      type: NotificationType.SYSTEM,
      referenceType: 'temporary_stay',
      referenceId: updated.id,
    });
    return this.response(updated);
  }

  async checkIn(id: string, guard: AuthenticatedUser): Promise<object> {
    const current = await this.findOne(id);
    await this.buildingAccess.assertApartmentAccess(guard, current.apartmentId);
    if (current.status !== TemporaryStayStatus.APPROVED) {
      throw new ConflictException('Chỉ có thể xác nhận khách đã được duyệt.');
    }
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);
    if (today < current.startDate || today > current.endDate) {
      throw new ConflictException(
        'Khách chỉ được check-in trong thời gian lưu trú đã đăng ký.',
      );
    }
    const updated = await this.prisma.temporaryStay.update({
      where: { id },
      data: {
        status: TemporaryStayStatus.CHECKED_IN,
        checkedInById: guard.id,
        checkedInAt: new Date(),
      },
      include,
    });
    await this.notifications.notifyUser(updated.declaredById, {
      title: 'Khách đã check-in',
      message: `${updated.guestFullName} đã được bảo vệ xác nhận vào tòa.`,
      type: NotificationType.SYSTEM,
      referenceType: 'temporary_stay',
      referenceId: updated.id,
    });
    return this.response(updated);
  }

  async checkOut(id: string, guard: AuthenticatedUser): Promise<object> {
    const current = await this.findOne(id);
    await this.buildingAccess.assertApartmentAccess(guard, current.apartmentId);
    if (current.status !== TemporaryStayStatus.CHECKED_IN) {
      throw new ConflictException('Khách chưa check-in hoặc đã rời tòa.');
    }
    const updated = await this.prisma.temporaryStay.update({
      where: { id },
      data: {
        status: TemporaryStayStatus.CHECKED_OUT,
        checkedOutById: guard.id,
        checkedOutAt: new Date(),
      },
      include,
    });
    await this.notifications.notifyUser(updated.declaredById, {
      title: 'Khách đã check-out',
      message: `${updated.guestFullName} đã được bảo vệ xác nhận rời tòa.`,
      type: NotificationType.SYSTEM,
      referenceType: 'temporary_stay',
      referenceId: updated.id,
    });
    return this.response(updated);
  }

  private async findOne(id: string): Promise<Stay> {
    const item = await this.prisma.temporaryStay.findUnique({
      where: { id },
      include,
    });
    if (!item) {
      throw new NotFoundException('Không tìm thấy đăng ký khách lưu trú.');
    }
    return item;
  }
  private canReview(user: AuthenticatedUser): boolean {
    return user.roles.some((role) =>
      [RoleCode.ADMIN, RoleCode.MANAGEMENT, RoleCode.RECEPTIONIST].some(
        (allowed) => allowed === role,
      ),
    );
  }
  private canViewAll(user: AuthenticatedUser): boolean {
    return (
      this.canReview(user) ||
      user.roles.some((role) => role === RoleCode.SECURITY)
    );
  }

  private async stayWhere(
    user: AuthenticatedUser,
  ): Promise<Prisma.TemporaryStayWhereInput> {
    if (user.roles.includes(RoleCode.RESIDENT)) {
      return { declaredById: user.id };
    }
    if (user.roles.includes(RoleCode.ADMIN)) return {};

    const buildingIds =
      (await this.buildingAccess.accessibleStaffBuildingIds(user)) ?? [];
    const buildingScope: Prisma.TemporaryStayWhereInput = {
      apartment: { buildingId: { in: buildingIds } },
    };
    if (user.roles.includes(RoleCode.SECURITY) && !this.canReview(user)) {
      const now = new Date();
      return {
        ...buildingScope,
        OR: [
          {
            status: TemporaryStayStatus.APPROVED,
            startDate: { lte: now },
            endDate: { gte: now },
          },
          { status: TemporaryStayStatus.CHECKED_IN },
        ],
      };
    }
    if (this.canReview(user)) return buildingScope;
    return { declaredById: user.id };
  }
  private response(item: Stay): object {
    return {
      id: item.id,
      apartmentId: item.apartmentId,
      apartmentCode: item.apartment.code,
      declaredById: item.declaredById,
      declaredByName: item.declaredBy.fullName,
      guestFullName: item.guestFullName,
      guestDateOfBirth: item.guestDateOfBirth,
      guestPhone: item.guestPhone,
      relationshipToResident: item.relationshipToResident,
      startDate: item.startDate,
      endDate: item.endDate,
      purpose: item.purpose,
      status: item.status.toLowerCase(),
      reviewNote: item.reviewNote,
      reviewedByName: item.reviewedBy?.fullName ?? null,
      checkedInByName: item.checkedInBy?.fullName ?? null,
      checkedOutByName: item.checkedOutBy?.fullName ?? null,
      checkedInAt: item.checkedInAt,
      checkedOutAt: item.checkedOutAt,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    };
  }
}
