import 'dotenv/config';

import { PrismaPg } from '@prisma/adapter-pg';
import {
  AmenityBookingStatus,
  HousingApplicationStatus,
  InvoiceStatus,
  MaintenanceCategory,
  MaintenancePriority,
  MaintenanceStatus,
  MembershipStatus,
  MembershipType,
  NotificationType,
  PrismaClient,
  ResidenceVerificationStatus,
  RoleCode,
  SecurityIncidentStatus,
  SecurityIncidentType,
  ServiceRequestStatus,
  TemporaryStayStatus,
} from '../src/generated/prisma/client';

const connectionString = process.env.DIRECT_URL ?? process.env.DATABASE_URL;
if (!connectionString) throw new Error('Thiếu DIRECT_URL hoặc DATABASE_URL.');

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

const email = process.env.SHOWCASE_RESIDENT_EMAIL?.trim();
if (!email) {
  throw new Error('Thiếu SHOWCASE_RESIDENT_EMAIL trong api/.env.');
}
const ids = {
  verification: 'c1000000-0000-4000-8000-000000000001',
  household: 'c1000000-0000-4000-8000-000000000002',
  invoice: 'c1000000-0000-4000-8000-000000000003',
  invoiceManagement: 'c1000000-0000-4000-8000-000000000004',
  invoiceWater: 'c1000000-0000-4000-8000-000000000005',
  maintenanceOpen: 'c1000000-0000-4000-8000-000000000006',
  maintenanceWaiting: 'c1000000-0000-4000-8000-000000000007',
  maintenanceDone: 'c1000000-0000-4000-8000-000000000008',
  serviceOpen: 'c1000000-0000-4000-8000-000000000009',
  serviceWaiting: 'c1000000-0000-4000-8000-000000000010',
  serviceDone: 'c1000000-0000-4000-8000-000000000011',
  bookingApproved: 'c1000000-0000-4000-8000-000000000012',
  bookingPending: 'c1000000-0000-4000-8000-000000000013',
  bookingDone: 'c1000000-0000-4000-8000-000000000014',
  stayApproved: 'c1000000-0000-4000-8000-000000000015',
  stayPending: 'c1000000-0000-4000-8000-000000000016',
  incidentReviewing: 'c1000000-0000-4000-8000-000000000017',
  incidentDone: 'c1000000-0000-4000-8000-000000000018',
  housingApplication: 'c1000000-0000-4000-8000-000000000019',
  maintenanceUpdate1: 'c1000000-0000-4000-8000-000000000020',
  maintenanceUpdate2: 'c1000000-0000-4000-8000-000000000021',
  maintenanceUpdate3: 'c1000000-0000-4000-8000-000000000022',
  maintenanceUpdate4: 'c1000000-0000-4000-8000-000000000023',
  serviceUpdate1: 'c1000000-0000-4000-8000-000000000024',
  serviceUpdate2: 'c1000000-0000-4000-8000-000000000025',
  serviceUpdate3: 'c1000000-0000-4000-8000-000000000026',
  incidentUpdate1: 'c1000000-0000-4000-8000-000000000027',
  incidentUpdate2: 'c1000000-0000-4000-8000-000000000028',
  incidentUpdate3: 'c1000000-0000-4000-8000-000000000029',
  notificationInvoice: 'c1000000-0000-4000-8000-000000000030',
  notificationMaintenance: 'c1000000-0000-4000-8000-000000000031',
  notificationService: 'c1000000-0000-4000-8000-000000000032',
  notificationAmenity: 'c1000000-0000-4000-8000-000000000033',
  notificationStay: 'c1000000-0000-4000-8000-000000000034',
  notificationSecurity: 'c1000000-0000-4000-8000-000000000035',
  notificationHousing: 'c1000000-0000-4000-8000-000000000036',
} as const;

const day = 24 * 60 * 60 * 1000;
const now = new Date();
const shifted = (days: number) => new Date(now.getTime() + days * day);
const localCalendarDate = (days: number) =>
  new Date(shifted(days).getTime() + 7 * 60 * 60 * 1000);
const dateOnly = (days: number) => {
  const date = localCalendarDate(days);
  return new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
  );
};
const atLocalHour = (days: number, hour: number) => {
  const date = localCalendarDate(days);
  return new Date(
    Date.UTC(
      date.getUTCFullYear(),
      date.getUTCMonth(),
      date.getUTCDate(),
      hour - 7,
    ),
  );
};

async function main() {
  const user = await prisma.user.findUnique({
    where: { email },
    include: {
      userRoles: { include: { role: true } },
      apartmentMemberships: { include: { apartment: true } },
    },
  });
  if (!user) throw new Error(`Không tìm thấy tài khoản ${email}.`);
  if (!user.userRoles.some((item) => item.role.code === RoleCode.RESIDENT)) {
    throw new Error('Tài khoản chưa có vai trò cư dân.');
  }
  const membership = user.apartmentMemberships.find(
    (item) =>
      item.status === MembershipStatus.ACTIVE &&
      item.type === MembershipType.TENANT &&
      item.apartment.code === 'A-0301',
  );
  if (!membership) throw new Error('Tài khoản chưa là người thuê căn A-0301.');
  const apartment = membership.apartment;
  const staff = await prisma.user.findMany({
    where: {
      status: 'ACTIVE',
      staffBuildingAssignments: {
        some: { buildingId: apartment.buildingId, isActive: true },
      },
    },
    include: { userRoles: { include: { role: true } } },
  });
  const staffFor = (role: RoleCode) => {
    const member = staff.find((person) =>
      person.userRoles.some((item) => item.role.code === role),
    );
    if (!member) throw new Error(`Thiếu nhân viên ${role} của tòa A.`);
    return member;
  };
  const manager = staffFor(RoleCode.MANAGEMENT);
  const accountant = staffFor(RoleCode.ACCOUNTANT);
  const receptionist = staffFor(RoleCode.RECEPTIONIST);
  const technician = staffFor(RoleCode.TECHNICIAN);
  const guard = staffFor(RoleCode.SECURITY);

  const verification = await prisma.residenceVerificationRequest.findFirst({
    where: {
      userId: user.id,
      apartmentId: apartment.id,
      status: ResidenceVerificationStatus.APPROVED,
    },
  });
  if (!verification) {
    await prisma.residenceVerificationRequest.upsert({
      where: { id: ids.verification },
      update: {},
      create: {
        id: ids.verification,
        userId: user.id,
        apartmentId: apartment.id,
        type: MembershipType.TENANT,
        status: ResidenceVerificationStatus.APPROVED,
        startDate: membership.startDate,
        verificationBasis: 'Hợp đồng thuê và thông tin liên hệ',
        note: 'Người thuê căn A-0301.',
        reviewNote: 'Ban quản lý đã đối chiếu thông tin cư trú.',
        reviewedById: manager.id,
        reviewedAt: now,
      },
    });
  }

  await prisma.householdMember.upsert({
    where: { id: ids.household },
    update: {},
    create: {
      id: ids.household,
      apartmentId: apartment.id,
      createdById: user.id,
      fullName: 'Đinh Gia Hân',
      relationship: 'Em gái',
      startDate: membership.startDate,
      status: 'ACTIVE',
    },
  });

  const feeTypes = await prisma.feeType.findMany({
    where: { code: { in: ['MANAGEMENT_FEE', 'WATER_FEE'] } },
  });
  const fee = (code: string) => {
    const item = feeTypes.find((value) => value.code === code);
    if (!item) throw new Error(`Thiếu danh mục phí ${code}.`);
    return item;
  };
  const month = new Date('2026-12-01T00:00:00.000Z');
  const invoiceDueDate = new Date(
    Date.UTC(month.getUTCFullYear(), month.getUTCMonth(), 15),
  );
  const invoiceCode = `HD-${month.getUTCFullYear()}${String(month.getUTCMonth() + 1).padStart(2, '0')}-A0301`;
  let invoice = await prisma.invoice.findFirst({
    where: { apartmentId: apartment.id, billingMonth: month },
  });
  if (invoice && invoice.payerId !== user.id) {
    throw new Error('Hóa đơn tháng 12 của A-0301 thuộc người thanh toán khác.');
  }
  if (!invoice) {
    const previouslySeeded = await prisma.invoice.findUnique({
      where: { id: ids.invoice },
    });
    invoice = previouslySeeded
      ? await prisma.invoice.update({
          where: { id: ids.invoice },
          data: {
            code: invoiceCode,
            billingMonth: month,
            dueDate: invoiceDueDate,
          },
        })
      : await prisma.invoice.create({
          data: {
            id: ids.invoice,
            code: invoiceCode,
            apartmentId: apartment.id,
            payerId: user.id,
            createdById: accountant.id,
            publishedById: accountant.id,
            billingMonth: month,
            issuedAt: now,
            publishedAt: now,
            dueDate: invoiceDueDate,
            status: InvoiceStatus.UNPAID,
            totalAmount: 1080000,
            note: 'Phí quản lý và nước sinh hoạt kỳ tới của căn A-0301.',
            items: {
              create: [
                {
                  id: ids.invoiceManagement,
                  feeTypeId: fee('MANAGEMENT_FEE').id,
                  name: 'Phí quản lý',
                  quantity: 72,
                  unitPrice: 12000,
                  amount: 864000,
                },
                {
                  id: ids.invoiceWater,
                  feeTypeId: fee('WATER_FEE').id,
                  name: 'Tiền nước',
                  quantity: 12,
                  unitPrice: 18000,
                  amount: 216000,
                },
              ],
            },
          },
        });
  }

  // Remove only the historical showcase rows from an earlier version of this script.
  // The resident's membership starts on 01/11, so those rows predate her tenancy.
  await prisma.maintenanceUpdate.deleteMany({
    where: { maintenanceRequestId: ids.maintenanceDone },
  });
  await prisma.maintenanceRequest.deleteMany({
    where: { id: ids.maintenanceDone, requestedById: user.id },
  });
  await prisma.serviceRequestUpdate.deleteMany({
    where: { serviceRequestId: ids.serviceDone },
  });
  await prisma.serviceRequest.deleteMany({
    where: { id: ids.serviceDone, requestedById: user.id },
  });
  await prisma.amenityBooking.deleteMany({
    where: { id: ids.bookingDone, residentId: user.id },
  });
  await prisma.securityIncidentUpdate.deleteMany({
    where: { securityIncidentId: ids.incidentDone },
  });
  await prisma.securityIncident.deleteMany({
    where: { id: ids.incidentDone, reportedById: user.id },
  });

  const maintenance = [
    {
      id: ids.maintenanceOpen,
      code: 'YC-TRAM-DANG-XU-LY',
      title: 'Vòi nước bếp bị rò rỉ',
      description:
        'Vòi nước dưới bồn rửa chảy nhỏ giọt, cần kiểm tra và thay gioăng.',
      location: 'Bếp căn A-0301',
      category: MaintenanceCategory.PLUMBING,
      priority: MaintenancePriority.NORMAL,
      status: MaintenanceStatus.IN_PROGRESS,
      assignedAt: now,
      completedAt: null,
    },
    {
      id: ids.maintenanceWaiting,
      code: 'YC-TRAM-CHO-XAC-NHAN',
      title: 'Kiểm tra ổ cắm phòng ngủ',
      description:
        'Ổ cắm phòng ngủ lúc có điện lúc không. Kỹ thuật viên đã xử lý và chờ cư dân xác nhận.',
      location: 'Phòng ngủ căn A-0301',
      category: MaintenanceCategory.ELECTRICAL,
      priority: MaintenancePriority.HIGH,
      status: MaintenanceStatus.WAITING_RESIDENT,
      assignedAt: now,
      completedAt: null,
    },
  ] as const;
  for (const item of maintenance) {
    await prisma.maintenanceRequest.upsert({
      where: { id: item.id },
      update: {},
      create: {
        ...item,
        apartmentId: apartment.id,
        requestedById: user.id,
        createdById: user.id,
        assignedTechnicianId: technician.id,
        assignedTeamName: 'Tổ kỹ thuật tòa A',
        assignedById: manager.id,
      },
    });
  }
  const maintenanceUpdates = [
    {
      id: ids.maintenanceUpdate1,
      maintenanceRequestId: ids.maintenanceOpen,
      actorId: manager.id,
      status: MaintenanceStatus.RECEIVED,
      note: 'Ban quản lý đã tiếp nhận và phân công kỹ thuật viên.',
    },
    {
      id: ids.maintenanceUpdate2,
      maintenanceRequestId: ids.maintenanceOpen,
      actorId: technician.id,
      status: MaintenanceStatus.IN_PROGRESS,
      note: 'Đang kiểm tra đầu nối và gioăng vòi nước.',
    },
    {
      id: ids.maintenanceUpdate3,
      maintenanceRequestId: ids.maintenanceWaiting,
      actorId: technician.id,
      status: MaintenanceStatus.WAITING_RESIDENT,
      note: 'Đã thay ổ cắm, chờ cư dân kiểm tra và xác nhận.',
    },
  ];
  for (const item of maintenanceUpdates) {
    await prisma.maintenanceUpdate.upsert({
      where: { id: item.id },
      update: {},
      create: item,
    });
  }

  const services = await prisma.service.findMany({ where: { isActive: true } });
  const service = (name: string) => {
    const item = services.find((value) => value.name === name);
    if (!item) throw new Error(`Thiếu dịch vụ ${name}.`);
    return item;
  };
  const serviceRequests = [
    {
      id: ids.serviceOpen,
      code: 'DV-TRAM-DA-XAC-NHAN',
      service: service('Vệ sinh căn hộ'),
      quantity: 2,
      scheduledAt: atLocalHour(2, 10),
      note: 'Vệ sinh phòng khách và bếp.',
      status: ServiceRequestStatus.CONFIRMED,
      managementNote: 'Lễ tân đã xác nhận lịch và nhân viên phụ trách.',
      assignedToId: receptionist.id,
      assignedToName: receptionist.fullName,
      completedAt: null,
    },
    {
      id: ids.serviceWaiting,
      code: 'DV-TRAM-CHO-XAC-NHAN',
      service: service('Giao nước uống'),
      quantity: 2,
      scheduledAt: now,
      note: 'Giao hai bình nước tại căn hộ.',
      status: ServiceRequestStatus.WAITING_RESIDENT,
      managementNote: 'Nhân viên đã giao nước, chờ cư dân xác nhận.',
      assignedToId: receptionist.id,
      assignedToName: receptionist.fullName,
      completedAt: null,
    },
  ] as const;
  for (const item of serviceRequests) {
    await prisma.serviceRequest.upsert({
      where: { id: item.id },
      update: {},
      create: {
        id: item.id,
        code: item.code,
        serviceId: item.service.id,
        apartmentId: apartment.id,
        requestedById: user.id,
        createdById: user.id,
        assignedToId: item.assignedToId,
        assignedToName: item.assignedToName,
        quantity: item.quantity,
        unitPrice: item.service.unitPrice,
        scheduledAt: item.scheduledAt,
        note: item.note,
        status: item.status,
        managementNote: item.managementNote,
        completedAt: item.completedAt,
      },
    });
  }
  const serviceUpdates = [
    {
      id: ids.serviceUpdate1,
      serviceRequestId: ids.serviceOpen,
      actorId: receptionist.id,
      status: ServiceRequestStatus.CONFIRMED,
      note: 'Lịch vệ sinh đã được xác nhận.',
    },
    {
      id: ids.serviceUpdate2,
      serviceRequestId: ids.serviceWaiting,
      actorId: receptionist.id,
      status: ServiceRequestStatus.WAITING_RESIDENT,
      note: 'Đã giao hai bình nước, chờ cư dân xác nhận.',
    },
  ];
  for (const item of serviceUpdates) {
    await prisma.serviceRequestUpdate.upsert({
      where: { id: item.id },
      update: {},
      create: item,
    });
  }

  const amenities = await prisma.amenity.findMany({
    where: { buildingId: apartment.buildingId, isActive: true },
  });
  const amenity = (name: string) => {
    const item = amenities.find((value) => value.name === name);
    if (!item) throw new Error(`Thiếu tiện ích ${name}.`);
    return item;
  };
  const bookings = [
    {
      id: ids.bookingApproved,
      code: 'TI-TRAM-DA-DUYET',
      amenity: amenity('Phòng gym'),
      startAt: atLocalHour(3, 10),
      attendeeCount: 1,
      status: AmenityBookingStatus.APPROVED,
      note: 'Đặt lịch tập cá nhân.',
      reviewedById: receptionist.id,
      reviewedAt: now,
      managementNote: 'Khung giờ còn trống.',
    },
    {
      id: ids.bookingPending,
      code: 'TI-TRAM-CHO-DUYET',
      amenity: amenity('Khu nướng BBQ'),
      startAt: atLocalHour(5, 16),
      attendeeCount: 6,
      status: AmenityBookingStatus.PENDING,
      note: 'Đặt khu nướng cho buổi gặp mặt gia đình.',
      reviewedById: null,
      reviewedAt: null,
      managementNote: null,
    },
  ] as const;
  for (const item of bookings) {
    const endAt = new Date(
      item.startAt.getTime() + item.amenity.slotDurationMinutes * 60 * 1000,
    );
    await prisma.amenityBooking.upsert({
      where: { id: item.id },
      update: {},
      create: {
        id: item.id,
        code: item.code,
        amenityId: item.amenity.id,
        apartmentId: apartment.id,
        residentId: user.id,
        startAt: item.startAt,
        endAt,
        attendeeCount: item.attendeeCount,
        status: item.status,
        note: item.note,
        reviewedById: item.reviewedById,
        reviewedAt: item.reviewedAt,
        managementNote: item.managementNote,
        processedById: null,
        checkedInAt: null,
        completedAt: null,
      },
    });
  }

  const stays = [
    {
      id: ids.stayApproved,
      guestFullName: 'Nguyễn Minh Anh',
      relationshipToResident: 'Bạn',
      startDate: dateOnly(1),
      endDate: dateOnly(3),
      purpose: 'Đến thăm và lưu trú ngắn ngày.',
      status: TemporaryStayStatus.APPROVED,
      reviewedById: receptionist.id,
      reviewedAt: now,
      reviewNote: 'Thông tin khách lưu trú hợp lệ.',
    },
    {
      id: ids.stayPending,
      guestFullName: 'Lê Hoàng Phúc',
      relationshipToResident: 'Bạn',
      startDate: dateOnly(6),
      endDate: dateOnly(7),
      purpose: 'Đến thăm cư dân cuối tuần.',
      status: TemporaryStayStatus.PENDING,
      reviewedById: null,
      reviewedAt: null,
      reviewNote: null,
    },
  ] as const;
  for (const item of stays) {
    await prisma.temporaryStay.upsert({
      where: { id: item.id },
      update: {},
      create: { ...item, apartmentId: apartment.id, declaredById: user.id },
    });
  }

  const incidents = [
    {
      id: ids.incidentReviewing,
      code: 'AN-TRAM-DANG-XU-LY',
      type: SecurityIncidentType.SUSPICIOUS_PERSON,
      title: 'Người lạ tại hành lang tầng 3',
      description:
        'Cư dân thấy người lạ đi lại nhiều lần gần cửa căn hộ và đã báo bảo vệ kiểm tra.',
      location: 'Hành lang tầng 3, tòa A',
      occurredAt: now,
      status: SecurityIncidentStatus.REVIEWING,
      resolutionNote: null,
      resolvedAt: null,
    },
  ] as const;
  for (const item of incidents) {
    await prisma.securityIncident.upsert({
      where: { id: item.id },
      update: {},
      create: {
        ...item,
        buildingId: apartment.buildingId,
        apartmentId: apartment.id,
        reportedById: user.id,
        assignedToId: guard.id,
        assignedById: manager.id,
        assignedAt: now,
        resolvedById: null,
      },
    });
  }
  const incidentUpdates = [
    {
      id: ids.incidentUpdate1,
      securityIncidentId: ids.incidentReviewing,
      actorId: user.id,
      status: SecurityIncidentStatus.REPORTED,
      note: 'Cư dân đã gửi thông tin sự cố.',
    },
    {
      id: ids.incidentUpdate2,
      securityIncidentId: ids.incidentReviewing,
      actorId: guard.id,
      status: SecurityIncidentStatus.REVIEWING,
      note: 'Bảo vệ đang kiểm tra camera hành lang.',
    },
  ];
  for (const item of incidentUpdates) {
    await prisma.securityIncidentUpdate.upsert({
      where: { id: item.id },
      update: {},
      create: item,
    });
  }

  const listing = await prisma.housingListing.findFirst({
    where: { status: 'AVAILABLE', transactionType: 'PURCHASE' },
    orderBy: { createdAt: 'desc' },
  });
  if (listing) {
    await prisma.housingApplication.upsert({
      where: { id: ids.housingApplication },
      update: {},
      create: {
        id: ids.housingApplication,
        code: 'HS-TRAM-TIM-HIEU-MUA',
        listingId: listing.id,
        applicantId: user.id,
        preferredStartDate: dateOnly(30),
        note: 'Đang thuê căn A-0301, muốn tìm hiểu thêm căn hộ để mua.',
        status: HousingApplicationStatus.PENDING,
      },
    });
  }

  const notifications = [
    {
      id: ids.notificationInvoice,
      title: 'Hóa đơn căn A-0301 cần thanh toán',
      message: 'Hóa đơn kỳ tới đã phát hành và đang chờ thanh toán.',
      type: NotificationType.INVOICE,
      referenceType: 'invoice',
      referenceId: invoice.id,
    },
    {
      id: ids.notificationMaintenance,
      title: 'Yêu cầu sửa chữa chờ bạn xác nhận',
      message:
        'Kỹ thuật viên đã xử lý ổ cắm phòng ngủ. Vui lòng kiểm tra kết quả.',
      type: NotificationType.MAINTENANCE,
      referenceType: 'maintenance_request',
      referenceId: ids.maintenanceWaiting,
    },
    {
      id: ids.notificationService,
      title: 'Dịch vụ giao nước chờ xác nhận',
      message: 'Hai bình nước đã được giao đến căn A-0301.',
      type: NotificationType.SERVICE,
      referenceType: 'service_request',
      referenceId: ids.serviceWaiting,
    },
    {
      id: ids.notificationAmenity,
      title: 'Lịch phòng gym đã được duyệt',
      message: 'Lịch đặt phòng gym của bạn đã được chấp thuận.',
      type: NotificationType.AMENITY,
      referenceType: 'amenity_booking',
      referenceId: ids.bookingApproved,
    },
    {
      id: ids.notificationStay,
      title: 'Khách lưu trú đã được duyệt',
      message: 'Đăng ký khách Nguyễn Minh Anh đã được lễ tân duyệt.',
      type: NotificationType.SYSTEM,
      referenceType: 'temporary_stay',
      referenceId: ids.stayApproved,
    },
    {
      id: ids.notificationSecurity,
      title: 'Bảo vệ đang xử lý sự cố',
      message: 'Bảo vệ đang kiểm tra báo cáo người lạ tại tầng 3.',
      type: NotificationType.SYSTEM,
      referenceType: 'security_incident',
      referenceId: ids.incidentReviewing,
    },
    ...(listing
      ? [
          {
            id: ids.notificationHousing,
            title: 'Đã tiếp nhận nhu cầu tìm mua căn hộ',
            message: 'Ban quản lý đã nhận yêu cầu tìm hiểu căn hộ của bạn.',
            type: NotificationType.HOUSING,
            referenceType: 'housing_application',
            referenceId: ids.housingApplication,
          },
        ]
      : []),
  ];
  for (const item of notifications) {
    await prisma.notification.upsert({
      where: { id: item.id },
      update: {
        title: item.title,
        message: item.message,
        referenceId: item.referenceId,
      },
      create: { ...item, userId: user.id, readAt: null },
    });
  }

  const counts = {
    verification: await prisma.residenceVerificationRequest.count({
      where: { userId: user.id, status: ResidenceVerificationStatus.APPROVED },
    }),
    household: await prisma.householdMember.count({
      where: { apartmentId: apartment.id, status: 'ACTIVE' },
    }),
    invoices: await prisma.invoice.groupBy({
      by: ['status'],
      where: { payerId: user.id },
      _count: true,
    }),
    maintenance: await prisma.maintenanceRequest.count({
      where: { requestedById: user.id },
    }),
    services: await prisma.serviceRequest.count({
      where: { requestedById: user.id },
    }),
    amenityBookings: await prisma.amenityBooking.count({
      where: { residentId: user.id },
    }),
    temporaryStays: await prisma.temporaryStay.count({
      where: { declaredById: user.id },
    }),
    securityIncidents: await prisma.securityIncident.count({
      where: { reportedById: user.id },
    }),
    housingApplications: await prisma.housingApplication.count({
      where: { applicantId: user.id },
    }),
    notifications: await prisma.notification.count({
      where: { userId: user.id },
    }),
    visibleAnnouncements: await prisma.announcement.count({
      where: {
        isPublished: true,
        audience: { in: ['ALL', 'RESIDENTS'] },
        OR: [{ buildingId: null }, { buildingId: apartment.buildingId }],
      },
    }),
  };
  if (
    counts.maintenance < 2 ||
    counts.services < 2 ||
    counts.amenityBookings < 2 ||
    counts.temporaryStays < 2 ||
    counts.securityIncidents < 1
  ) {
    throw new Error('Dữ liệu minh họa chưa đầy đủ.');
  }
  console.log(
    JSON.stringify(
      {
        email,
        apartment: apartment.code,
        membershipStartDate: membership.startDate,
        unpaidInvoice: invoice.code,
        counts,
      },
      null,
      2,
    ),
  );
}

main()
  .catch((error: unknown) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
