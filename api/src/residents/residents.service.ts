import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  ApartmentStatus,
  HouseholdMemberStatus,
  MembershipStatus,
  MembershipType,
  NotificationType,
  Prisma,
  ResidenceVerificationStatus,
  RoleCode,
  UserStatus,
} from '../generated/prisma/client';
import type { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { BuildingAccessService } from '../building-access/building-access.service';
import type { CreateHouseholdMemberDto } from './dto/create-household-member.dto';
import type { CreateMembershipDto } from './dto/create-membership.dto';
import type { CreateResidenceVerificationDto } from './dto/create-residence-verification.dto';
import type { ReviewResidenceVerificationDto } from './dto/review-residence-verification.dto';

const staffRoles = new Set<RoleCode>([RoleCode.ADMIN, RoleCode.MANAGEMENT]);

@Injectable()
export class ResidentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly buildingAccess: BuildingAccessService,
  ) {}

  async findResidents(currentUser: AuthenticatedUser): Promise<object> {
    const userWhere = await this.residentWhere(currentUser);

    const residents = await this.prisma.user.findMany({
      where: { ...userWhere, status: UserStatus.ACTIVE },
      orderBy: { fullName: 'asc' },
      select: { id: true, fullName: true, phone: true, email: true },
    });

    return {
      items: residents.map((resident) => ({
        ...resident,
        phone: resident.phone ?? '',
      })),
    };
  }

  async findMemberships(currentUser: AuthenticatedUser): Promise<object> {
    const hasStaffAccess = this.hasStaffAccess(currentUser);
    const apartmentIds = hasStaffAccess
      ? []
      : await this.accessibleApartmentIds(currentUser.id);
    const staffBuildingIds = hasStaffAccess
      ? await this.buildingAccess.accessibleStaffBuildingIds(currentUser)
      : [];
    const memberships = await this.prisma.apartmentMembership.findMany({
      where: {
        type: { in: [MembershipType.OWNER, MembershipType.TENANT] },
        ...(!hasStaffAccess
          ? {
              OR: [
                { userId: currentUser.id },
                {
                  apartmentId: { in: apartmentIds },
                  status: MembershipStatus.ACTIVE,
                },
              ],
            }
          : staffBuildingIds === null
            ? {}
            : { apartment: { buildingId: { in: staffBuildingIds } } }),
      },
      orderBy: [{ status: 'asc' }, { startDate: 'desc' }],
    });
    return {
      items: memberships.map((item) => this.toMembershipResponse(item)),
    };
  }

  async createMembership(
    dto: CreateMembershipDto,
    currentUser: AuthenticatedUser,
  ): Promise<object> {
    await this.buildingAccess.assertApartmentAccess(
      currentUser,
      dto.apartmentId,
    );
    const startDate = new Date(dto.startDate);
    const endDate = dto.endDate ? new Date(dto.endDate) : null;
    if (endDate && endDate < startDate) {
      throw new BadRequestException('Ngày kết thúc phải sau ngày bắt đầu.');
    }

    return this.prisma.$transaction(async (transaction) => {
      const apartment = await transaction.apartment.findUnique({
        where: { id: dto.apartmentId },
        select: { id: true, status: true },
      });
      if (!apartment) throw new NotFoundException('Không tìm thấy căn hộ.');

      const resident = dto.residentId
        ? await transaction.user.findUnique({ where: { id: dto.residentId } })
        : await transaction.user.findUnique({ where: { email: dto.email } });
      if (!resident || resident.status !== UserStatus.ACTIVE) {
        throw new NotFoundException(
          'Cư dân chưa có tài khoản hoạt động. Hãy yêu cầu cư dân đăng ký trước.',
        );
      }
      if (resident.email.toLowerCase() !== dto.email) {
        throw new BadRequestException(
          'Email không khớp với tài khoản cư dân đã chọn.',
        );
      }

      const duplicated = await transaction.apartmentMembership.findFirst({
        where: {
          apartmentId: dto.apartmentId,
          userId: resident.id,
          status: MembershipStatus.ACTIVE,
        },
        select: { id: true },
      });
      if (duplicated) {
        throw new ConflictException(
          `${resident.fullName} đã có quan hệ đang hiệu lực với căn hộ.`,
        );
      }

      if (
        dto.type === MembershipType.OWNER ||
        dto.type === MembershipType.TENANT
      ) {
        const activeRepresentative =
          await transaction.apartmentMembership.findFirst({
            where: {
              apartmentId: dto.apartmentId,
              type: dto.type,
              status: MembershipStatus.ACTIVE,
            },
            select: { id: true },
          });
        if (activeRepresentative) {
          throw new ConflictException(
            dto.type === MembershipType.OWNER
              ? 'Căn hộ đã có một chủ sở hữu đang hiệu lực.'
              : 'Căn hộ đã có một người thuê đại diện đang hiệu lực.',
          );
        }
      }

      const residentRole = await transaction.role.findUnique({
        where: { code: RoleCode.RESIDENT },
        select: { id: true },
      });
      if (!residentRole) {
        throw new ConflictException('Vai trò cư dân chưa được khởi tạo.');
      }
      await transaction.userRole.upsert({
        where: { userId: resident.id },
        update: { roleId: residentRole.id },
        create: { userId: resident.id, roleId: residentRole.id },
      });

      if (!resident.phone) {
        await transaction.user.update({
          where: { id: resident.id },
          data: { phone: dto.phone },
        });
      }

      const membership = await transaction.apartmentMembership.create({
        data: {
          apartmentId: dto.apartmentId,
          userId: resident.id,
          type: dto.type,
          startDate,
          endDate,
          isPrimary: true,
        },
      });
      if (apartment.status === ApartmentStatus.VACANT) {
        await transaction.apartment.update({
          where: { id: apartment.id },
          data: { status: ApartmentStatus.OCCUPIED },
        });
      }
      return this.toMembershipResponse(membership);
    });
  }

  async endMembership(
    id: string,
    currentUser: AuthenticatedUser,
  ): Promise<object> {
    const scopedMembership = await this.prisma.apartmentMembership.findUnique({
      where: { id },
      select: { apartmentId: true },
    });
    if (!scopedMembership)
      throw new NotFoundException('Không tìm thấy quan hệ cư trú.');
    await this.buildingAccess.assertApartmentAccess(
      currentUser,
      scopedMembership.apartmentId,
    );
    return this.prisma.$transaction(async (transaction) => {
      const membership = await transaction.apartmentMembership.findUnique({
        where: { id },
      });
      if (!membership) {
        throw new NotFoundException('Không tìm thấy quan hệ cư trú.');
      }
      if (membership.status === MembershipStatus.ENDED) {
        return this.toMembershipResponse(membership);
      }

      const today = new Date();
      today.setUTCHours(0, 0, 0, 0);
      const ended = await transaction.apartmentMembership.update({
        where: { id },
        data: {
          status: MembershipStatus.ENDED,
          endDate: membership.endDate ?? today,
        },
      });
      const remaining = await transaction.apartmentMembership.count({
        where: {
          apartmentId: membership.apartmentId,
          status: MembershipStatus.ACTIVE,
        },
      });
      if (remaining === 0) {
        await transaction.apartment.updateMany({
          where: {
            id: membership.apartmentId,
            status: ApartmentStatus.OCCUPIED,
          },
          data: { status: ApartmentStatus.VACANT },
        });
      }
      return this.toMembershipResponse(ended);
    });
  }

  async findHouseholdMembers(currentUser: AuthenticatedUser): Promise<object> {
    const hasStaffAccess = this.hasStaffAccess(currentUser);
    const apartmentIds = hasStaffAccess
      ? null
      : await this.accessibleApartmentIds(currentUser.id);
    const staffBuildingIds = hasStaffAccess
      ? await this.buildingAccess.accessibleStaffBuildingIds(currentUser)
      : [];
    const members = await this.prisma.householdMember.findMany({
      where: hasStaffAccess
        ? staffBuildingIds === null
          ? undefined
          : { apartment: { buildingId: { in: staffBuildingIds } } }
        : {
            apartmentId: { in: apartmentIds ?? [] },
            createdById: currentUser.id,
          },
      orderBy: [{ status: 'asc' }, { fullName: 'asc' }],
    });
    return {
      items: members.map((item) => this.toHouseholdMemberResponse(item)),
    };
  }

  async createHouseholdMember(
    dto: CreateHouseholdMemberDto,
    currentUser: AuthenticatedUser,
  ): Promise<object> {
    await this.assertApartmentAccess(dto.apartmentId, currentUser);
    await this.assertCanManagePersonalHousehold(dto.apartmentId, currentUser);
    const startDate = new Date(dto.startDate);
    const dateOfBirth = dto.dateOfBirth ? new Date(dto.dateOfBirth) : null;
    if (dateOfBirth && dateOfBirth > new Date()) {
      throw new BadRequestException('Ngày sinh không được ở trong tương lai.');
    }

    const duplicated = await this.prisma.householdMember.findFirst({
      where: {
        apartmentId: dto.apartmentId,
        status: HouseholdMemberStatus.ACTIVE,
        fullName: { equals: dto.fullName, mode: 'insensitive' },
        dateOfBirth,
      },
      select: { id: true },
    });
    if (duplicated) {
      throw new ConflictException(
        'Thành viên này đã có trong danh sách cư trú của căn hộ.',
      );
    }

    const member = await this.prisma.householdMember.create({
      data: {
        apartmentId: dto.apartmentId,
        createdById: currentUser.id,
        fullName: dto.fullName,
        dateOfBirth,
        phone: dto.phone?.trim() || null,
        relationship: dto.relationship,
        startDate,
      },
    });
    return this.toHouseholdMemberResponse(member);
  }

  async endHouseholdMember(
    id: string,
    currentUser: AuthenticatedUser,
  ): Promise<object> {
    const member = await this.prisma.householdMember.findUnique({
      where: { id },
    });
    if (!member)
      throw new NotFoundException('Không tìm thấy thành viên trong hộ.');
    await this.assertApartmentAccess(member.apartmentId, currentUser);
    await this.assertCanManagePersonalHousehold(
      member.apartmentId,
      currentUser,
    );
    if (
      !this.hasStaffAccess(currentUser) &&
      member.createdById !== currentUser.id
    ) {
      throw new ForbiddenException(
        'Bạn chỉ được cập nhật thành viên do chính mình khai báo.',
      );
    }
    if (member.status === HouseholdMemberStatus.ENDED) {
      return this.toHouseholdMemberResponse(member);
    }
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);
    const ended = await this.prisma.householdMember.update({
      where: { id },
      data: { status: HouseholdMemberStatus.ENDED, endDate: today },
    });
    return this.toHouseholdMemberResponse(ended);
  }

  async getMyResidenceVerification(
    currentUser: AuthenticatedUser,
  ): Promise<object> {
    const membership = await this.prisma.apartmentMembership.findFirst({
      where: {
        userId: currentUser.id,
        status: MembershipStatus.ACTIVE,
        type: { in: [MembershipType.OWNER, MembershipType.TENANT] },
      },
      orderBy: { startDate: 'desc' },
      include: {
        apartment: {
          include: {
            building: true,
            memberships: {
              where: {
                status: MembershipStatus.ACTIVE,
                type: { in: [MembershipType.OWNER, MembershipType.TENANT] },
              },
              select: { type: true },
            },
          },
        },
      },
    });
    if (membership) {
      return {
        state: 'approved',
        membership: {
          ...this.toMembershipResponse(membership),
          apartment: {
            id: membership.apartment.id,
            code: membership.apartment.code,
            buildingName: membership.apartment.building.name,
          },
          privacy: {
            hasVerifiedOwner: membership.apartment.memberships.some(
              (item) => item.type === MembershipType.OWNER,
            ),
            hasActiveTenant: membership.apartment.memberships.some(
              (item) => item.type === MembershipType.TENANT,
            ),
          },
        },
      };
    }

    const request = await this.prisma.residenceVerificationRequest.findFirst({
      where: { userId: currentUser.id },
      orderBy: { createdAt: 'desc' },
      include: { apartment: { include: { building: true } } },
    });
    if (!request) return { state: 'notSubmitted', request: null };
    return {
      state: request.status.toLowerCase(),
      request: this.toVerificationResponse(request),
    };
  }

  async findResidenceVerificationApartments(): Promise<object> {
    const apartments = await this.prisma.apartment.findMany({
      include: { building: true },
      orderBy: [{ building: { name: 'asc' } }, { code: 'asc' }],
    });
    return {
      items: apartments.map((apartment) => ({
        id: apartment.id,
        code: apartment.code,
        buildingName: apartment.building.name,
        floor: apartment.floor,
        area: Number(apartment.area),
        bedrooms: apartment.bedrooms,
        status:
          apartment.status === ApartmentStatus.UNDER_MAINTENANCE
            ? 'underMaintenance'
            : apartment.status.toLowerCase(),
      })),
    };
  }

  async createResidenceVerification(
    dto: CreateResidenceVerificationDto,
    currentUser: AuthenticatedUser,
  ): Promise<object> {
    const startDate = new Date(dto.startDate);
    const result = await this.prisma.$transaction(async (transaction) => {
      const [apartment, activeMembership, pendingRequest] = await Promise.all([
        transaction.apartment.findUnique({
          where: { id: dto.apartmentId },
          include: { building: true },
        }),
        transaction.apartmentMembership.findFirst({
          where: {
            userId: currentUser.id,
            status: MembershipStatus.ACTIVE,
          },
          select: { id: true },
        }),
        transaction.residenceVerificationRequest.findFirst({
          where: {
            userId: currentUser.id,
            status: ResidenceVerificationStatus.PENDING,
          },
          select: { id: true },
        }),
      ]);
      if (!apartment) throw new NotFoundException('Không tìm thấy căn hộ.');
      if (activeMembership) {
        throw new ConflictException(
          'Tài khoản đã được xác minh với một căn hộ đang hiệu lực.',
        );
      }
      if (pendingRequest) {
        throw new ConflictException(
          'Bạn đã có một yêu cầu đang chờ ban quản lý xét duyệt.',
        );
      }
      const occupiedSlot = await transaction.apartmentMembership.findFirst({
        where: {
          apartmentId: dto.apartmentId,
          type: dto.type,
          status: MembershipStatus.ACTIVE,
        },
        select: { id: true },
      });
      if (occupiedSlot) {
        throw new ConflictException(
          dto.type === MembershipType.OWNER
            ? 'Căn hộ đã có tài khoản chủ sở hữu đang hiệu lực.'
            : 'Căn hộ đã có tài khoản người thuê đang hiệu lực.',
        );
      }
      await transaction.user.update({
        where: { id: currentUser.id },
        data: { phone: dto.contactPhone.trim() },
      });
      return transaction.residenceVerificationRequest.create({
        data: {
          userId: currentUser.id,
          apartmentId: dto.apartmentId,
          type: dto.type,
          startDate,
          note: dto.note?.trim() || null,
        },
        include: {
          user: {
            select: { id: true, fullName: true, email: true, phone: true },
          },
          apartment: { include: { building: true } },
        },
      });
    });

    await this.notificationsService.notifyRolesInBuilding(
      [RoleCode.ADMIN, RoleCode.MANAGEMENT],
      result.apartment.buildingId,
      {
        title: 'Có yêu cầu xác minh cư dân mới',
        message: `${currentUser.fullName} vừa gửi yêu cầu xác minh căn hộ ${result.apartment.code}.`,
        type: NotificationType.SYSTEM,
        referenceType: 'residence_verification',
        referenceId: result.id,
      },
    );
    return this.toVerificationResponse(result);
  }

  async findResidenceVerifications(
    currentUser: AuthenticatedUser,
  ): Promise<object> {
    const buildingIds =
      await this.buildingAccess.accessibleStaffBuildingIds(currentUser);
    const items = await this.prisma.residenceVerificationRequest.findMany({
      where:
        buildingIds === null
          ? undefined
          : { apartment: { buildingId: { in: buildingIds } } },
      orderBy: [{ status: 'desc' }, { createdAt: 'desc' }],
      include: {
        user: {
          select: { id: true, fullName: true, email: true, phone: true },
        },
        reviewedBy: { select: { id: true, fullName: true } },
        apartment: {
          include: {
            building: true,
            memberships: {
              where: { status: MembershipStatus.ACTIVE },
              include: {
                user: { select: { id: true, fullName: true, email: true } },
              },
            },
          },
        },
      },
    });
    return { items: items.map((item) => this.toVerificationResponse(item)) };
  }

  async approveResidenceVerification(
    id: string,
    dto: ReviewResidenceVerificationDto,
    currentUser: AuthenticatedUser,
  ): Promise<object> {
    if (!dto.verificationBasis?.trim()) {
      throw new BadRequestException('Vui lòng chọn căn cứ xác minh.');
    }
    const scopedRequest =
      await this.prisma.residenceVerificationRequest.findUnique({
        where: { id },
        select: { apartmentId: true },
      });
    if (!scopedRequest)
      throw new NotFoundException('Không tìm thấy yêu cầu xác minh.');
    await this.buildingAccess.assertApartmentAccess(
      currentUser,
      scopedRequest.apartmentId,
    );
    const verificationBasis = dto.verificationBasis.trim();
    const result = await this.prisma.$transaction(async (transaction) => {
      const request = await transaction.residenceVerificationRequest.findUnique(
        {
          where: { id },
          include: { apartment: { include: { building: true } } },
        },
      );
      if (!request)
        throw new NotFoundException('Không tìm thấy yêu cầu xác minh.');
      if (request.status !== ResidenceVerificationStatus.PENDING) {
        throw new ConflictException('Yêu cầu này đã được xử lý trước đó.');
      }
      const [existingForUser, occupiedSlot] = await Promise.all([
        transaction.apartmentMembership.findFirst({
          where: { userId: request.userId, status: MembershipStatus.ACTIVE },
          select: { id: true },
        }),
        transaction.apartmentMembership.findFirst({
          where: {
            apartmentId: request.apartmentId,
            type: request.type,
            status: MembershipStatus.ACTIVE,
          },
          select: { id: true },
        }),
      ]);
      if (existingForUser) {
        throw new ConflictException(
          'Tài khoản này đã được liên kết với căn hộ khác.',
        );
      }
      if (occupiedSlot) {
        throw new ConflictException(
          request.type === MembershipType.OWNER
            ? 'Căn hộ đã có một chủ sở hữu đang hiệu lực.'
            : 'Căn hộ đã có một người thuê đại diện đang hiệu lực.',
        );
      }

      const residentRole = await transaction.role.findUnique({
        where: { code: RoleCode.RESIDENT },
        select: { id: true },
      });
      if (!residentRole)
        throw new ConflictException('Vai trò cư dân chưa được khởi tạo.');
      await transaction.userRole.upsert({
        where: { userId: request.userId },
        update: { roleId: residentRole.id },
        create: { userId: request.userId, roleId: residentRole.id },
      });
      await transaction.apartmentMembership.create({
        data: {
          apartmentId: request.apartmentId,
          userId: request.userId,
          type: request.type,
          startDate: request.startDate,
          isPrimary: true,
        },
      });
      if (request.apartment.status === ApartmentStatus.VACANT) {
        await transaction.apartment.update({
          where: { id: request.apartmentId },
          data: { status: ApartmentStatus.OCCUPIED },
        });
      }
      return transaction.residenceVerificationRequest.update({
        where: { id },
        data: {
          status: ResidenceVerificationStatus.APPROVED,
          verificationBasis,
          reviewNote: dto.reviewNote?.trim() || null,
          reviewedById: currentUser.id,
          reviewedAt: new Date(),
        },
        include: { apartment: { include: { building: true } } },
      });
    });
    await this.notificationsService.notifyUser(result.userId, {
      title: 'Yêu cầu cư dân đã được duyệt',
      message: `Tài khoản của bạn đã được liên kết với căn hộ ${result.apartment.code}.`,
      type: NotificationType.SYSTEM,
      referenceType: 'residence_verification',
      referenceId: result.id,
    });
    return this.toVerificationResponse(result);
  }

  async rejectResidenceVerification(
    id: string,
    dto: ReviewResidenceVerificationDto,
    currentUser: AuthenticatedUser,
  ): Promise<object> {
    if (!dto.reviewNote?.trim()) {
      throw new BadRequestException('Vui lòng nhập lý do từ chối.');
    }
    const current = await this.prisma.residenceVerificationRequest.findUnique({
      where: { id },
      include: { apartment: { include: { building: true } } },
    });
    if (!current)
      throw new NotFoundException('Không tìm thấy yêu cầu xác minh.');
    await this.buildingAccess.assertApartmentAccess(
      currentUser,
      current.apartmentId,
    );
    if (current.status !== ResidenceVerificationStatus.PENDING) {
      throw new ConflictException('Yêu cầu này đã được xử lý trước đó.');
    }
    const result = await this.prisma.residenceVerificationRequest.update({
      where: { id },
      data: {
        status: ResidenceVerificationStatus.REJECTED,
        reviewNote: dto.reviewNote.trim(),
        reviewedById: currentUser.id,
        reviewedAt: new Date(),
      },
      include: { apartment: { include: { building: true } } },
    });
    await this.notificationsService.notifyUser(result.userId, {
      title: 'Yêu cầu cư dân cần bổ sung',
      message: dto.reviewNote.trim(),
      type: NotificationType.SYSTEM,
      referenceType: 'residence_verification',
      referenceId: result.id,
    });
    return this.toVerificationResponse(result);
  }

  private hasStaffAccess(user: AuthenticatedUser): boolean {
    return user.roles.some((role) => staffRoles.has(role));
  }

  private async residentWhere(
    currentUser: AuthenticatedUser,
  ): Promise<Prisma.UserWhereInput> {
    if (currentUser.roles.includes(RoleCode.ADMIN)) {
      return { userRoles: { some: { role: { code: RoleCode.RESIDENT } } } };
    }
    if (currentUser.roles.includes(RoleCode.MANAGEMENT)) {
      const buildingIds =
        (await this.buildingAccess.accessibleStaffBuildingIds(currentUser)) ??
        [];
      return {
        userRoles: { some: { role: { code: RoleCode.RESIDENT } } },
        apartmentMemberships: {
          some: {
            apartment: { buildingId: { in: buildingIds } },
            status: MembershipStatus.ACTIVE,
          },
        },
      };
    }
    return this.householdUserWhere(currentUser.id);
  }

  private async accessibleApartmentIds(userId: string): Promise<string[]> {
    const memberships = await this.prisma.apartmentMembership.findMany({
      where: {
        userId,
        status: MembershipStatus.ACTIVE,
        type: { in: [MembershipType.OWNER, MembershipType.TENANT] },
      },
      select: { apartmentId: true },
    });
    return memberships.map((item) => item.apartmentId);
  }

  private async householdUserWhere(
    userId: string,
  ): Promise<Prisma.UserWhereInput> {
    const apartmentIds = await this.accessibleApartmentIds(userId);
    return {
      OR: [
        { id: userId },
        {
          apartmentMemberships: {
            some: {
              apartmentId: { in: apartmentIds },
              status: MembershipStatus.ACTIVE,
              type: { in: [MembershipType.OWNER, MembershipType.TENANT] },
            },
          },
        },
      ],
    };
  }

  private async assertApartmentAccess(
    apartmentId: string,
    currentUser: AuthenticatedUser,
  ): Promise<void> {
    const apartment = await this.prisma.apartment.findUnique({
      where: { id: apartmentId },
      select: { id: true },
    });
    if (!apartment) throw new NotFoundException('Không tìm thấy căn hộ.');
    if (this.hasStaffAccess(currentUser)) {
      await this.buildingAccess.assertApartmentAccess(currentUser, apartmentId);
      return;
    }
    const allowed = await this.prisma.apartmentMembership.findFirst({
      where: {
        apartmentId,
        userId: currentUser.id,
        status: MembershipStatus.ACTIVE,
        type: { in: [MembershipType.OWNER, MembershipType.TENANT] },
      },
      select: { id: true },
    });
    if (!allowed) {
      throw new ForbiddenException(
        'Bạn không có quyền quản lý thành viên của căn hộ này.',
      );
    }
  }

  private async assertCanManagePersonalHousehold(
    apartmentId: string,
    currentUser: AuthenticatedUser,
  ): Promise<void> {
    if (this.hasStaffAccess(currentUser)) return;
    const membership = await this.prisma.apartmentMembership.findFirst({
      where: {
        apartmentId,
        userId: currentUser.id,
        status: MembershipStatus.ACTIVE,
      },
      select: { type: true },
    });
    if (membership?.type !== MembershipType.OWNER) return;
    const activeTenant = await this.prisma.apartmentMembership.findFirst({
      where: {
        apartmentId,
        userId: { not: currentUser.id },
        type: MembershipType.TENANT,
        status: MembershipStatus.ACTIVE,
      },
      select: { id: true },
    });
    if (activeTenant) {
      throw new ForbiddenException(
        'Căn hộ đang có người thuê. Thành viên sinh sống do tài khoản người thuê khai báo.',
      );
    }
  }

  private toMembershipResponse(membership: {
    id: string;
    apartmentId: string;
    userId: string;
    type: MembershipType;
    status: MembershipStatus;
    isPrimary: boolean;
    startDate: Date;
    endDate: Date | null;
  }): object {
    return {
      id: membership.id,
      apartmentId: membership.apartmentId,
      residentId: membership.userId,
      type: membership.type.toLowerCase(),
      status: membership.status.toLowerCase(),
      isPrimary: membership.isPrimary,
      startDate: membership.startDate,
      endDate: membership.endDate,
    };
  }

  private toHouseholdMemberResponse(member: {
    id: string;
    apartmentId: string;
    createdById: string;
    fullName: string;
    dateOfBirth: Date | null;
    phone: string | null;
    relationship: string;
    startDate: Date;
    endDate: Date | null;
    status: HouseholdMemberStatus;
  }): object {
    return {
      id: member.id,
      apartmentId: member.apartmentId,
      createdById: member.createdById,
      fullName: member.fullName,
      dateOfBirth: member.dateOfBirth,
      phone: member.phone ?? '',
      relationship: member.relationship,
      startDate: member.startDate,
      endDate: member.endDate,
      status: member.status.toLowerCase(),
    };
  }

  private toVerificationResponse(request: any): object {
    return {
      id: request.id,
      userId: request.userId,
      apartmentId: request.apartmentId,
      type: request.type.toLowerCase(),
      status: request.status.toLowerCase(),
      startDate: request.startDate,
      verificationBasis: request.verificationBasis,
      note: request.note,
      reviewNote: request.reviewNote,
      reviewedById: request.reviewedById,
      reviewedAt: request.reviewedAt,
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
      user: request.user
        ? {
            id: request.user.id,
            fullName: request.user.fullName,
            email: request.user.email,
            phone: request.user.phone ?? '',
          }
        : undefined,
      reviewedBy: request.reviewedBy
        ? { id: request.reviewedBy.id, fullName: request.reviewedBy.fullName }
        : undefined,
      apartment: request.apartment
        ? {
            id: request.apartment.id,
            code: request.apartment.code,
            buildingName: request.apartment.building?.name ?? '',
            activeRepresentatives: request.apartment.memberships?.map(
              (membership: any) => ({
                type: membership.type.toLowerCase(),
                userId: membership.userId,
                fullName: membership.user?.fullName ?? '',
                email: membership.user?.email ?? '',
              }),
            ),
          }
        : undefined,
    };
  }
}
