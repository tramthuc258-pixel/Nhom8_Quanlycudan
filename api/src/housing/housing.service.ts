import { randomUUID } from 'node:crypto';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  ApartmentStatus,
  HousingApplicationStatus,
  HousingInquiryStatus,
  HousingListingStatus,
  HousingTransactionType,
  HouseholdMemberStatus,
  MembershipStatus,
  MembershipType,
  NotificationType,
  Prisma,
  RoleCode,
} from '../generated/prisma/client';
import type { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { BuildingAccessService } from '../building-access/building-access.service';
import type { CompleteApplicationDto } from './dto/complete-application.dto';
import type { CreateApplicationDto } from './dto/create-application.dto';
import type { CreateListingDto } from './dto/create-listing.dto';
import type { CreateHousingInquiryDto } from './dto/create-housing-inquiry.dto';
import type { UpdateHousingInquiryDto } from './dto/update-housing-inquiry.dto';

const listingInclude = {
  apartment: { include: { building: true } },
  submittedBy: true,
  reviewedBy: true,
} satisfies Prisma.HousingListingInclude;

const applicationInclude = {
  listing: { include: { apartment: true } },
  applicant: true,
  reviewedBy: true,
  contract: true,
} satisfies Prisma.HousingApplicationInclude;

type ListingWithDetails = Prisma.HousingListingGetPayload<{
  include: typeof listingInclude;
}>;
type ApplicationWithDetails = Prisma.HousingApplicationGetPayload<{
  include: typeof applicationInclude;
}>;
const inquiryInclude = {
  listing: { include: { apartment: { include: { building: true } } } },
  handledBy: true,
} satisfies Prisma.HousingInquiryInclude;
type InquiryWithDetails = Prisma.HousingInquiryGetPayload<{
  include: typeof inquiryInclude;
}>;

@Injectable()
export class HousingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly buildingAccess: BuildingAccessService,
  ) {}

  async findListings(user: AuthenticatedUser): Promise<object> {
    const listings = await this.prisma.housingListing.findMany({
      where: await this.listingWhere(user),
      include: listingInclude,
      orderBy: { createdAt: 'desc' },
    });
    return { items: listings.map((item) => this.listingResponse(item)) };
  }

  async findPublicListings(): Promise<object> {
    const listings = await this.prisma.housingListing.findMany({
      where: { status: HousingListingStatus.AVAILABLE },
      include: listingInclude,
      orderBy: { createdAt: 'desc' },
    });
    return { items: listings.map((item) => this.listingResponse(item)) };
  }

  async createPublicInquiry(dto: CreateHousingInquiryDto): Promise<object> {
    const listing = await this.prisma.housingListing.findUnique({
      where: { id: dto.listingId },
      include: { apartment: true },
    });
    if (!listing || listing.status !== HousingListingStatus.AVAILABLE) {
      throw new ConflictException('Tin đăng này không còn nhận yêu cầu.');
    }

    const phone = dto.phone.replace(/[\s.-]/g, '');
    const duplicated = await this.prisma.housingInquiry.findFirst({
      where: {
        listingId: listing.id,
        phone,
        status: {
          in: [HousingInquiryStatus.NEW, HousingInquiryStatus.CONTACTED],
        },
      },
      select: { id: true },
    });
    if (duplicated) {
      throw new ConflictException(
        'Số điện thoại này đã có một yêu cầu đang được xử lý cho căn hộ.',
      );
    }

    const inquiry = await this.prisma.housingInquiry.create({
      data: {
        code: `LH-${new Date().getUTCFullYear()}-${randomUUID().slice(0, 8).toUpperCase()}`,
        listingId: listing.id,
        fullName: dto.fullName,
        phone,
        email: dto.email || null,
        message: dto.message || null,
      },
      include: inquiryInclude,
    });
    await this.notifications.notifyRolesInBuilding(
      [RoleCode.ADMIN, RoleCode.MANAGEMENT],
      listing.apartment.buildingId,
      {
        title: 'Có khách quan tâm căn hộ',
        message: `${inquiry.code}: ${inquiry.fullName} quan tâm căn ${listing.apartment.code}.`,
        type: NotificationType.HOUSING,
        referenceType: 'housing_inquiry',
        referenceId: inquiry.id,
      },
    );
    return this.inquiryResponse(inquiry);
  }

  async findInquiries(user: AuthenticatedUser): Promise<object> {
    const buildingIds =
      await this.buildingAccess.accessibleStaffBuildingIds(user);
    const inquiries = await this.prisma.housingInquiry.findMany({
      where:
        buildingIds === null
          ? undefined
          : { listing: { apartment: { buildingId: { in: buildingIds } } } },
      include: inquiryInclude,
      orderBy: { createdAt: 'desc' },
    });
    return { items: inquiries.map((item) => this.inquiryResponse(item)) };
  }

  async updateInquiry(
    id: string,
    handler: AuthenticatedUser,
    dto: UpdateHousingInquiryDto,
  ): Promise<object> {
    const existing = await this.prisma.housingInquiry.findUnique({
      where: { id },
      include: { listing: { include: { apartment: true } } },
    });
    if (!existing)
      throw new NotFoundException('Không tìm thấy yêu cầu liên hệ.');
    await this.buildingAccess.assertBuildingAccess(
      handler,
      existing.listing.apartment.buildingId,
    );
    const inquiry = await this.prisma.housingInquiry.update({
      where: { id },
      data: {
        status: dto.status,
        handledById: handler.id,
        handledAt: new Date(),
        staffNote: dto.staffNote || null,
      },
      include: inquiryInclude,
    });
    return this.inquiryResponse(inquiry);
  }

  async createListing(
    user: AuthenticatedUser,
    dto: CreateListingDto,
  ): Promise<object> {
    const apartment = await this.prisma.apartment.findUnique({
      where: { id: dto.apartmentId },
      include: {
        memberships: { where: { status: MembershipStatus.ACTIVE } },
      },
    });
    if (!apartment) throw new NotFoundException('Không tìm thấy căn hộ.');
    if (apartment.status === ApartmentStatus.UNDER_MAINTENANCE) {
      throw new ConflictException('Không thể đăng căn hộ đang bảo trì.');
    }

    const isStaff = this.isStaff(user);
    if (isStaff) {
      await this.buildingAccess.assertBuildingAccess(
        user,
        apartment.buildingId,
      );
    }
    const isOwner = apartment.memberships.some(
      (item) => item.userId === user.id && item.type === MembershipType.OWNER,
    );
    const hasOwner = apartment.memberships.some(
      (item) => item.type === MembershipType.OWNER,
    );
    if ((!isStaff && !isOwner) || (isStaff && hasOwner)) {
      throw new ForbiddenException(
        isStaff
          ? 'Ban quản lý chỉ được đăng căn thuộc quỹ quản lý chưa có chủ sở hữu.'
          : 'Bạn không phải chủ sở hữu của căn hộ này.',
      );
    }
    if (
      apartment.memberships.some((item) => item.type === MembershipType.TENANT)
    ) {
      throw new ConflictException(
        'Căn hộ đang có người thuê. Hãy kết thúc quan hệ thuê trước khi đăng.',
      );
    }

    const openListing = await this.prisma.housingListing.findFirst({
      where: {
        apartmentId: apartment.id,
        status: {
          in: [
            HousingListingStatus.PENDING_APPROVAL,
            HousingListingStatus.AVAILABLE,
          ],
        },
      },
      select: { id: true },
    });
    if (openListing) {
      throw new ConflictException('Căn hộ đã có một bài đăng đang xử lý.');
    }

    const listing = await this.prisma.housingListing.create({
      data: {
        apartmentId: apartment.id,
        submittedById: user.id,
        title: dto.title,
        description: dto.description,
        transactionType: dto.transactionType,
        price: dto.price,
        deposit:
          dto.transactionType === HousingTransactionType.RENT ? dto.deposit : 0,
        availableFrom: new Date(dto.availableFrom),
        imageUrls: dto.imageUrls ?? [],
        ownerSubmitted: !isStaff,
        status: isStaff
          ? HousingListingStatus.AVAILABLE
          : HousingListingStatus.PENDING_APPROVAL,
      },
      include: listingInclude,
    });
    if (listing.ownerSubmitted) {
      await this.notifications.notifyRolesInBuilding(
        [RoleCode.ADMIN, RoleCode.MANAGEMENT],
        listing.apartment.buildingId,
        {
          title: 'Có bài đăng căn hộ mới cần duyệt',
          message: `${listing.submittedBy.fullName} đã gửi bài đăng cho căn ${listing.apartment.code}.`,
          type: NotificationType.HOUSING,
          referenceType: 'housing_listing',
          referenceId: listing.id,
        },
        [user.id],
      );
    }
    return this.listingResponse(listing);
  }

  async approveListing(
    id: string,
    reviewer: AuthenticatedUser,
  ): Promise<object> {
    const current = await this.findListing(id);
    await this.buildingAccess.assertBuildingAccess(
      reviewer,
      current.apartment.buildingId,
    );
    if (current.status !== HousingListingStatus.PENDING_APPROVAL) {
      throw new ConflictException('Bài đăng này đã được xử lý trước đó.');
    }
    const listing = await this.prisma.housingListing.update({
      where: { id },
      data: {
        status: HousingListingStatus.AVAILABLE,
        reviewedById: reviewer.id,
        reviewedAt: new Date(),
        reviewNote: 'Bài đăng đã được ban quản lý phê duyệt.',
      },
      include: listingInclude,
    });
    await this.notifications.notifyUser(listing.submittedById, {
      title: 'Bài đăng căn hộ đã được duyệt',
      message: `Bài đăng “${listing.title}” đã được công khai để nhận hồ sơ.`,
      type: NotificationType.HOUSING,
      referenceType: 'housing_listing',
      referenceId: listing.id,
    });
    return this.listingResponse(listing);
  }

  async rejectListing(
    id: string,
    reviewer: AuthenticatedUser,
    reason: string,
  ): Promise<object> {
    const current = await this.findListing(id);
    await this.buildingAccess.assertBuildingAccess(
      reviewer,
      current.apartment.buildingId,
    );
    if (current.status !== HousingListingStatus.PENDING_APPROVAL) {
      throw new ConflictException('Bài đăng này đã được xử lý trước đó.');
    }
    const listing = await this.prisma.housingListing.update({
      where: { id },
      data: {
        status: HousingListingStatus.REJECTED,
        reviewedById: reviewer.id,
        reviewedAt: new Date(),
        reviewNote: reason,
      },
      include: listingInclude,
    });
    await this.notifications.notifyUser(listing.submittedById, {
      title: 'Bài đăng căn hộ chưa được duyệt',
      message: `Bài đăng “${listing.title}” bị từ chối: ${reason}`,
      type: NotificationType.HOUSING,
      referenceType: 'housing_listing',
      referenceId: listing.id,
    });
    return this.listingResponse(listing);
  }

  async findApplications(user: AuthenticatedUser): Promise<object> {
    const applications = await this.prisma.housingApplication.findMany({
      where: await this.applicationWhere(user),
      include: applicationInclude,
      orderBy: { submittedAt: 'desc' },
    });
    return {
      items: applications.map((item) => this.applicationResponse(item)),
    };
  }

  async createApplication(
    user: AuthenticatedUser,
    dto: CreateApplicationDto,
  ): Promise<object> {
    if (!user.roles.includes(RoleCode.RESIDENT)) {
      throw new ForbiddenException('Chỉ cư dân mới có thể nộp hồ sơ.');
    }
    const listing = await this.prisma.housingListing.findUnique({
      where: { id: dto.listingId },
      include: { apartment: true },
    });
    if (!listing || listing.status !== HousingListingStatus.AVAILABLE) {
      throw new ConflictException('Tin đăng này không còn nhận hồ sơ.');
    }

    const startDate = new Date(dto.preferredStartDate);
    const endDate = dto.preferredEndDate
      ? new Date(dto.preferredEndDate)
      : null;
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);
    if (startDate < today || startDate < listing.availableFrom) {
      throw new BadRequestException(
        'Ngày bắt đầu phải từ ngày căn hộ sẵn sàng.',
      );
    }
    if (
      listing.transactionType === HousingTransactionType.RENT &&
      (!endDate || endDate <= startDate)
    ) {
      throw new BadRequestException(
        'Ngày kết thúc thuê phải sau ngày bắt đầu.',
      );
    }

    const duplicated = await this.prisma.housingApplication.findFirst({
      where: {
        listingId: listing.id,
        applicantId: user.id,
        status: HousingApplicationStatus.PENDING,
      },
      select: { id: true },
    });
    if (duplicated) {
      throw new ConflictException(
        'Bạn đã có một hồ sơ đang chờ duyệt cho căn hộ này.',
      );
    }

    if (!user.phone) {
      await this.prisma.user.update({
        where: { id: user.id },
        data: { phone: dto.phone },
      });
    }

    const application = await this.prisma.housingApplication.create({
      data: {
        code: `HS-${today.getUTCFullYear()}-${randomUUID().slice(0, 8).toUpperCase()}`,
        listingId: listing.id,
        applicantId: user.id,
        preferredStartDate: startDate,
        preferredEndDate:
          listing.transactionType === HousingTransactionType.RENT
            ? endDate
            : null,
        note: dto.note || null,
      },
      include: applicationInclude,
    });
    await this.notifications.notifyRolesInBuilding(
      [RoleCode.ADMIN, RoleCode.MANAGEMENT],
      application.listing.apartment.buildingId,
      {
        title: 'Có hồ sơ mua/thuê căn hộ mới',
        message: `${application.code}: ${application.applicant.fullName} đã nộp hồ sơ cho căn ${application.listing.apartment.code}.`,
        type: NotificationType.HOUSING,
        referenceType: 'housing_application',
        referenceId: application.id,
      },
      [user.id],
    );
    if (listing.submittedById !== user.id) {
      await this.notifications.notifyUser(listing.submittedById, {
        title: 'Bài đăng có người quan tâm',
        message: `${application.applicant.fullName} đã nộp hồ sơ cho căn ${application.listing.apartment.code}.`,
        type: NotificationType.HOUSING,
        referenceType: 'housing_application',
        referenceId: application.id,
      });
    }
    return this.applicationResponse(application);
  }

  async rejectApplication(
    id: string,
    reviewer: AuthenticatedUser,
    reason: string,
  ): Promise<object> {
    const current = await this.findApplication(id);
    await this.buildingAccess.assertBuildingAccess(
      reviewer,
      current.listing.apartment.buildingId,
    );
    if (current.status !== HousingApplicationStatus.PENDING) {
      throw new ConflictException('Hồ sơ này đã được xử lý trước đó.');
    }
    const application = await this.prisma.housingApplication.update({
      where: { id },
      data: {
        status: HousingApplicationStatus.REJECTED,
        reviewedById: reviewer.id,
        reviewedAt: new Date(),
        reviewNote: reason,
      },
      include: applicationInclude,
    });
    await this.notifications.notifyUser(application.applicantId, {
      title: 'Hồ sơ căn hộ chưa được chấp thuận',
      message: `${application.code}: ${reason}`,
      type: NotificationType.HOUSING,
      referenceType: 'housing_application',
      referenceId: application.id,
    });
    return this.applicationResponse(application);
  }

  async completeApplication(
    id: string,
    reviewer: AuthenticatedUser,
    dto: CompleteApplicationDto,
  ): Promise<object> {
    const scopedApplication = await this.findApplication(id);
    await this.buildingAccess.assertBuildingAccess(
      reviewer,
      scopedApplication.listing.apartment.buildingId,
    );
    const signedAt = new Date(dto.contractSignedAt);
    const effectiveDate = new Date(dto.effectiveDate);
    if (effectiveDate < signedAt) {
      throw new BadRequestException(
        'Ngày hiệu lực không được trước ngày ký hợp đồng.',
      );
    }

    try {
      const result = await this.prisma.$transaction(async (transaction) => {
        const application = await transaction.housingApplication.findUnique({
          where: { id },
          include: applicationInclude,
        });
        if (!application) throw new NotFoundException('Không tìm thấy hồ sơ.');
        if (application.status !== HousingApplicationStatus.PENDING) {
          throw new ConflictException('Hồ sơ này đã được xử lý trước đó.');
        }
        const listing = application.listing;
        if (listing.status !== HousingListingStatus.AVAILABLE) {
          throw new ConflictException('Tin đăng không còn nhận hồ sơ.');
        }
        if (
          listing.transactionType === HousingTransactionType.RENT &&
          application.preferredEndDate &&
          application.preferredEndDate <= effectiveDate
        ) {
          throw new BadRequestException(
            'Ngày kết thúc thuê phải sau ngày hiệu lực.',
          );
        }

        const activeMemberships =
          await transaction.apartmentMembership.findMany({
            where: {
              apartmentId: listing.apartmentId,
              status: MembershipStatus.ACTIVE,
            },
          });
        if (
          activeMemberships.some(
            (item) => item.userId === application.applicantId,
          )
        ) {
          throw new ConflictException(
            `${application.applicant.fullName} đã có quan hệ đang hiệu lực với căn hộ.`,
          );
        }

        const activeOwner = activeMemberships.find(
          (item) => item.type === MembershipType.OWNER,
        );
        if (
          listing.transactionType === HousingTransactionType.RENT &&
          activeMemberships.some((item) => item.type === MembershipType.TENANT)
        ) {
          throw new ConflictException(
            'Căn hộ đã có một người thuê đại diện đang hiệu lực.',
          );
        }
        const ownerId = activeOwner?.userId ?? listing.submittedById;
        if (listing.transactionType === HousingTransactionType.PURCHASE) {
          await transaction.apartmentMembership.updateMany({
            where: {
              apartmentId: listing.apartmentId,
              status: MembershipStatus.ACTIVE,
            },
            data: { status: MembershipStatus.ENDED, endDate: effectiveDate },
          });
          await transaction.householdMember.updateMany({
            where: {
              apartmentId: listing.apartmentId,
              status: HouseholdMemberStatus.ACTIVE,
            },
            data: {
              status: HouseholdMemberStatus.ENDED,
              endDate: effectiveDate,
            },
          });
        }

        await transaction.apartmentMembership.create({
          data: {
            apartmentId: listing.apartmentId,
            userId: application.applicantId,
            type:
              listing.transactionType === HousingTransactionType.RENT
                ? MembershipType.TENANT
                : MembershipType.OWNER,
            isPrimary: true,
            startDate: effectiveDate,
            endDate:
              listing.transactionType === HousingTransactionType.RENT
                ? application.preferredEndDate
                : null,
          },
        });

        await transaction.housingContract.create({
          data: {
            contractNumber: dto.contractNumber,
            applicationId: application.id,
            apartmentId: listing.apartmentId,
            ownerId,
            customerId: application.applicantId,
            recordedById: reviewer.id,
            transactionType: listing.transactionType,
            agreedPrice: listing.price,
            deposit: listing.deposit,
            signedAt,
            effectiveStartDate: effectiveDate,
            effectiveEndDate:
              listing.transactionType === HousingTransactionType.RENT
                ? application.preferredEndDate
                : null,
            note: dto.note || null,
          },
        });

        const now = new Date();
        await transaction.housingApplication.update({
          where: { id: application.id },
          data: {
            status: HousingApplicationStatus.COMPLETED,
            reviewedById: reviewer.id,
            reviewedAt: now,
            reviewNote:
              dto.note ||
              'Đã xác nhận hợp đồng và hoàn tất giao dịch bên ngoài ứng dụng.',
          },
        });
        const otherPending = await transaction.housingApplication.findMany({
          where: {
            id: { not: application.id },
            listingId: listing.id,
            status: HousingApplicationStatus.PENDING,
          },
          select: { id: true, code: true, applicantId: true },
        });
        await transaction.housingApplication.updateMany({
          where: {
            id: { not: application.id },
            listingId: listing.id,
            status: HousingApplicationStatus.PENDING,
          },
          data: {
            status: HousingApplicationStatus.REJECTED,
            reviewedById: reviewer.id,
            reviewedAt: now,
            reviewNote: 'Căn hộ đã hoàn tất giao dịch với một hồ sơ khác.',
          },
        });
        await transaction.housingListing.update({
          where: { id: listing.id },
          data: { status: HousingListingStatus.CLOSED, closedAt: now },
        });
        await transaction.apartment.update({
          where: { id: listing.apartmentId },
          data: { status: ApartmentStatus.OCCUPIED },
        });

        const completed =
          await transaction.housingApplication.findUniqueOrThrow({
            where: { id: application.id },
            include: applicationInclude,
          });
        return {
          response: this.applicationResponse(completed),
          applicantId: completed.applicantId,
          applicationCode: completed.code,
          listingSubmitterId: listing.submittedById,
          apartmentCode: completed.listing.apartment.code,
          otherPending,
        };
      });
      await this.notifications.notifyUser(result.applicantId, {
        title: 'Giao dịch căn hộ đã hoàn tất',
        message: `${result.applicationCode}: hợp đồng căn ${result.apartmentCode} đã được ghi nhận.`,
        type: NotificationType.HOUSING,
        referenceType: 'housing_application',
        referenceId: id,
      });
      if (result.listingSubmitterId !== result.applicantId) {
        await this.notifications.notifyUser(result.listingSubmitterId, {
          title: 'Giao dịch căn hộ đã hoàn tất',
          message: `Giao dịch căn ${result.apartmentCode} đã được ban quản lý xác nhận.`,
          type: NotificationType.HOUSING,
          referenceType: 'housing_application',
          referenceId: id,
        });
      }
      for (const rejected of result.otherPending) {
        await this.notifications.notifyUser(rejected.applicantId, {
          title: 'Hồ sơ căn hộ đã kết thúc',
          message: `${rejected.code}: căn hộ đã hoàn tất giao dịch với một hồ sơ khác.`,
          type: NotificationType.HOUSING,
          referenceType: 'housing_application',
          referenceId: rejected.id,
        });
      }
      return result.response;
    } catch (error: unknown) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException('Mã hợp đồng đã tồn tại.');
      }
      throw error;
    }
  }

  private isStaff(user: AuthenticatedUser): boolean {
    return user.roles.some(
      (role) => role === RoleCode.ADMIN || role === RoleCode.MANAGEMENT,
    );
  }

  private async listingWhere(
    user: AuthenticatedUser,
  ): Promise<Prisma.HousingListingWhereInput> {
    if (!this.isStaff(user)) {
      return {
        OR: [
          {
            status: {
              in: [HousingListingStatus.AVAILABLE, HousingListingStatus.CLOSED],
            },
          },
          { submittedById: user.id },
        ],
      };
    }
    if (user.roles.includes(RoleCode.ADMIN)) return {};
    const buildingIds =
      (await this.buildingAccess.accessibleStaffBuildingIds(user)) ?? [];
    return { apartment: { buildingId: { in: buildingIds } } };
  }

  private async applicationWhere(
    user: AuthenticatedUser,
  ): Promise<Prisma.HousingApplicationWhereInput> {
    if (!this.isStaff(user)) return { applicantId: user.id };
    if (user.roles.includes(RoleCode.ADMIN)) return {};
    const buildingIds =
      (await this.buildingAccess.accessibleStaffBuildingIds(user)) ?? [];
    return { listing: { apartment: { buildingId: { in: buildingIds } } } };
  }

  private async findListing(id: string) {
    const listing = await this.prisma.housingListing.findUnique({
      where: { id },
      include: listingInclude,
    });
    if (!listing) throw new NotFoundException('Không tìm thấy bài đăng.');
    return listing;
  }

  private async findApplication(id: string) {
    const application = await this.prisma.housingApplication.findUnique({
      where: { id },
      include: applicationInclude,
    });
    if (!application) throw new NotFoundException('Không tìm thấy hồ sơ.');
    return application;
  }

  private listingResponse(listing: ListingWithDetails): object {
    return {
      id: listing.id,
      apartmentId: listing.apartmentId,
      apartmentCode: listing.apartment.code,
      buildingName: listing.apartment.building.name,
      title: listing.title,
      description: listing.description,
      transactionType: listing.transactionType.toLowerCase(),
      price: Number(listing.price),
      deposit: Number(listing.deposit),
      availableFrom: listing.availableFrom,
      status:
        listing.status === HousingListingStatus.PENDING_APPROVAL
          ? 'pendingApproval'
          : listing.status.toLowerCase(),
      createdAt: listing.createdAt,
      submittedById: listing.submittedById,
      submittedByName: listing.submittedBy.fullName,
      ownerSubmitted: listing.ownerSubmitted,
      reviewedAt: listing.reviewedAt,
      reviewedBy: listing.reviewedBy?.fullName ?? null,
      reviewNote: listing.reviewNote,
      imageUrls: Array.isArray(listing.imageUrls) ? listing.imageUrls : [],
    };
  }

  private applicationResponse(application: ApplicationWithDetails): object {
    return {
      id: application.id,
      code: application.code,
      listingId: application.listingId,
      apartmentId: application.listing.apartmentId,
      transactionType: application.listing.transactionType.toLowerCase(),
      applicantId: application.applicantId,
      applicantFullName: application.applicant.fullName,
      applicantEmail: application.applicant.email,
      applicantPhone: application.applicant.phone ?? '',
      preferredStartDate: application.preferredStartDate,
      preferredEndDate: application.preferredEndDate,
      note: application.note ?? '',
      status: application.status.toLowerCase(),
      submittedAt: application.submittedAt,
      reviewedAt: application.reviewedAt,
      reviewedBy: application.reviewedBy?.fullName ?? null,
      reviewNote: application.reviewNote,
      contractNumber: application.contract?.contractNumber ?? null,
      contractSignedAt: application.contract?.signedAt ?? null,
      effectiveDate: application.contract?.effectiveStartDate ?? null,
    };
  }

  private inquiryResponse(inquiry: InquiryWithDetails): object {
    return {
      id: inquiry.id,
      code: inquiry.code,
      listingId: inquiry.listingId,
      apartmentCode: inquiry.listing.apartment.code,
      buildingName: inquiry.listing.apartment.building.name,
      listingTitle: inquiry.listing.title,
      transactionType: inquiry.listing.transactionType.toLowerCase(),
      fullName: inquiry.fullName,
      phone: inquiry.phone,
      email: inquiry.email,
      message: inquiry.message,
      status: inquiry.status.toLowerCase(),
      staffNote: inquiry.staffNote,
      handledAt: inquiry.handledAt,
      handledBy: inquiry.handledBy?.fullName ?? null,
      createdAt: inquiry.createdAt,
    };
  }
}
